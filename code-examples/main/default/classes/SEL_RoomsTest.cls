/**
 * Test class for SEL_Rooms
 *
 * Demonstrates D'fflib selector test patterns including:
 * - mockExecuteQuery() for preventing database calls
 * - verifyQueryAndBindVariableKeys() fluent validation chain
 * - validateCondition() for WHERE clause assertions
 * - validateBindVariableValue() for bind variable verification
 * - validateFields() for SELECT field verification
 */
@IsTest( isParallel = true )
private with sharing class SEL_RoomsTest{

    @IsTest
    private static void selectActiveByRoomType_singleRoomType(){
        // create mocks - prevent database calls
        SEL_Rooms selector = SEL_Rooms.newInstance( dfflib_Database.Context.FULL );
        fflib_ApexMocks mocks = selector.mockExecuteQuery();

        // Given - set input
        String roomType = DOM_Rooms.TYPE_SINGLE;

        // When - perform test
        selector.selectActiveByRoomType( roomType );

        // Then - validate query, condition and bind variables
        selector.verifyQueryAndBindVariableKeys( mocks )
            .validateCondition( 'IsActive__c = true AND RoomType__c = :roomType' )
            .validateBindVariableValue( 'roomType', roomType )
            .validateFields( new Set<SObjectField>{
                Room__c.IsActive__c,
                Room__c.RoomType__c,
                Room__c.PricePerNight__c,
                Room__c.Capacity__c
            } );
    }

    @IsTest
    private static void selectAvailableByDateRange_twoNights(){
        // create mocks - prevent database calls
        SEL_Rooms selector = SEL_Rooms.newInstance( dfflib_Database.Context.FULL );
        fflib_ApexMocks mocks = selector.mockExecuteQuery();

        // Given - set input
        Date checkIn  = Date.today();
        Date checkOut = Date.today().addDays( 2 );

        // When - perform test
        selector.selectAvailableByDateRange( checkIn, checkOut );

        // Then - validate query, condition and bind variables
        // Partial match used because the subselect makes the full condition string long
        selector.verifyQueryAndBindVariableKeys( mocks )
            .validateCondition( 'IsActive__c = true', true )
            .validateCondition( 'CheckInDate__c < :checkOut AND CheckOutDate__c > :checkIn', true )
            .validateBindVariableValue( 'checkIn', checkIn )
            .validateBindVariableValue( 'checkOut', checkOut )
            .validateBindVariableValue( 'openStatuses', DOM_RoomReservations.STATUSES_OPEN )
            .validateFields( new Set<SObjectField>{
                Room__c.IsActive__c,
                Room__c.PricePerNight__c
            } );
    }

    @IsTest
    private static void selectNearestRooms_withinRadius(){
        // create mocks - prevent database calls
        SEL_Rooms selector = SEL_Rooms.newInstance( dfflib_Database.Context.FULL );
        fflib_ApexMocks mocks = selector.mockExecuteQuery();

        // Given - set input (Amsterdam coordinates)
        Decimal latitude  = 52.3676;
        Decimal longitude = 4.9041;
        Decimal radiusKm  = 5.0;

        // When - perform test
        selector.selectNearestRooms( latitude, longitude, radiusKm );

        // Then - validate query, condition and bind variables
        dfflib_QueryFactory qf = selector.verifyQueryAndBindVariableKeys( mocks )
            .validateCondition( 'DISTANCE( Location__c, GEOLOCATION(:latitude, :longitude), \'km\' )< :radiusKm' )
            .validateBindVariableValue( 'latitude', latitude )
            .validateBindVariableValue( 'longitude', longitude )
            .validateBindVariableValue( 'radiusKm', radiusKm )
            .qf;

        // Then - validate ordering is replaced by a single ascending DISTANCE ordering with nulls last
        System.Assert.isNotNull( qf, 'Expected QueryFactory to be captured' );
        List<dfflib_QueryFactory.Ordering> orderings = qf.getOrderings();
        System.Assert.areEqual( 1, orderings.size(), 'Expected default ordering to be replaced by exactly 1 DISTANCE ordering' );

        String expectedDistance = qf.getDistanceString( Room__c.Location__c, dfflib_QueryFactory.DistanceUnit.KILOMETERS );
        dfflib_QueryFactory.Ordering ordering = orderings[ 0 ];
        System.Assert.areEqual( expectedDistance, ordering.getField(), 'Expected ordering on the DISTANCE expression' );
        System.Assert.areEqual( dfflib_QueryFactory.SortOrder.ASCENDING, ordering.getDirection(), 'Expected ascending (nearest-first) ordering' );
        System.Assert.areEqual( expectedDistance + ' ASC NULLS LAST ', ordering.toSOQL(), 'Expected ORDER BY clause with NULLS LAST' );
    }
}