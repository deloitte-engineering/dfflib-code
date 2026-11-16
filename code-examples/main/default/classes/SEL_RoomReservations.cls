/**
 * Selector class for RoomReservation__c object
 *
 * Demonstrates D'fflib selector patterns including:
 * - newInstance with dfflib_Database.Context parameter
 * - executeQuery with bind variable maps
 * - Parent relationship queries (Room__c, Contact)
 * - Date range filtering
 * - Status-based queries
 */
public with sharing class SEL_RoomReservations extends dfflib_SObjectSelector{
    /**
     * Creates a new instance of the selector via the application class. This is here to allow unit tests to override
     * and inject a mock instead of this class or to switch out this class for a new version.
     */
    public static SEL_RoomReservations newInstance( dfflib_Database.Context ctx ){
        return ( SEL_RoomReservations ) dfflib.selector.newInstance( RoomReservation__c.SObjectType, ctx );
    }

    /**
     * Returns the SObject type for the selector. This is used to retrieve the sObject name when building the SOQL queries.
     */
    public override Schema.SObjectType getSObjectType(){
        return RoomReservation__c.SObjectType;
    }

    /**
     * Returns the sObject fields which should be selected within all queries (unless not required).
     * For selecting fields through relationships @see{Set<String> getRelatedFieldSet()}.
     */
    public override List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField>{
            RoomReservation__c.CheckInDate__c,
            RoomReservation__c.CheckOutDate__c,
            RoomReservation__c.Contact__c,
            RoomReservation__c.Id,
            RoomReservation__c.Name,
            RoomReservation__c.NumberOfGuests__c,
            RoomReservation__c.Room__c,
            RoomReservation__c.SpecialRequests__c,
            RoomReservation__c.Status__c,
            RoomReservation__c.TotalPrice__c
        };
    }

    public override Set<String> getRelatedFieldSet(){
        return new Set<String>{
            'Contact__r.Name',
            'Room__r.Capacity__c',
            'Room__r.Name', // room number
            'Room__r.RoomType__c'
        };
    }

    /**
     * Gather the number of open RoomReservations per Room Id
     *
     * @param roomIds   Set of Room Ids
     * @return List of AggregateResults with Room Id and number of open reservations
     */
    public List<dfflib_AggregateResult> selectOpenCountPerRoomId( Set<Id> roomIds ){
        dfflib_QueryFactory qf = newQueryFactory( false ); // Construct query without default SObject and relational fields
        qf.selectField( RoomReservation__c.Room__c );
        qf.selectField( 'COUNT( Id ) numOpenReservations' );
        List<String> conditions = new List<String>{
            'Room__c IN :roomIds',
            'Status__c IN :openStatuses'
        };
        qf.setCondition( String.join( conditions, ' AND ' ) );
        qf.setGroupByField( RoomReservation__c.Room__c );

        return this.executeAggregateQuery( qf, new Map<String, Object>{
            'roomIds'       => roomIds,
            'openStatuses'  => DOM_RoomReservations.STATUSES_OPEN
        } );
    }

    /**
     * Select reservations by Room Id
     *
     * @param roomIds   Set of Room Ids
     * @return List of RoomReservation__c
     */
    public List<RoomReservation__c> selectByRoomId( Set<Id> roomIds ){
        dfflib_QueryFactory qf = newQueryFactory( true, true ); // Construct query with default SObject fields and relational fields
        qf.setCondition( 'Room__c IN :roomIds' );

        return this.executeQuery( qf, new Map<String, Object>{
            'roomIds' => roomIds
        } );
    }

    /**
     * Select reservations by Contact Id
     *
     * @param contactIds    Set of Contact Ids
     * @return List of RoomReservation__c
     */
    public List<RoomReservation__c> selectByContactId( Set<Id> contactIds ){
        dfflib_QueryFactory qf = newQueryFactory( true );
        qf.setCondition( 'Contact__c IN :contactIds' );

        return this.executeQuery( qf, new Map<String, Object>{
            'contactIds' => contactIds
        } );
    }
}