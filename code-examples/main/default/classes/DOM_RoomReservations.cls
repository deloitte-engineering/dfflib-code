/**
 * Domain class for RoomReservation__c object demonstrating D'fflib domain patterns including:
 * - Statics to centralize object-related constants (avoiding scattered hardcoded strings)
 * - Object-specific methods like record-validation
 * - Trigger handlers:
 * -- CalculateTotalPrice before insert/update
 */
public with sharing class DOM_RoomReservations extends dfflib_SObjectDomain{

    // Statuses in sequence of RoomReservation lifecycle
    public static final String STATUS_SUBMITTED     = 'Submitted';
    public static final String STATUS_PAID          = 'Paid';
    public static final String STATUS_CHECKED_IN    = 'CheckedIn';
    public static final String STATUS_CHECKED_OUT   = 'CheckedOut';
    public static final String STATUS_CANCELLED     = 'Cancelled';

    public static final Set<String> STATUSES_OPEN = new Set<String>{ STATUS_SUBMITTED, STATUS_PAID, STATUS_CHECKED_IN };
    public static final Set<String> STATUSES_COMPLETED = new Set<String>{ STATUS_CHECKED_OUT, STATUS_CANCELLED };

    // User-facing validation messages (consider moving to Custom Labels for translation)
    public static final String MSG_INVALID_DATE_RANGE         = 'The check-out date must be after the check-in date.';
    public static final String MSG_INVALID_NUMBER_OF_GUESTS   = 'A reservation should have at least one guest.';

    // ============================================================================
    // CONSTRUCTOR
    // ============================================================================
    /**
     * Constructor accepting list of RoomReservation__c records, called by Trigger invocation
     * @param sObjectList List of RoomReservation__c records
     */
    public DOM_RoomReservations( List<RoomReservation__c> sObjectList ){
        super( sObjectList, dfflib.unitOfWork.newInstance( dfflib_Database.Context.FULL ) );
        registerHandler( TriggerEvent.BEFORE_INSERT, CalculateTotalPrice.class );
        registerHandler( TriggerEvent.BEFORE_UPDATE, CalculateTotalPrice.class );
    }

    // ============================================================================
    // VALIDATION
    // ============================================================================

    /**
     * Validates the in-memory records (e.g. input received from the front-end) before any DML is performed.
     * For sake of code-example throwing first failure found; normally more likely to collect all failures
     * and return e.g. a Map<Integer, String> of errors per record index.
     *
     * @throws  dfflib_Utils.InvalidInputValueException on the first invalid record
     */
    public void validateRecords(){
        List<RoomReservation__c> reservations = ( List<RoomReservation__c> ) getRecords();
        for( Integer i = 0, j = reservations.size(); i < j; i++ ){
            RoomReservation__c res = reservations[ i ];
            dfflib_Utils.verifyNotNull( res.Room__c, 'Room' );
            dfflib_Utils.verifyNotNull( res.Contact__c, 'Contact' );
            dfflib_Utils.verifyNotNull( res.CheckInDate__c, 'Check-in date' );
            dfflib_Utils.verifyNotNull( res.CheckOutDate__c, 'Check-out date' );
            if( res.CheckOutDate__c <= res.CheckInDate__c ){
                throw new dfflib_Utils.InvalidInputValueException( MSG_INVALID_DATE_RANGE );
            }
            if( res.NumberOfGuests__c == null || res.NumberOfGuests__c < 1 ){
                throw new dfflib_Utils.InvalidInputValueException( MSG_INVALID_NUMBER_OF_GUESTS );
            }
        }
    }

    // ============================================================================
    // TRIGGER HANDLERS
    // ============================================================================

    /**
     * Trigger handler that auto-calculates TotalPrice__c for each RoomReservation before insert/update.
     *
     * initialize: Pre-loads all referenced Room__c records in bulk (one query per trigger invocation)
     *             to avoid per-record SOQL queries inside process().
     *
     * process:    For each reservation, looks up the Room by Id and calculates TotalPrice__c as
     *             PricePerNight__c x nights (daysBetween CheckInDate__c and CheckOutDate__c).
     *             Fields are set directly on the record in-memory; no DML via UoW is required.
     *
     * finalize:   Not needed — this is a Before trigger, so field values are set directly on
     *             the in-memory SObject records before they are written to the database.
     */
    public class CalculateTotalPrice extends BaseHandler implements BeforeInsert, BeforeUpdate, FireOnce{
        private Map<Id, Room__c> roomsById;

        public override void initialize( TriggerState state, dfflib_ISObjectUnitOfWork uow ){
            Set<Id> roomIds = new Set<Id>();
            for( Integer i = 0, j = state.currentList.size(); i < j; i++ ){
                RoomReservation__c res = ( RoomReservation__c ) state.currentList[ i ];
                if( res.Room__c != null ){
                    roomIds.add( res.Room__c );
                }
            }
            roomsById = new Map<Id, Room__c>(
                ( List<Room__c> ) SEL_Rooms.newInstance( dfflib_Database.Context.NONE ).selectSObjectsById( roomIds )
            );
        }

        public override Boolean process( SObject current, SObject previous, dfflib_ISObjectUnitOfWork uow ){
            RoomReservation__c res = ( RoomReservation__c ) current;
            Room__c room = roomsById.get( res.Room__c );
            if( room != null && res.CheckInDate__c != null && res.CheckOutDate__c != null ){
                Integer nights = res.CheckInDate__c.daysBetween( res.CheckOutDate__c );
                if( nights > 0 ){
                    res.TotalPrice__c = room.PricePerNight__c * nights;
                }
            }
            return true;
        }
    }

    // ============================================================================
    // FACTORY METHODS
    // ============================================================================

    /**
     * Factory method to create domain instance from record Ids
     * @param recordIds Set of Reservation Ids
     * @return DOM_RoomReservations domain instance
     */
    public static DOM_RoomReservations newInstance( Set<Id> recordIds ){
        return ( DOM_RoomReservations ) dfflib.domain.newInstance( recordIds );
    }

    /**
     * Factory method to create domain instance from records
     * @param sObjectList List of RoomReservation__c records
     * @return DOM_RoomReservations domain instance
     */
    public static DOM_RoomReservations newInstance(){ return newInstance( new List<RoomReservation__c>() ); }
    public static DOM_RoomReservations newInstance( List<RoomReservation__c> sObjectList ){
        return ( DOM_RoomReservations ) dfflib.domain.newInstance( sObjectList );
    }

    // ============================================================================
    // DOMAIN FACTORY (inner class for trigger handler construction)
    // ============================================================================

    /**
     * Domain factory class for constructing DOM_RoomReservations domain instances
     */
    public class Constructor implements dfflib_SObjectDomain.IConstructable{
        public dfflib_SObjectDomain construct( List<SObject> sObjectList ){
            return new DOM_RoomReservations( ( List<RoomReservation__c> ) sObjectList );
        }
    }
}