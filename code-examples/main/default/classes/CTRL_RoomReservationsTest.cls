/**
 * Test class for CTRL_RoomReservations
 *
 * Pattern summary:
 * - All dependencies (UoW, Selectors, SRV_Response) are mocked via defineMock()
 * - Leverage of Unit Test Builder Framework via TestFactory to easily construct test data consistently
 * - Throwing a faked DMLException upon commitWork() to cover and validate error handling
 * - Tests verify that other layers are invoked as intended (e.g. allOrNone configuration), not the behaviour of those layers
 * - Consistent Given/When/Then structure and clear method names
 */
@IsTest( isParallel = true )
private with sharing class CTRL_RoomReservationsTest{

    /**
     * Stubs the SRV_Response mock to avoid null-pointers in the fluent chain. Must be called between startStubbing() and stopStubbing().
     */
    private static void stubResponseService( fflib_ApexMocks mocks, SRV_Response m_srvResponse ){
        mocks.when( m_srvResponse.setResponse( ( SRV_Response.TYPES ) fflib_Match.anyObject(), ( String ) fflib_Match.anyObject() ) ).thenReturn( m_srvResponse );
        // fflib_Match.anyObject() does not match null, so stub null messages separately
        mocks.when( m_srvResponse.setResponse( ( SRV_Response.TYPES ) fflib_Match.anyObject(), ( String ) fflib_Match.isNull() ) ).thenReturn( m_srvResponse );
        mocks.when( m_srvResponse.setPayload( fflib_Match.anyObject() ) ).thenReturn( m_srvResponse );
        mocks.when( m_srvResponse.getResponse() ).thenReturn( null );
    }

    // ============================================================================
    // getAvailableRooms
    // ============================================================================

    @IsTest
    private static void getAvailableRooms_validDateRange(){
        // create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        SEL_Rooms m_selRooms = ( SEL_Rooms ) dfflib.selector.defineMock( mocks, SEL_Rooms.class, Room__c.SObjectType );
        SRV_Response m_srvResponse = ( SRV_Response ) dfflib.service.defineMock( mocks, SRV_Response.class );

        // Given - single room
        Date checkIn  = Date.today();
        Date checkOut = Date.today().addDays( 2 );
        Room__c room = ( Room__c ) TestFactory.aRoom().asSingleRoom( 101 ).mockWithIds();
        List<Room__c> expectedRooms = new List<Room__c>{ room };

        // set mocks
        mocks.startStubbing();
        mocks.when( m_selRooms.selectAvailableByDateRange( checkIn, checkOut ) ).thenReturn( expectedRooms );
        stubResponseService( mocks, m_srvResponse );
        mocks.stopStubbing();

        // When
        CTRL_RoomReservations.getAvailableRooms( checkIn, checkOut );

        // Then - selector called once, OK response with the rooms as payload
        ( ( SEL_Rooms ) mocks.verify( m_selRooms, 1 ) ).selectAvailableByDateRange( checkIn, checkOut );
        ( ( SRV_Response ) mocks.verify( m_srvResponse, 1 ) ).setResponse( SRV_Response.TYPES.OK, null );
        ( ( SRV_Response ) mocks.verify( m_srvResponse, 1 ) ).setPayload( expectedRooms );
    }

    @IsTest
    private static void getAvailableRooms_nullInput(){
        // create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        SRV_Response m_srvResponse = ( SRV_Response ) dfflib.service.defineMock( mocks, SRV_Response.class );

        // set mocks
        mocks.startStubbing();
        stubResponseService( mocks, m_srvResponse );
        mocks.stopStubbing();

        // When - null inputs
        CTRL_RoomReservations.getAvailableRooms( null, null );

        // Then - dfflib_Utils.verifyNotNull message for the first invalid parameter
        ( ( SRV_Response ) mocks.verify( m_srvResponse, 1 ) ).setResponse(
            SRV_Response.TYPES.INVALID_REQUEST,
            dfflib_Utils.message( '{0} cannot be null', 'checkIn date' )
        );
    }

    @IsTest
    private static void getAvailableRooms_checkOutBeforeCheckIn(){
        // create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        SRV_Response m_srvResponse = ( SRV_Response ) dfflib.service.defineMock( mocks, SRV_Response.class );

        // Given - check-out before check-in
        Date checkIn = Date.today();

        // set mocks
        mocks.startStubbing();
        stubResponseService( mocks, m_srvResponse );
        mocks.stopStubbing();

        // When
        CTRL_RoomReservations.getAvailableRooms( checkIn, checkIn.addDays( -1 ) );

        // Then
        ( ( SRV_Response ) mocks.verify( m_srvResponse, 1 ) ).setResponse(
            SRV_Response.TYPES.INVALID_REQUEST,
            DOM_RoomReservations.MSG_INVALID_DATE_RANGE
        );
    }

    @IsTest
    private static void getAvailableRooms_unexpectedException(){
        // create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        SEL_Rooms m_selRooms = ( SEL_Rooms ) dfflib.selector.defineMock( mocks, SEL_Rooms.class, Room__c.SObjectType );
        SRV_Response m_srvResponse = ( SRV_Response ) dfflib.service.defineMock( mocks, SRV_Response.class );

        // Given - selector throws a technical exception
        String exceptionMessage = 'Technical failure';
        Date checkIn  = Date.today();
        Date checkOut = Date.today().addDays( 2 );

        // set mocks
        mocks.startStubbing();
        mocks.when( m_selRooms.selectAvailableByDateRange( checkIn, checkOut ) )
            .thenThrow( new dfflib_Utils.MissingDataException( exceptionMessage ) );
        stubResponseService( mocks, m_srvResponse );
        mocks.stopStubbing();

        // When
        CTRL_RoomReservations.getAvailableRooms( checkIn, checkOut );

        // Then - technical message is not exposed; generic user-friendly message is returned
        ( ( SRV_Response ) mocks.verify( m_srvResponse, 1 ) ).setResponse(
            SRV_Response.TYPES.PROCESSING_ERROR,
            CTRL_RoomReservations.MSG_PROCESSING_ERROR
        );
    }

    // ============================================================================
    // createReservations
    // ============================================================================

    @IsTest
    private static void createReservations_validRecords(){
        // create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        dfflib_ISObjectUnitOfWork uowMock = dfflib.unitOfWork.defineMock( mocks );
        DOM_RoomReservations m_domReservations = ( DOM_RoomReservations ) dfflib.domain.defineMock( mocks, DOM_RoomReservations.class, RoomReservation__c.SObjectType );
        SRV_Response m_srvResponse = ( SRV_Response ) dfflib.service.defineMock( mocks, SRV_Response.class );

        // Given
        RoomReservation__c reservation = ( RoomReservation__c ) TestFactory.aRoomReservation()
            .asDefault()
            .mock();

        List<RoomReservation__c> reservations = new List<RoomReservation__c>{ reservation };

        // set mocks
        mocks.startStubbing();
        stubResponseService( mocks, m_srvResponse );
        mocks.stopStubbing();

        // When - mocked domain passes validation; mocked UoW returns null for getNewResults; loop skips -> success path
        CTRL_RoomReservations.createReservations( reservations );

        // Then - verify records validated, UoW configured with allOrNone = false, registered and committed, and SRV_Response received CREATED
        ( ( DOM_RoomReservations ) mocks.verify( m_domReservations, 1 ) ).validateRecords();
        ( ( dfflib_ISObjectUnitOfWork ) mocks.verify( uowMock, 1 ) ).registerNewAllOrNone( RoomReservation__c.SObjectType, false );
        ( ( dfflib_ISObjectUnitOfWork ) mocks.verify( uowMock, 1 ) ).registerNew( reservations );
        ( ( dfflib_ISObjectUnitOfWork ) mocks.verify( uowMock, 1 ) ).commitWork();
        ( ( SRV_Response ) mocks.verify( m_srvResponse, 1 ) ).setResponse( SRV_Response.TYPES.CREATED, null );
    }

    @IsTest
    private static void createReservations_emptyInput(){
        // create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        SRV_Response m_srvResponse = ( SRV_Response ) dfflib.service.defineMock( mocks, SRV_Response.class );

        // set mocks
        mocks.startStubbing();
        stubResponseService( mocks, m_srvResponse );
        mocks.stopStubbing();

        // When - empty list fails validation
        CTRL_RoomReservations.createReservations( new List<RoomReservation__c>() );

        // Then - dfflib_Utils.verifyNotEmpty message
        ( ( SRV_Response ) mocks.verify( m_srvResponse, 1 ) ).setResponse(
            SRV_Response.TYPES.INVALID_REQUEST,
            dfflib_Utils.message( '{0} cannot be empty', 'reservations' )
        );
    }

    @IsTest
    private static void createReservations_invalidRecords(){
        // create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        dfflib_ISObjectUnitOfWork uowMock = dfflib.unitOfWork.defineMock( mocks );
        DOM_RoomReservations m_domReservations = ( DOM_RoomReservations ) dfflib.domain.defineMock( mocks, DOM_RoomReservations.class, RoomReservation__c.SObjectType );
        SRV_Response m_srvResponse = ( SRV_Response ) dfflib.service.defineMock( mocks, SRV_Response.class );

        // Given - domain validation fails on the first invalid record
        String validationMessage = 'Room cannot be null';
        RoomReservation__c reservation = ( RoomReservation__c ) TestFactory.aRoomReservation()
            .asDefault()
            .mock();

        // set mocks
        mocks.startStubbing();
        ( ( DOM_RoomReservations ) mocks.doThrowWhen(
            new dfflib_Utils.InvalidInputValueException( validationMessage ),
            m_domReservations
        ) ).validateRecords();
        stubResponseService( mocks, m_srvResponse );
        mocks.stopStubbing();

        // When
        CTRL_RoomReservations.createReservations( new List<RoomReservation__c>{ reservation } );

        // Then - nothing committed; validation message returned as INVALID_REQUEST
        ( ( dfflib_ISObjectUnitOfWork ) mocks.verify( uowMock, mocks.never() ) ).commitWork();
        ( ( SRV_Response ) mocks.verify( m_srvResponse, 1 ) ).setResponse(
            SRV_Response.TYPES.INVALID_REQUEST,
            validationMessage
        );
    }

    @IsTest
    private static void createReservations_dmlException(){
        // create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        dfflib_ISObjectUnitOfWork uowMock = dfflib.unitOfWork.defineMock( mocks );
        dfflib.domain.defineMock( mocks, DOM_RoomReservations.class, RoomReservation__c.SObjectType );
        SRV_Response m_srvResponse = ( SRV_Response ) dfflib.service.defineMock( mocks, SRV_Response.class );

        // Given - a DmlException and default RoomReservation
        String exceptionMessage = 'Fake exception message';
        RoomReservation__c reservation = ( RoomReservation__c ) TestFactory.aRoomReservation()
            .asDefault()
            .mock();

        // set mocks
        mocks.startStubbing();
        ( ( dfflib_ISObjectUnitOfWork ) mocks.doThrowWhen( new DmlException( exceptionMessage ), uowMock ) ).commitWork();
        stubResponseService( mocks, m_srvResponse );
        mocks.stopStubbing();

        // When - exception is caught -> DML_ERROR response returned instead of re-thrown
        CTRL_RoomReservations.createReservations( new List<RoomReservation__c>{ reservation } );

        // Then - generic user-friendly message is returned, technical message is not exposed
        ( ( SRV_Response ) mocks.verify( m_srvResponse, 1 ) ).setResponse(
            SRV_Response.TYPES.DML_ERROR,
            CTRL_RoomReservations.MSG_DML_ERROR
        );
    }

    @IsTest
    private static void createReservations_partialFailure(){
        // create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        dfflib_ISObjectUnitOfWork uowMock = dfflib.unitOfWork.defineMock( mocks );
        dfflib.domain.defineMock( mocks, DOM_RoomReservations.class, RoomReservation__c.SObjectType );
        SRV_Response m_srvResponse = ( SRV_Response ) dfflib.service.defineMock( mocks, SRV_Response.class );

        // Given - two reservations, of which the second fails on insert (partial success via allOrNone = false)
        List<RoomReservation__c> reservations = new List<RoomReservation__c>{
            ( RoomReservation__c ) TestFactory.aRoomReservation().asDefault().mock(),
            ( RoomReservation__c ) TestFactory.aRoomReservation().asDefault().mock()
        };
        String dmlMessage = 'The room is already booked for these dates';
        List<Database.SaveResult> saveResults = new List<Database.SaveResult>{
            dfflib_UT_Utils.createSaveResult( fflib_IDGenerator.generate( RoomReservation__c.SObjectType ), true, null ),
            dfflib_UT_Utils.createSaveResult( null, false, dmlMessage )
        };

        // set mocks
        mocks.startStubbing();
        mocks.when( uowMock.getNewResults( RoomReservation__c.SObjectType ) ).thenReturn( saveResults );
        stubResponseService( mocks, m_srvResponse );
        mocks.stopStubbing();

        // When
        CTRL_RoomReservations.createReservations( reservations );

        // Then - committed once; DML_ERROR with the failed record's message keyed by its index
        ( ( dfflib_ISObjectUnitOfWork ) mocks.verify( uowMock, 1 ) ).commitWork();
        ( ( SRV_Response ) mocks.verify( m_srvResponse, 1 ) ).setResponse(
            SRV_Response.TYPES.DML_ERROR,
            '1 of 2 reservations failed'
        );
        ( ( SRV_Response ) mocks.verify( m_srvResponse, 1 ) ).setPayload(
            new Map<Integer, String>{ 1 => dmlMessage }
        );
    }

    // ============================================================================
    // cancelReservations
    // ============================================================================

    @IsTest
    private static void cancelReservations_validIds(){
        // create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        dfflib_ISObjectUnitOfWork uowMock = dfflib.unitOfWork.defineMock( mocks );
        SRV_Response m_srvResponse = ( SRV_Response ) dfflib.service.defineMock( mocks, SRV_Response.class );

        // Given - two reservations to cancel
        List<Id> reservationIds = new List<Id>{
            fflib_IDGenerator.generate( RoomReservation__c.SObjectType ),
            fflib_IDGenerator.generate( RoomReservation__c.SObjectType )
        };

        // set mocks
        mocks.startStubbing();
        stubResponseService( mocks, m_srvResponse );
        mocks.stopStubbing();

        // When
        CTRL_RoomReservations.cancelReservations( reservationIds );

        // Then - verify registerDirty per record, a single commitWork, and OK response
        for( Integer i = 0, j = reservationIds.size(); i < j; i++ ){
            ( ( dfflib_ISObjectUnitOfWork ) mocks.verify( uowMock, 1 ) ).registerDirty(
                new RoomReservation__c( Id = reservationIds[ i ], Status__c = DOM_RoomReservations.STATUS_CANCELLED )
            );
        }
        ( ( dfflib_ISObjectUnitOfWork ) mocks.verify( uowMock, 1 ) ).commitWork();
        ( ( SRV_Response ) mocks.verify( m_srvResponse, 1 ) ).setResponse( SRV_Response.TYPES.OK, null );
    }

    @IsTest
    private static void cancelReservations_nullInput(){
        // create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        SRV_Response m_srvResponse = ( SRV_Response ) dfflib.service.defineMock( mocks, SRV_Response.class );

        // set mocks
        mocks.startStubbing();
        stubResponseService( mocks, m_srvResponse );
        mocks.stopStubbing();

        // When - null reservationIds
        CTRL_RoomReservations.cancelReservations( null );

        // Then - dfflib_Utils.verifyNotEmpty message
        ( ( SRV_Response ) mocks.verify( m_srvResponse, 1 ) ).setResponse(
            SRV_Response.TYPES.INVALID_REQUEST,
            'reservationIds cannot be empty'
        );
    }

    @IsTest
    private static void cancelReservations_emptyInput(){
        // create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        dfflib_ISObjectUnitOfWork uowMock = dfflib.unitOfWork.defineMock( mocks );
        SRV_Response m_srvResponse = ( SRV_Response ) dfflib.service.defineMock( mocks, SRV_Response.class );

        // set mocks
        mocks.startStubbing();
        stubResponseService( mocks, m_srvResponse );
        mocks.stopStubbing();

        // When - empty list
        CTRL_RoomReservations.cancelReservations( new List<Id>() );

        // Then - nothing committed; INVALID_REQUEST
        ( ( dfflib_ISObjectUnitOfWork ) mocks.verify( uowMock, mocks.never() ) ).commitWork();
        ( ( SRV_Response ) mocks.verify( m_srvResponse, 1 ) ).setResponse(
            SRV_Response.TYPES.INVALID_REQUEST,
            'reservationIds cannot be empty'
        );
    }

    @IsTest
    private static void cancelReservations_dmlException(){
        // create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        dfflib_ISObjectUnitOfWork uowMock = dfflib.unitOfWork.defineMock( mocks );
        SRV_Response m_srvResponse = ( SRV_Response ) dfflib.service.defineMock( mocks, SRV_Response.class );

        // Given
        String exceptionMessage = 'Fake exception message';

        // set mocks
        mocks.startStubbing();
        ( ( dfflib_ISObjectUnitOfWork ) mocks.doThrowWhen( new DmlException( exceptionMessage ), uowMock ) ).commitWork();
        stubResponseService( mocks, m_srvResponse );
        mocks.stopStubbing();

        // When
        CTRL_RoomReservations.cancelReservations( new List<Id>{ fflib_IDGenerator.generate( RoomReservation__c.SObjectType ) } );

        // Then - DML_ERROR with the generic user-friendly message
        ( ( SRV_Response ) mocks.verify( m_srvResponse, 1 ) ).setResponse(
            SRV_Response.TYPES.DML_ERROR,
            CTRL_RoomReservations.MSG_DML_ERROR
        );
    }
}