/**
 * Domain class for Room__c object demonstrating D'fflib domain patterns including:
 * - Trigger Handler
 * -- ValidateDeactivation: Prevent Room deactivation when still reservations pending
 */
public with sharing class DOM_Rooms extends dfflib_SObjectDomain{
    // Domain constants
    public static final String TYPE_CONFERENCE  = 'Conference';
    public static final String TYPE_DOUBLE      = 'Double';
    public static final String TYPE_SINGLE      = 'Single';
    public static final String TYPE_SUITE       = 'Suite';

    /**
     * Trigger Handler construction, initiating the Trigger Context and Unit of Work.
     * In case deviating DatabaseContexts are desired for the Unit of Work,
     * one can initiate a separate Unit of Work within the Trigger Handler,
     * or provide a different DatabaseContext in the constructor, to apply to all Handlers.
     */
    public DOM_Rooms( List<Room__c> sObjectList ){
        // Initialize the domain
        super( sObjectList, dfflib.unitOfWork.newInstance( dfflib_Database.Context.FULL ) );

        // Register all of the trigger handlers for this domain
        registerHandler( TriggerEvent.BEFORE_UPDATE, ValidateDeactivation.class );
    }

    // ============================================================================
    // TRIGGER HANDLERS
    // ============================================================================
    public without sharing class ValidateDeactivation extends BaseHandler implements BeforeUpdate, FireOnce{
        Set<Id> deactivatedRoomIds = new Set<Id>();

        public override Boolean process( SObject current, SObject previous, dfflib_ISObjectUnitOfWork uow ){
            Room__c curr = ( Room__c ) current;
            Room__c prev = ( Room__c ) previous;

            if( curr.IsActive__c == false && prev.IsActive__c == true ){
                deactivatedRoomIds.add( curr.Id );
            }
            return true;
        }

        public override void finalize( TriggerState state, dfflib_ISObjectUnitOfWork uow ){
            if( deactivatedRoomIds.size() > 0 ){
                // Validate whether there are any remainingReservations left for the deactivated rooms (bypassing any sharing for data correctness)
                List<dfflib_AggregateResult> numOpenReservationsPerRoom = SEL_RoomReservations.newInstance( dfflib_Database.Context.NONE ).selectOpenCountPerRoomId( deactivatedRoomIds );

                // Convert Trigger Context Room records to be available per ID to set errors
                Map<Id, Room__c> roomsById = new Map<Id, Room__c>( ( List<Room__c> ) state.currentList );
                for( Integer i = 0, j = numOpenReservationsPerRoom.size(); i < j; i ++ ){
                    dfflib_AggregateResult result = numOpenReservationsPerRoom[ i ];
                    Id roomId = ( Id ) result.get( 'Room__c' );
                    if( Integer.valueOf( result.get( 'numOpenReservations' ) ) > 0 ){
                        Room__c roomToSetError = roomsById.get( roomId );
                        roomToSetError.addError( 'Cannot deactivate a room with open reservations.' );
                    }
                }
            }
        }
    }


    /**
     * Factory constructions to be referenced by calling classes,
     * populating the records-variable either by Set<Id>, List<SObject> or with none
     */
    /**
     * Factory method to create domain instance from record Ids
     * @param recordIds Set of Room Ids
     * @return DOM_Rooms domain instance
     */
    public static DOM_Rooms newInstance( Set<Id> recordIds ){
        return ( DOM_Rooms ) dfflib.domain.newInstance( recordIds );
    }

    /**
     * Factory method to create domain instance from records
     * @param sObjectList List of Room__c records
     * @return DOM_Rooms domain instance
     */
    public static DOM_Rooms newInstance(){ return newInstance( new List<Room__c>() ); }
    public static DOM_Rooms newInstance( List<Room__c> sObjectList ){
        return ( DOM_Rooms ) dfflib.domain.newInstance( sObjectList );
    }

    /**
     * Domain factory class for constructing DOM_Rooms domain instances
     */
    public class Constructor implements dfflib_SObjectDomain.IConstructable{
        public dfflib_SObjectDomain construct( List<SObject> sObjectList ){
            return new DOM_Rooms( sObjectList );
        }
    }
}