/**
 * Selector class for Room__c object
 *
 * Demonstrates D'fflib selector patterns including:
 * - newInstance with dfflib_Database.Context parameter
 * - executeQuery with bind variable maps
 * - Database Context switching (e.g. NONE for bypassing sharing)
 * - DISTANCE ordering for geolocation-based nearest-room queries
 * - Availability subselect filtering out rooms with overlapping open reservations
 */
public with sharing class SEL_Rooms extends dfflib_SObjectSelector{

    /**
     * Creates a new instance of the selector via the application class. This is here to allow unit tests to override
     * and inject a mock instead of this class or to switch out this class for a new version.
     *
     * @param ctx   The database context to use for this selector instance (e.g. FULL, WITH_SHARING, NONE)
     * @return      A new SEL_Rooms instance (or test mock) bound to the given context
     */
    public static SEL_Rooms newInstance( dfflib_Database.Context ctx ){
        return ( SEL_Rooms ) dfflib.selector.newInstance( Room__c.SObjectType, ctx );
    }

    /**
     * Returns the SObject type for the selector. This is used to retrieve the sObject name when building the SOQL queries.
     *
     * @return  Room__c SObjectType token
     */
    public override Schema.SObjectType getSObjectType(){
        return Room__c.SObjectType;
    }

    /**
     * Returns the sObject fields which should be selected within all queries (unless not required).
     * For selecting fields through relationships @see{Set<String> getRelatedFieldSet()}.
     *
     * @return  List of Room__c SObjectField tokens included in every standard query
     */
    public override List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField>{
            Room__c.Capacity__c,
            Room__c.Id,
            Room__c.IsActive__c,
            Room__c.Location__c,
            Room__c.Name,
            Room__c.PricePerNight__c,
            Room__c.RoomType__c
        };
    }

    // ============================================================================
    // QUERY METHODS
    // ============================================================================

    /**
     * Select all active rooms of a given room type.
     *
     * @param roomType  The picklist value of the room type to filter on (e.g. 'Single', 'Double', 'Suite')
     * @return          List of Room__c records matching the active + type filter
     */
    public List<Room__c> selectActiveByRoomType( String roomType ){
        dfflib_QueryFactory qf = newQueryFactory( true );
        List<String> conditions = new List<String>{
            'IsActive__c = true',
            'RoomType__c = :roomType'
        };
        qf.setCondition( String.join( conditions, ' AND ' ) );

        return this.executeQuery( qf, new Map<String, Object>{
            'roomType' => roomType
        } );
    }

    /**
     * Select all rooms that are available (not already booked with an open reservation) for the given date range.
     *
     * This single rule covers every overlap case (starts within, ends within, spans, or is contained within
     * the requested range) while allowing back-to-back bookings on the same turnover day.
     * Thus date ranges are half-open [checkIn, checkOut): the check-out day is free for the next guest.
     *
     * @param checkIn   The requested check-in date (inclusive)
     * @param checkOut  The requested check-out date (exclusive)
     * @return          List of active Room__c records with no overlapping open reservations
     */
    public List<Room__c> selectAvailableByDateRange( Date checkIn, Date checkOut ){
        dfflib_QueryFactory qf = newQueryFactory( true );
        qf.setCondition(
            'IsActive__c = true' +
            ' AND Id NOT IN (' +
                'SELECT Room__c ' +
                'FROM RoomReservation__c ' +
                'WHERE Status__c IN :openStatuses ' +
                'AND CheckInDate__c < :checkOut ' +
                'AND CheckOutDate__c > :checkIn' +
            ')'
        );

        return this.executeQuery( qf, new Map<String, Object>{
            'checkIn'       => checkIn,
            'checkOut'      => checkOut,
            'openStatuses'  => DOM_RoomReservations.STATUSES_OPEN
        } );
    }

    /**
     * Select rooms ordered by proximity to the given geolocation, filtered to those within a maximum radius.
     *
     * Uses the SOQL DISTANCE / GEOLOCATION functions to sort results by ascending distance
     * from the supplied coordinates. Only rooms within radiusKm kilometres are returned.
     *
     * @param latitude  Latitude of the reference point (decimal degrees)
     * @param longitude Longitude of the reference point (decimal degrees)
     * @param radiusKm  Maximum search radius in kilometres
     * @return          List of Room__c records within the radius, sorted nearest-first
     */
    public List<Room__c> selectNearestRooms( Decimal latitude, Decimal longitude, Decimal radiusKm ){
        dfflib_QueryFactory qf = newQueryFactory( true );
        String distanceString = qf.getDistanceString( Room__c.Location__c, dfflib_QueryFactory.DistanceUnit.KILOMETERS );

        qf.selectField( distanceString );
        qf.setCondition( distanceString + '< :radiusKm' );
        qf.setOrdering( distanceString, dfflib_QueryFactory.SortOrder.ASCENDING, true );

        return this.executeQuery( qf, new Map<String, Object>{
            'latitude'  => latitude,
            'longitude' => longitude,
            'radiusKm'  => radiusKm
        } );
    }
}