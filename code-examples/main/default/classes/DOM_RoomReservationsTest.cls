/**
 * Test class for DOM_RoomReservations
 *
 * Tests the domain class factory methods, constructor, and static constants
 * using fflib_ApexMocks and TestFactory patterns.
 */
@IsTest( isParallel = true )
public with sharing class DOM_RoomReservationsTest{

    // ============================================================================
    // BUILDER
    // ============================================================================
    public class Builder extends dfflib_UT_SObjectFactory.DomainObject{
        public Builder(){
            super( RoomReservation__c.SObjectType );
        }

        public Builder asDefault(){
            Date today = Date.today();
            withDates( today, today.addDays( 2 ) );
            withNumberOfGuests( 1 );
            withStatus( DOM_RoomReservations.STATUS_SUBMITTED );
            return this;
        }

        /**
         * Reservation that passes all DOM_RoomReservations.validateRecords() rules
         */
        public Builder asValid(){
            asDefault();
            forRoom( TestFactory.aRoom().asSingleRoom( 101 ) );
            forContact( TestFactory.aContact().asDefault() );
            return this;
        }

        public Builder forContact( DOM_ContactsTest.Builder builder ){
            setParent( RoomReservation__c.Contact__c, builder );
            return this;
        }

        public Builder forRoom( DOM_RoomsTest.Builder builder ){
            setParent( RoomReservation__c.Room__c, builder );
            return this;
        }

        public Builder withCheckInDate( Date checkInDate ){
            set( RoomReservation__c.CheckInDate__c, checkInDate );
            return this;
        }

        public Builder withCheckOutDate( Date checkOutDate ){
            set( RoomReservation__c.CheckOutDate__c, checkOutDate );
            return this;
        }

        public Builder withDates( Date checkInDate, Date checkOutDate ){
            set( RoomReservation__c.CheckInDate__c, checkInDate );
            set( RoomReservation__c.CheckOutDate__c, checkOutDate );
            return this;
        }

        public Builder withNumberOfGuests( Integer numberOfGuests ){
            set( RoomReservation__c.NumberOfGuests__c, numberOfGuests );
            return this;
        }

        public Builder withSpecialRequests( String specialRequests ){
            set( RoomReservation__c.SpecialRequests__c, specialRequests );
            return this;
        }

        public Builder withStatus( String status ){
            set( RoomReservation__c.Status__c, status );
            return this;
        }

        public Builder withTotalPrice( Decimal totalPrice ){
            set( RoomReservation__c.TotalPrice__c, totalPrice );
            return this;
        }
    }

    // ============================================================================
    // TESTS
    // ============================================================================

    @IsTest
    private static void newInstance_noRecords(){
        // When
        DOM_RoomReservations domainInstance = DOM_RoomReservations.newInstance();

        // Then - domain has no records
        List<RoomReservation__c> records = domainInstance.getRecords();
        System.Assert.areEqual( 0, records.size(), 'Expected empty records list' );
    }

    /**
     * Test newInstance(List<RoomReservation__c>) factory method
     * Verifies domain is created with provided records
     */
    @IsTest
    private static void newInstance_withRecords(){
        // Given - Create test reservation using TestFactory
        RoomReservation__c testReservation = ( RoomReservation__c ) TestFactory.aRoomReservation().mockWithIds();

        // When - Create domain instance with records
        DOM_RoomReservations domainInstance = DOM_RoomReservations.newInstance( new List<RoomReservation__c>{ testReservation } );

        // Then - Verify records are accessible
        List<RoomReservation__c> records = domainInstance.getRecords();
        System.Assert.areEqual( 1, records.size(), 'Expected 1 record in domain' );
        System.Assert.areEqual( testReservation.Id, records[0].Id, 'Record Id should match' );
    }

    @IsTest
    private static void newInstance_withIds(){
        // create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        SEL_RoomReservations mockSelector = ( SEL_RoomReservations ) dfflib.selector.defineMock(
            mocks, SEL_RoomReservations.class, RoomReservation__c.SObjectType
        );

        // Given - submitted reservation with mock Id via Builder
        RoomReservation__c testReservation = ( RoomReservation__c ) TestFactory.aRoomReservation()
            .withStatus( DOM_RoomReservations.STATUS_SUBMITTED )
            .mockWithIds();
        Set<Id> recordIds = new Set<Id>{ testReservation.Id };

        // set mocks
        mocks.startStubbing();
        mocks.when( mockSelector.selectSObjectsById( recordIds ) ).thenReturn( new List<RoomReservation__c>{ testReservation } );
        mocks.stopStubbing();

        // When - Create domain instance from IDs
        DOM_RoomReservations domainInstance = DOM_RoomReservations.newInstance( recordIds );

        // Then - Verify records retrieved via selector
        List<RoomReservation__c> records = domainInstance.getRecords();
        System.Assert.areEqual( 1, records.size(), 'Expected 1 record from selector' );
        System.Assert.areEqual( testReservation.Id, records[0].Id, 'Record Id should match' );
    }

    @IsTest
    private static void statusSets_openAndCompleted(){
        // When & Then - Verify STATUSES_OPEN contains expected statuses
        System.Assert.isTrue(
            DOM_RoomReservations.STATUSES_OPEN.contains( DOM_RoomReservations.STATUS_SUBMITTED ),
            'STATUSES_OPEN should contain STATUS_SUBMITTED'
        );
        System.Assert.isTrue(
            DOM_RoomReservations.STATUSES_OPEN.contains( DOM_RoomReservations.STATUS_PAID ),
            'STATUSES_OPEN should contain STATUS_PAID'
        );
        System.Assert.isTrue(
            DOM_RoomReservations.STATUSES_OPEN.contains( DOM_RoomReservations.STATUS_CHECKED_IN ),
            'STATUSES_OPEN should contain STATUS_CHECKED_IN'
        );

        // When & Then - Verify STATUSES_COMPLETED contains expected statuses
        System.Assert.isTrue(
            DOM_RoomReservations.STATUSES_COMPLETED.contains( DOM_RoomReservations.STATUS_CHECKED_OUT ),
            'STATUSES_COMPLETED should contain STATUS_CHECKED_OUT'
        );
        System.Assert.isTrue(
            DOM_RoomReservations.STATUSES_COMPLETED.contains( DOM_RoomReservations.STATUS_CANCELLED ),
            'STATUSES_COMPLETED should contain STATUS_CANCELLED'
        );

        // When & Then - Verify mutual exclusivity
        System.Assert.isFalse(
            DOM_RoomReservations.STATUSES_OPEN.contains( DOM_RoomReservations.STATUS_CANCELLED ),
            'STATUSES_OPEN should not contain STATUS_CANCELLED'
        );
        System.Assert.isFalse(
            DOM_RoomReservations.STATUSES_COMPLETED.contains( DOM_RoomReservations.STATUS_SUBMITTED ),
            'STATUSES_COMPLETED should not contain STATUS_SUBMITTED'
        );
    }

    /**
     * Test direct constructor instantiation
     * Verifies the main constructor works correctly
     */
    @IsTest
    private static void constructor_withRecords(){
        // Given - Create test reservations
        RoomReservation__c reservation1 = ( RoomReservation__c ) TestFactory.aRoomReservation()
            .asDefault()
            .withStatus( DOM_RoomReservations.STATUS_SUBMITTED )
            .mockWithIds();

        RoomReservation__c reservation2 = ( RoomReservation__c ) TestFactory.aRoomReservation()
            .asDefault()
            .withStatus( DOM_RoomReservations.STATUS_PAID )
            .mockWithIds();

        List<RoomReservation__c> testRecords = new List<RoomReservation__c>{ reservation1, reservation2 };

        // When - Instantiate domain directly
        DOM_RoomReservations domainInstance = new DOM_RoomReservations( testRecords );

        // Then - Verify records are accessible
        List<RoomReservation__c> records = domainInstance.getRecords();
        System.Assert.areEqual( 2, records.size(), 'Expected 2 records in domain' );
    }

    /**
     * Test CalculateTotalPrice handler sets TotalPrice__c correctly.
     * Verifies TotalPrice = PricePerNight x nights when a valid Room and date range are present.
     */
    @IsTest
    private static void calculateTotalPrice_validRoomAndDates(){
        // create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        dfflib_ISObjectUnitOfWork uowMock = dfflib.unitOfWork.defineMock( mocks );
        SEL_Rooms m_selRooms = ( SEL_Rooms ) dfflib.selector.defineMock(
            mocks, SEL_Rooms.class, Room__c.SObjectType
        );

        // Given - Room with PricePerNight = 42.0 and Reservation for 3 nights
        DOM_RoomsTest.Builder roomBuilder = TestFactory.aRoom().asSingleRoom( 101 );
        RoomReservation__c res = ( RoomReservation__c ) TestFactory.aRoomReservation()
            .asDefault()
            .forRoom( roomBuilder )
            .withDates( Date.today(), Date.today().addDays( 3 ) )
            .mockWithIds();
        Room__c room = ( Room__c ) roomBuilder.mockWithIds();

        // set mocks
        mocks.startStubbing();
        mocks.when( m_selRooms.selectSObjectsById( new Set<Id>{ res.Room__c } ) )
            .thenReturn( new List<Room__c>{ room } );
        mocks.stopStubbing();

        // When - Run the CalculateTotalPrice handler for BEFORE_INSERT
        new DOM_RoomReservations( new List<RoomReservation__c>{ res } ).runHandler(
            DOM_RoomReservations.CalculateTotalPrice.class,
            dfflib_SObjectDomain.TriggerEvent.BEFORE_INSERT,
            null,
            uowMock
        );

        // Then - TotalPrice should be PricePerNight (42.0) x 3 nights = 126.0
        System.Assert.areEqual( 126.0, res.TotalPrice__c, 'Expected TotalPrice = PricePerNight × nights' );
    }

    /**
     * Test CalculateTotalPrice handler leaves TotalPrice__c unchanged when Room is not found.
     * Verifies no calculation occurs when the selector returns an empty result.
     */
    @IsTest
    private static void calculateTotalPrice_roomNotFound(){
        // create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        dfflib_ISObjectUnitOfWork uowMock = dfflib.unitOfWork.defineMock( mocks );
        SEL_Rooms m_selRooms = ( SEL_Rooms ) dfflib.selector.defineMock( mocks, SEL_Rooms.class, Room__c.SObjectType );

        // Given - Reservation linked to a Room that the selector will not find
        RoomReservation__c res = ( RoomReservation__c ) TestFactory.aRoomReservation()
            .forRoom( TestFactory.aRoom().asSingleRoom( 101 ) )
            .withDates( Date.today(), Date.today().addDays( 3 ) )
            .mockWithIds();

        // set mocks
        mocks.startStubbing();
        mocks.when( m_selRooms.sObjectType() ).thenReturn( Room__c.SObjectType );
        mocks.when( m_selRooms.selectSObjectsById( new Set<Id>{ res.Room__c } ) ).thenReturn( new List<Room__c>() );
        mocks.stopStubbing();

        // When - Run the CalculateTotalPrice handler for BEFORE_INSERT
        new DOM_RoomReservations( new List<RoomReservation__c>{ res } ).runHandler(
            DOM_RoomReservations.CalculateTotalPrice.class,
            dfflib_SObjectDomain.TriggerEvent.BEFORE_INSERT,
            null,
            uowMock
        );

        // Then - TotalPrice should remain null since the Room was not found
        System.Assert.isNull( res.TotalPrice__c, 'Expected TotalPrice to remain null when Room not found' );
    }

    @IsTest
    private static void validateRecords_validRecords(){
        // Given - two fully valid reservations
        List<RoomReservation__c> records = new List<RoomReservation__c>{
            ( RoomReservation__c ) TestFactory.aRoomReservation().asValid().mockWithIds(),
            ( RoomReservation__c ) TestFactory.aRoomReservation().asValid().mockWithIds()
        };

        // When / Then - no exception expected
        try{
            DOM_RoomReservations.newInstance( records ).validateRecords();
        } catch( Exception ex ){
            System.Assert.fail( 'Expected no validation failure, got: ' + ex.getMessage() );
        }
    }

    @IsTest
    private static void validateRecords_missingRoom(){
        // Given - reservation without a Room
        RoomReservation__c res = ( RoomReservation__c ) TestFactory.aRoomReservation()
            .asDefault()
            .forContact( TestFactory.aContact().asDefault() )
            .mockWithIds();

        // When / Then - validation fails on the missing Room
        try{
            DOM_RoomReservations.newInstance( new List<RoomReservation__c>{ res } ).validateRecords();
            System.Assert.fail( 'Expected dfflib_Utils.InvalidInputValueException to be thrown' );
        } catch( Exception ex ){
            System.Assert.areEqual( 'dfflib_Utils.InvalidInputValueException', ex.getTypeName(), 'Unexpected exception type' );
            System.Assert.areEqual( 'Room cannot be null', ex.getMessage(), 'Unexpected validation message' );
        }
    }

    @IsTest
    private static void validateRecords_missingContact(){
        // Given - reservation without a Contact
        RoomReservation__c res = ( RoomReservation__c ) TestFactory.aRoomReservation()
            .asDefault()
            .forRoom( TestFactory.aRoom().asSingleRoom( 101 ) )
            .mockWithIds();

        // When / Then - validation fails on the missing Contact
        try{
            DOM_RoomReservations.newInstance( new List<RoomReservation__c>{ res } ).validateRecords();
            System.Assert.fail( 'Expected dfflib_Utils.InvalidInputValueException to be thrown' );
        } catch( Exception ex ){
            System.Assert.areEqual( 'dfflib_Utils.InvalidInputValueException', ex.getTypeName(), 'Unexpected exception type' );
            System.Assert.areEqual( 'Contact cannot be null', ex.getMessage(), 'Unexpected validation message' );
        }
    }

    @IsTest
    private static void validateRecords_missingCheckInDate(){
        // Given - reservation without a check-in date
        RoomReservation__c res = ( RoomReservation__c ) TestFactory.aRoomReservation().asValid()
            .withCheckInDate( null )
            .mockWithIds();

        // When / Then - validation fails on the missing check-in date
        try{
            DOM_RoomReservations.newInstance( new List<RoomReservation__c>{ res } ).validateRecords();
            System.Assert.fail( 'Expected dfflib_Utils.InvalidInputValueException to be thrown' );
        } catch( Exception ex ){
            System.Assert.areEqual( 'dfflib_Utils.InvalidInputValueException', ex.getTypeName(), 'Unexpected exception type' );
            System.Assert.areEqual( 'Check-in date cannot be null', ex.getMessage(), 'Unexpected validation message' );
        }
    }

    @IsTest
    private static void validateRecords_missingCheckOutDate(){
        // Given - reservation without a check-out date
        RoomReservation__c res = ( RoomReservation__c ) TestFactory.aRoomReservation().asValid()
            .withCheckOutDate( null )
            .mockWithIds();

        // When / Then - validation fails on the missing check-out date
        try{
            DOM_RoomReservations.newInstance( new List<RoomReservation__c>{ res } ).validateRecords();
            System.Assert.fail( 'Expected dfflib_Utils.InvalidInputValueException to be thrown' );
        } catch( Exception ex ){
            System.Assert.areEqual( 'dfflib_Utils.InvalidInputValueException', ex.getTypeName(), 'Unexpected exception type' );
            System.Assert.areEqual( 'Check-out date cannot be null', ex.getMessage(), 'Unexpected validation message' );
        }
    }

    @IsTest
    private static void validateRecords_checkOutNotAfterCheckIn(){
        // Given - check-out equal to check-in (zero nights)
        RoomReservation__c res = ( RoomReservation__c ) TestFactory.aRoomReservation().asValid()
            .withDates( Date.today(), Date.today() )
            .mockWithIds();

        // When / Then - validation fails on the invalid date range
        try{
            DOM_RoomReservations.newInstance( new List<RoomReservation__c>{ res } ).validateRecords();
            System.Assert.fail( 'Expected dfflib_Utils.InvalidInputValueException to be thrown' );
        } catch( Exception ex ){
            System.Assert.areEqual( 'dfflib_Utils.InvalidInputValueException', ex.getTypeName(), 'Unexpected exception type' );
            System.Assert.areEqual( DOM_RoomReservations.MSG_INVALID_DATE_RANGE, ex.getMessage(), 'Unexpected validation message' );
        }
    }

    @IsTest
    private static void validateRecords_zeroGuests(){
        // Given - reservation without guests
        RoomReservation__c res = ( RoomReservation__c ) TestFactory.aRoomReservation().asValid()
            .withNumberOfGuests( 0 )
            .mockWithIds();

        // When / Then - validation fails on the number of guests
        try{
            DOM_RoomReservations.newInstance( new List<RoomReservation__c>{ res } ).validateRecords();
            System.Assert.fail( 'Expected dfflib_Utils.InvalidInputValueException to be thrown' );
        } catch( Exception ex ){
            System.Assert.areEqual( 'dfflib_Utils.InvalidInputValueException', ex.getTypeName(), 'Unexpected exception type' );
            System.Assert.areEqual( DOM_RoomReservations.MSG_INVALID_NUMBER_OF_GUESTS, ex.getMessage(), 'Unexpected validation message' );
        }
    }
}