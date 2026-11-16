/**
 * Test class for DOM_Rooms
 *
 * Tests the ValidateDeactivation trigger handler using fflib_ApexMocks
 * to mock the SEL_RoomReservations selector and verify behavior.
 * Uses the standard SObject.hasErrors() / SObject.getErrors() for error validation.
 */
@IsTest( isParallel = true )
public with sharing class DOM_RoomsTest{

    // ============================================================================
    // BUILDER
    // ============================================================================
    public class Builder extends dfflib_UT_SObjectFactory.DomainObject{
        public Builder(){
            super( Room__c.SObjectType );
        }

        public Builder asSingleRoom( Integer roomNumber ){
            withRoomNumber( 'ROOM-' + String.valueOf( roomNumber ).leftPad( 5, '0' ) );
            withRoomType( DOM_Rooms.TYPE_SINGLE );
            withPricePerNight( 42.0 );
            withCapacity( 1 );
            isActive( true );
            return this;
        }

        public Builder isActive( Boolean isActive ){
            set( Room__c.IsActive__c, isActive );
            return this;
        }

        public Builder withCapacity( Integer capacity ){
            set( Room__c.Capacity__c, capacity );
            return this;
        }

        public Builder withLocation( Decimal latitude, Decimal longitude ){
            set( Room__c.Location__Latitude__s, latitude );
            set( Room__c.Location__Longitude__s, longitude );
            return this;
        }

        public Builder withPricePerNight( Decimal pricePerNight ){
            set( Room__c.PricePerNight__c, pricePerNight );
            return this;
        }

        public Builder withRoomNumber( String roomNumber ){
            set( Room__c.Name, roomNumber );
            return this;
        }

        public Builder withRoomType( String roomType ){
            set( Room__c.RoomType__c, roomType );
            return this;
        }
    }

    // ============================================================================
    // TESTS
    // ============================================================================

    @IsTest
    private static void newInstance_noRecords(){
        // When
        DOM_Rooms domainTest = DOM_Rooms.newInstance();

        // Then - empty domain
        List<Room__c> recordList = domainTest.getRecords();
        System.assert( recordList.isEmpty(), 'Expected empty list' );
    }

    @IsTest
    private static void validateDeactivation_noDeactivations(){
        // create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        dfflib_ISObjectUnitOfWork uowMock = dfflib.unitOfWork.defineMock( mocks );
        SEL_RoomReservations m_selReservations = ( SEL_RoomReservations ) dfflib.selector.defineMock(
            mocks, SEL_RoomReservations.class, RoomReservation__c.SObjectType
        );

        // Given - Room stays active (no deactivation)
        Room__c currentRoom = ( Room__c ) TestFactory.aRoom()
            .isActive( true )
            .mockWithIds();
        Room__c previousRoom = currentRoom.clone( true, true );
        // previousRoom.IsActive__c already true -- no state change

        List<Room__c> triggeredRecords = new List<Room__c>{ currentRoom };
        Map<Id, Room__c> oldMap = new Map<Id, Room__c>{ currentRoom.Id => previousRoom };

        // When - Run the handler
        new DOM_Rooms( triggeredRecords ).runHandler(
            DOM_Rooms.ValidateDeactivation.class,
            dfflib_SObjectDomain.TriggerEvent.BEFORE_UPDATE,
            oldMap,
            uowMock
        );

        // Then - Selector should NOT be called since no rooms were deactivated
        ( ( SEL_RoomReservations ) mocks.verify( m_selReservations, 0 ) ).selectOpenCountPerRoomId( ( Set<Id> ) fflib_Match.anyObject() );

        // Verify no errors were raised
        System.Assert.isFalse( currentRoom.hasErrors(), 'Expected no errors when room is not deactivated' );
    }

    @IsTest
    private static void validateDeactivation_noOpenReservations(){
        // create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        dfflib_ISObjectUnitOfWork uowMock = dfflib.unitOfWork.defineMock( mocks );
        SEL_RoomReservations m_selReservations = ( SEL_RoomReservations ) dfflib.selector.defineMock(
            mocks, SEL_RoomReservations.class, RoomReservation__c.SObjectType
        );

        // Given - Room is deactivated; previous state was active; no open reservations
        Room__c currentRoom = ( Room__c ) TestFactory.aRoom()
            .isActive( false )
            .mockWithIds();
        Room__c previousRoom = currentRoom.clone( true, true );
        previousRoom.IsActive__c = true;

        List<Room__c> triggeredRecords = new List<Room__c>{ currentRoom };
        Map<Id, Room__c> oldMap = new Map<Id, Room__c>{ currentRoom.Id => previousRoom };

        Set<Id> expectedRoomIds = new Set<Id>{ currentRoom.Id };

        // set mocks
        mocks.startStubbing();
        mocks.when( m_selReservations.selectOpenCountPerRoomId( expectedRoomIds ) )
            .thenReturn( new List<dfflib_AggregateResult>() );
        mocks.stopStubbing();

        // When - Run the handler
        new DOM_Rooms( triggeredRecords ).runHandler(
            DOM_Rooms.ValidateDeactivation.class,
            dfflib_SObjectDomain.TriggerEvent.BEFORE_UPDATE,
            oldMap,
            uowMock
        );

        // Then - Selector should be called with the deactivated room Id
        ( ( SEL_RoomReservations ) mocks.verify( m_selReservations, 1 ) ).selectOpenCountPerRoomId( expectedRoomIds );

        // Verify no errors were raised (no open reservations)
        System.Assert.isFalse( currentRoom.hasErrors(), 'Expected no errors when room has no open reservations' );
    }

    @IsTest
    private static void validateDeactivation_withOpenReservations(){
        // create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        dfflib_ISObjectUnitOfWork uowMock = dfflib.unitOfWork.defineMock( mocks );
        SEL_RoomReservations m_selReservations = ( SEL_RoomReservations ) dfflib.selector.defineMock(
            mocks, SEL_RoomReservations.class, RoomReservation__c.SObjectType
        );
        dfflib_AggregateResult aggResult = ( dfflib_AggregateResult ) mocks.mock( dfflib_AggregateResult.class );

        // Given - Room is deactivated and has open reservations
        Room__c currentRoom = ( Room__c ) TestFactory.aRoom()
            .isActive( false )
            .mockWithIds();
        Room__c previousRoom = currentRoom.clone( true, true );
        previousRoom.IsActive__c = true;

        List<Room__c> triggeredRecords = new List<Room__c>{ currentRoom };
        Map<Id, Room__c> oldMap = new Map<Id, Room__c>{ currentRoom.Id => previousRoom };

        Set<Id> expectedRoomIds = new Set<Id>{ currentRoom.Id };
        Integer numOpenReservations = 3;

        // set mocks
        mocks.startStubbing();
        mocks.when( m_selReservations.selectOpenCountPerRoomId( expectedRoomIds ) )
            .thenReturn( new List<dfflib_AggregateResult>{ aggResult } );
        mocks.when( aggResult.get( 'Room__c' ) ).thenReturn( currentRoom.Id );
        mocks.when( aggResult.get( 'numOpenReservations' ) ).thenReturn( numOpenReservations );
        mocks.stopStubbing();

        // When - Run the handler
        new DOM_Rooms( triggeredRecords ).runHandler(
            DOM_Rooms.ValidateDeactivation.class,
            dfflib_SObjectDomain.TriggerEvent.BEFORE_UPDATE,
            oldMap,
            uowMock
        );

        // Then - Selector should be called
        ( ( SEL_RoomReservations ) mocks.verify( m_selReservations, 1 ) ).selectOpenCountPerRoomId( expectedRoomIds );

        // Verify error was raised for the room with open reservations
        List<Database.Error> errors = currentRoom.getErrors();
        System.Assert.areEqual( 1, errors.size(), 'Expected 1 error for room with open reservations' );
        System.Assert.areEqual(
            'Cannot deactivate a room with open reservations.',
            errors[ 0 ].getMessage(),
            'Expected different error message'
        );
    }

    @IsTest
    private static void validateDeactivation_mixedScenario(){
        // create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        dfflib_ISObjectUnitOfWork uowMock = dfflib.unitOfWork.defineMock( mocks );
        SEL_RoomReservations m_selReservations = ( SEL_RoomReservations ) dfflib.selector.defineMock(
            mocks, SEL_RoomReservations.class, RoomReservation__c.SObjectType
        );
        dfflib_AggregateResult aggResultA = ( dfflib_AggregateResult ) mocks.mock( dfflib_AggregateResult.class );

        // Given - Mixed scenario:
        // Room A: Deactivated, has 2 open reservations -> expects error (only aggregate result returned)
        // Room B: Deactivated, has 0 open reservations -> no error
        // Room C: Not deactivated (stays active) -> not included in selector call
        Room__c currentRoomA = ( Room__c ) TestFactory.aRoom().isActive( false ).mockWithIds();
        Room__c previousRoomA = currentRoomA.clone( true, true );
        previousRoomA.IsActive__c = true;

        Room__c currentRoomB = ( Room__c ) TestFactory.aRoom().isActive( false ).mockWithIds();
        Room__c previousRoomB = currentRoomB.clone( true, true );
        previousRoomB.IsActive__c = true;

        Room__c currentRoomC = ( Room__c ) TestFactory.aRoom().isActive( true ).mockWithIds();
        Room__c previousRoomC = currentRoomC.clone( true, true );
        // previousRoomC.IsActive__c already true -- no state change

        List<Room__c> triggeredRecords = new List<Room__c>{ currentRoomA, currentRoomB, currentRoomC };
        Map<Id, Room__c> oldMap = new Map<Id, Room__c>{
            currentRoomA.Id => previousRoomA,
            currentRoomB.Id => previousRoomB,
            currentRoomC.Id => previousRoomC
        };

        // Only deactivated rooms should be queried
        Set<Id> expectedRoomIds = new Set<Id>{ currentRoomA.Id, currentRoomB.Id };
        Integer numOpenReservationsA = 2;

        // set mocks
        mocks.startStubbing();
        mocks.when( m_selReservations.selectOpenCountPerRoomId( expectedRoomIds ) )
            .thenReturn( new List<dfflib_AggregateResult>{ aggResultA } );
        mocks.when( aggResultA.get( 'Room__c' ) ).thenReturn( currentRoomA.Id );
        mocks.when( aggResultA.get( 'numOpenReservations' ) ).thenReturn( numOpenReservationsA );
        mocks.stopStubbing();

        // When - Run the handler
        new DOM_Rooms( triggeredRecords ).runHandler(
            DOM_Rooms.ValidateDeactivation.class,
            dfflib_SObjectDomain.TriggerEvent.BEFORE_UPDATE,
            oldMap,
            uowMock
        );

        // Then - Selector should be called with only the deactivated room Ids (A and B, not C)
        ( ( SEL_RoomReservations ) mocks.verify( m_selReservations, 1 ) ).selectOpenCountPerRoomId( expectedRoomIds );

        // Verify only Room A has an error (Room B has no reservations, Room C was not deactivated)
        List<Database.Error> errorsA = currentRoomA.getErrors();
        System.Assert.areEqual( 1, errorsA.size(), 'Expected 1 error for Room A with open reservations' );
        System.Assert.areEqual(
            'Cannot deactivate a room with open reservations.',
            errorsA[ 0 ].getMessage(),
            'Expected different error message'
        );
        System.Assert.isFalse( currentRoomB.hasErrors(), 'Expected no errors for Room B without open reservations' );
        System.Assert.isFalse( currentRoomC.hasErrors(), 'Expected no errors for Room C which was not deactivated' );
    }
}