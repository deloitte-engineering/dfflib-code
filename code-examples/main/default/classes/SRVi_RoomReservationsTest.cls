/**
 * Test class for SRVi_RoomReservations
 *
 * Pattern summary:
 * - All dependencies (UoW, Selector, SRV_Response) are mocked via defineMock()
 * - RestContext request/response set per test to simulate the incoming API call
 * - fflib_Match.sObjectWith() to verify the registered records by their relevant field values
 * - Verifying the relationship registration (registerNew with parent) for both a new and a matched (existing) guest
 * - Bulk: multiple bookings for the same new guest share one registered Contact
 * - fflib_ArgumentCaptor to verify the per-reservation response payload
 * - Consistent Given/When/Then structure and clear method names
 */
@IsTest( isParallel = true )
private with sharing class SRVi_RoomReservationsTest{
    private static final String EMAIL       = 'jane.doe@example.com';
    private static final Id ROOM_ID         = fflib_IDGenerator.generate( Room__c.SObjectType );
    private static final Date CHECK_IN      = Date.today().addDays( 0 );
    private static final Date CHECK_OUT     = Date.today().addDays( 3 );

    /**
     * Builds a valid request body; individual attributes can be overridden by the caller via the Maps
     */
    private static Map<String, Object> aGuest(){
        return new Map<String, Object>{ 'firstName' => 'Jane', 'lastName' => 'Doe', 'email' => EMAIL, 'phone' => '+31612345678' };
    }
    private static Map<String, Object> aReservation(){
        return new Map<String, Object>{
            'roomId' => ROOM_ID, 'checkInDate' => CHECK_IN, 'checkOutDate' => CHECK_OUT,
            'numberOfGuests' => 2, 'specialRequests' => 'Late check-in'
        };
    }
    private static Map<String, Object> aBooking( Map<String, Object> guest, Map<String, Object> reservation ){
        return new Map<String, Object>{ 'guest' => guest, 'reservation' => reservation };
    }
    private static String aBody( Map<String, Object> guest, Map<String, Object> reservation ){
        return aBody( new List<Object>{ aBooking( guest, reservation ) } );
    }
    private static String aBody( List<Object> bookings ){
        return JSON.serialize( new Map<String, Object>{ 'bookings' => bookings } );
    }

    /**
     * Sets the RestContext to simulate an incoming POST request with the given body
     */
    private static void setRestContext( String body ){
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/reservations/create';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf( body );
        RestContext.request = req;
        RestContext.response = new RestResponse();
    }

    /**
     * Stubs the SRV_Response mock to avoid null-pointers in the fluent chain. Must be called between startStubbing() and stopStubbing().
     */
    private static void stubResponseService( fflib_ApexMocks mocks, SRV_Response m_srvResponse ){
        mocks.when( m_srvResponse.setResponse( ( SRV_Response.TYPES ) fflib_Match.anyObject(), ( String ) fflib_Match.anyObject() ) ).thenReturn( m_srvResponse );
        mocks.when( m_srvResponse.setPayload( fflib_Match.anyObject(), ( String ) fflib_Match.anyObject() ) ).thenReturn( m_srvResponse );
        // fflib_Match.anyObject() does not match null, so stub null payloads (Ids of mocked commit) separately
        mocks.when( m_srvResponse.setPayload( fflib_Match.isNull(), ( String ) fflib_Match.anyObject() ) ).thenReturn( m_srvResponse );
    }

    // ============================================================================
    // SUCCESS SCENARIOS
    // ============================================================================

    @IsTest
    private static void newGuest_registersRelationship(){
        // create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        dfflib_ISObjectUnitOfWork uowMock = dfflib.unitOfWork.defineMock( mocks );
        SEL_Contacts m_selContacts = ( SEL_Contacts ) dfflib.selector.defineMock( mocks, SEL_Contacts.class, Contact.SObjectType );
        SRV_Response m_srvResponse = ( SRV_Response ) dfflib.service.defineMock( mocks, SRV_Response.class );

        // Given - no existing Contact for the email
        setRestContext( aBody( aGuest(), aReservation() ) );

        // set mocks
        mocks.startStubbing();
        mocks.when( m_selContacts.selectByEmails( new Set<String>{ EMAIL } ) ).thenReturn( new List<Contact>() );
        stubResponseService( mocks, m_srvResponse );
        mocks.stopStubbing();

        // When
        SRVi_RoomReservations.handleRequest();

        // Then - new Contact registered, reservation registered WITH relationship to that new Contact, single commit
        Map<SObjectField, Object> expectedContactMap = new Map<SObjectField, Object>{
            Contact.FirstName => 'Jane', Contact.LastName => 'Doe', Contact.Email => EMAIL, Contact.Phone => '+31612345678'
        };
        ( ( dfflib_ISObjectUnitOfWork ) mocks.verify( uowMock, 1 ) ).registerNew( fflib_Match.sObjectWith( expectedContactMap ) );
        ( ( dfflib_ISObjectUnitOfWork ) mocks.verify( uowMock, 1 ) ).registerNew(
            fflib_Match.sObjectWith( new Map<SObjectField, Object>{
                RoomReservation__c.Room__c          => ROOM_ID,
                RoomReservation__c.CheckInDate__c   => CHECK_IN,
                RoomReservation__c.CheckOutDate__c  => CHECK_OUT,
                RoomReservation__c.Status__c        => DOM_RoomReservations.STATUS_SUBMITTED
            } ),
            ( Schema.SObjectField ) fflib_Match.eq( RoomReservation__c.Contact__c ),
            fflib_Match.sObjectWith( expectedContactMap )
        );
        ( ( dfflib_ISObjectUnitOfWork ) mocks.verify( uowMock, 1 ) ).commitWork();
        ( ( SRV_Response ) mocks.verify( m_srvResponse, 1 ) ).setResponse( SRV_Response.TYPES.CREATED, SRVi_RoomReservations.MSG_CREATED );
    }

    @IsTest
    private static void newGuest_returnsHttp201(){
        // create mocks - SRV_Response NOT mocked, to validate the actual REST response
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        dfflib.unitOfWork.defineMock( mocks );
        SEL_Contacts m_selContacts = ( SEL_Contacts ) dfflib.selector.defineMock( mocks, SEL_Contacts.class, Contact.SObjectType );

        // Given
        setRestContext( aBody( aGuest(), aReservation() ) );

        // set mocks
        mocks.startStubbing();
        mocks.when( m_selContacts.selectByEmails( new Set<String>{ EMAIL } ) ).thenReturn( new List<Contact>() );
        mocks.stopStubbing();

        // When
        SRVi_RoomReservations.handleRequest();

        // Then - HTTP 201 with the CREATED type and payload keys in the JSON body
        RestResponse res = RestContext.response;
        System.Assert.areEqual( 201, res.statusCode, 'Expected HTTP 201 Created' );
        Map<String, Object> body = ( Map<String, Object> ) JSON.deserializeUntyped( res.responseBody.toString() );
        System.Assert.areEqual( 'CREATED', body.get( 'type' ), 'Expected CREATED response type' );
        Map<String, Object> payload = ( Map<String, Object> ) body.get( 'payload' );
        List<Object> reservations = ( List<Object> ) payload.get( 'reservations' );
        System.Assert.areEqual( 1, reservations.size(), 'Expected one reservation in payload' );
        Map<String, Object> reservation = ( Map<String, Object> ) reservations[ 0 ];
        System.Assert.isTrue( reservation.containsKey( 'reservationId' ), 'Expected reservationId in payload' );
        System.Assert.isTrue( reservation.containsKey( 'contactId' ), 'Expected contactId in payload' );
    }

    @IsTest
    private static void existingGuest_registersRelationship(){
        // create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        dfflib_ISObjectUnitOfWork uowMock = dfflib.unitOfWork.defineMock( mocks );
        SEL_Contacts m_selContacts = ( SEL_Contacts ) dfflib.selector.defineMock( mocks, SEL_Contacts.class, Contact.SObjectType );
        SRV_Response m_srvResponse = ( SRV_Response ) dfflib.service.defineMock( mocks, SRV_Response.class );

        // Given - an existing Contact for the email, with an outdated phone number
        Contact existing = ( Contact ) TestFactory.aContact().withName( 'Jane', 'Doe' ).withEmail( EMAIL ).withPhone( '+31600000000' ).mockWithIds();
        setRestContext( aBody( aGuest(), aReservation() ) );

        // set mocks
        mocks.startStubbing();
        mocks.when( m_selContacts.selectByEmails( new Set<String>{ EMAIL } ) ).thenReturn( new List<Contact>{ existing } );
        stubResponseService( mocks, m_srvResponse );
        mocks.stopStubbing();

        // When
        SRVi_RoomReservations.handleRequest();

        // Then - matched Contact left untouched: not registered as new, nor as dirty
        ( ( dfflib_ISObjectUnitOfWork ) mocks.verify( uowMock, mocks.never() ) ).registerNew( fflib_Match.anySObject() );
        ( ( dfflib_ISObjectUnitOfWork ) mocks.verify( uowMock, mocks.never() ) ).registerDirty( fflib_Match.anySObject() );
        // Then - reservation registered WITH relationship to the matched Contact (resolved from its existing Id at commit)
        ( ( dfflib_ISObjectUnitOfWork ) mocks.verify( uowMock, 1 ) ).registerNew(
            fflib_Match.sObjectWith( new Map<SObjectField, Object>{
                RoomReservation__c.Room__c          => ROOM_ID,
                RoomReservation__c.CheckInDate__c   => CHECK_IN,
                RoomReservation__c.CheckOutDate__c  => CHECK_OUT,
                RoomReservation__c.Status__c        => DOM_RoomReservations.STATUS_SUBMITTED
            } ),
            ( Schema.SObjectField ) fflib_Match.eq( RoomReservation__c.Contact__c ),
            fflib_Match.sObjectWith( new Map<SObjectField, Object>{ Contact.Id => existing.Id } )
        );
        ( ( dfflib_ISObjectUnitOfWork ) mocks.verify( uowMock, 1 ) ).commitWork();
        ( ( SRV_Response ) mocks.verify( m_srvResponse, 1 ) ).setResponse( SRV_Response.TYPES.CREATED, SRVi_RoomReservations.MSG_CREATED );
        // Then - payload holds one entry per reservation; contactId is resolved by the (mocked) Unit of Work at commit,
        // which is covered by the relationship registration verified above
        fflib_ArgumentCaptor payloadCaptor = fflib_ArgumentCaptor.forClass( List<Map<String, Object>>.class );
        ( ( SRV_Response ) mocks.verify( m_srvResponse, 1 ) ).setPayload( payloadCaptor.capture(), ( String ) fflib_Match.eq( 'reservations' ) );
        List<Map<String, Object>> payload = ( List<Map<String, Object>> ) payloadCaptor.getValue();
        System.Assert.areEqual( 1, payload.size(), 'Expected one reservation in payload' );
    }

    @IsTest
    private static void sameNewGuest_registersOneContact(){
        // create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        dfflib_ISObjectUnitOfWork uowMock = dfflib.unitOfWork.defineMock( mocks );
        SEL_Contacts m_selContacts = ( SEL_Contacts ) dfflib.selector.defineMock( mocks, SEL_Contacts.class, Contact.SObjectType );
        SRV_Response m_srvResponse = ( SRV_Response ) dfflib.service.defineMock( mocks, SRV_Response.class );

        // Given - two bookings for the same new guest, email differing in case only
        Map<String, Object> sameGuest = aGuest();
        sameGuest.put( 'email', EMAIL.toUpperCase() );
        setRestContext( aBody( new List<Object>{ aBooking( aGuest(), aReservation() ), aBooking( sameGuest, aReservation() ) } ) );

        // set mocks
        mocks.startStubbing();
        mocks.when( m_selContacts.selectByEmails( new Set<String>{ EMAIL } ) ).thenReturn( new List<Contact>() );
        stubResponseService( mocks, m_srvResponse );
        mocks.stopStubbing();

        // When
        SRVi_RoomReservations.handleRequest();

        // Then - one Contact registered, both reservations registered WITH relationship to that Contact, single commit
        ( ( dfflib_ISObjectUnitOfWork ) mocks.verify( uowMock, 1 ) ).registerNew( fflib_Match.anySObject() );
        ( ( dfflib_ISObjectUnitOfWork ) mocks.verify( uowMock, 2 ) ).registerNew(
            fflib_Match.anySObject(),
            ( Schema.SObjectField ) fflib_Match.eq( RoomReservation__c.Contact__c ),
            fflib_Match.sObjectWith( new Map<SObjectField, Object>{ Contact.Email => EMAIL } )
        );
        ( ( dfflib_ISObjectUnitOfWork ) mocks.verify( uowMock, 1 ) ).commitWork();
        ( ( SRV_Response ) mocks.verify( m_srvResponse, 1 ) ).setResponse( SRV_Response.TYPES.CREATED, SRVi_RoomReservations.MSG_CREATED );
    }

    // ============================================================================
    // FAILURE SCENARIOS
    // ============================================================================

    @IsTest
    private static void invalidJson_returnsInvalidFormat(){
        // create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        dfflib_ISObjectUnitOfWork uowMock = dfflib.unitOfWork.defineMock( mocks );
        SRV_Response m_srvResponse = ( SRV_Response ) dfflib.service.defineMock( mocks, SRV_Response.class );

        // Given - an unknown attribute, rejected by strict deserialization
        setRestContext( JSON.serialize( new Map<String, Object>{ 'bookings' => new List<Object>{ aBooking( aGuest(), aReservation() ) }, 'unknown' => true } ) );

        // set mocks
        mocks.startStubbing();
        stubResponseService( mocks, m_srvResponse );
        mocks.stopStubbing();

        // When
        SRVi_RoomReservations.handleRequest();

        // Then - nothing committed; INVALID_FORMAT
        ( ( dfflib_ISObjectUnitOfWork ) mocks.verify( uowMock, mocks.never() ) ).commitWork();
        ( ( SRV_Response ) mocks.verify( m_srvResponse, 1 ) ).setResponse(
            SRV_Response.TYPES.INVALID_FORMAT,
            SRVi_RoomReservations.MSG_INVALID_FORMAT
        );
    }

    @IsTest
    private static void noBookings_returnsInvalidRequest(){
        // create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        dfflib_ISObjectUnitOfWork uowMock = dfflib.unitOfWork.defineMock( mocks );
        SRV_Response m_srvResponse = ( SRV_Response ) dfflib.service.defineMock( mocks, SRV_Response.class );

        // Given - an empty list of bookings
        setRestContext( aBody( new List<Object>() ) );

        // set mocks
        mocks.startStubbing();
        stubResponseService( mocks, m_srvResponse );
        mocks.stopStubbing();

        // When
        SRVi_RoomReservations.handleRequest();

        // Then - nothing committed; validation message returned
        ( ( dfflib_ISObjectUnitOfWork ) mocks.verify( uowMock, mocks.never() ) ).commitWork();
        ( ( SRV_Response ) mocks.verify( m_srvResponse, 1 ) ).setResponse(
            SRV_Response.TYPES.INVALID_REQUEST,
            dfflib_Utils.message( '{0} cannot be empty', 'bookings' )
        );
    }

    @IsTest
    private static void missingEmail_returnsInvalidRequest(){
        // create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        dfflib_ISObjectUnitOfWork uowMock = dfflib.unitOfWork.defineMock( mocks );
        SRV_Response m_srvResponse = ( SRV_Response ) dfflib.service.defineMock( mocks, SRV_Response.class );

        // Given - guest without email
        Map<String, Object> guest = aGuest();
        guest.remove( 'email' );
        setRestContext( aBody( guest, aReservation() ) );

        // set mocks
        mocks.startStubbing();
        stubResponseService( mocks, m_srvResponse );
        mocks.stopStubbing();

        // When
        SRVi_RoomReservations.handleRequest();

        // Then - nothing committed; validation message returned
        ( ( dfflib_ISObjectUnitOfWork ) mocks.verify( uowMock, mocks.never() ) ).commitWork();
        ( ( SRV_Response ) mocks.verify( m_srvResponse, 1 ) ).setResponse(
            SRV_Response.TYPES.INVALID_REQUEST,
            dfflib_Utils.message( '{0} cannot be blank', 'guest.email' )
        );
    }

    @IsTest
    private static void commitFails_returnsDmlError(){
        // create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        dfflib_ISObjectUnitOfWork uowMock = dfflib.unitOfWork.defineMock( mocks );
        SEL_Contacts m_selContacts = ( SEL_Contacts ) dfflib.selector.defineMock( mocks, SEL_Contacts.class, Contact.SObjectType );
        SRV_Response m_srvResponse = ( SRV_Response ) dfflib.service.defineMock( mocks, SRV_Response.class );

        // Given
        setRestContext( aBody( aGuest(), aReservation() ) );

        // set mocks
        mocks.startStubbing();
        mocks.when( m_selContacts.selectByEmails( new Set<String>{ EMAIL } ) ).thenReturn( new List<Contact>() );
        ( ( dfflib_ISObjectUnitOfWork ) mocks.doThrowWhen( new DmlException( 'Fake exception message' ), uowMock ) ).commitWork();
        stubResponseService( mocks, m_srvResponse );
        mocks.stopStubbing();

        // When
        SRVi_RoomReservations.handleRequest();

        // Then - generic user-friendly message, technical message not exposed
        ( ( SRV_Response ) mocks.verify( m_srvResponse, 1 ) ).setResponse(
            SRV_Response.TYPES.DML_ERROR,
            SRVi_RoomReservations.MSG_DML_ERROR
        );
    }

    @IsTest
    private static void unexpectedException_returnsProcessingError(){
        // create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        dfflib_ISObjectUnitOfWork uowMock = dfflib.unitOfWork.defineMock( mocks );
        SEL_Contacts m_selContacts = ( SEL_Contacts ) dfflib.selector.defineMock( mocks, SEL_Contacts.class, Contact.SObjectType );
        SRV_Response m_srvResponse = ( SRV_Response ) dfflib.service.defineMock( mocks, SRV_Response.class );

        // Given - selector throws a technical exception
        setRestContext( aBody( aGuest(), aReservation() ) );

        // set mocks
        mocks.startStubbing();
        mocks.when( m_selContacts.selectByEmails( new Set<String>{ EMAIL } ) )
            .thenThrow( new dfflib_Utils.MissingDataException( 'Technical failure' ) );
        stubResponseService( mocks, m_srvResponse );
        mocks.stopStubbing();

        // When
        SRVi_RoomReservations.handleRequest();

        // Then - PROCESSING_ERROR, nothing committed
        ( ( SRV_Response ) mocks.verify( m_srvResponse, 1 ) ).setResponse(
            SRV_Response.TYPES.PROCESSING_ERROR,
            SRVi_RoomReservations.MSG_PROCESSING_ERROR
        );
        ( ( dfflib_ISObjectUnitOfWork ) mocks.verify( uowMock, mocks.never() ) ).commitWork();
    }
}
