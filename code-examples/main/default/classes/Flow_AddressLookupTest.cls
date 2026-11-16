/**
 * Test class for Flow_AddressLookup.
 * Demonstrates the D'fflib service mock pattern:
 * - dfflib.service.defineMock() replaces the real SRVo_PostalCodeValidation with a mock
 * - No HTTP callouts are made — the service layer is fully stubbed
 * - Flow_AddressLookup.lookupAddresses() is tested in isolation
 */
@IsTest( isParallel = true )
private with sharing class Flow_AddressLookupTest{

    // ============================================================================
    // TEST METHODS
    // ============================================================================

    /**
     * Happy-path: service returns an AddressResult — response should be populated
     * with addressFound = true and matching street/city values.
     */
    @IsTest
    private static void lookupAddresses_addressFound(){
        // create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        SRVo_PostalCodeValidation m_srv = ( SRVo_PostalCodeValidation ) dfflib.service.defineMock( mocks, SRVo_PostalCodeValidation.class );

        // Given - request for a known postal code and the populated AddressResult the service returns
        SRVo_PostalCodeValidation.AddressResult mockAddress = new SRVo_PostalCodeValidation.AddressResult();
        mockAddress.street       = 'Damrak';
        mockAddress.city         = 'Amsterdam';
        mockAddress.municipality = 'Amsterdam';
        mockAddress.province     = 'Noord-Holland';

        Flow_AddressLookup.Request req = new Flow_AddressLookup.Request();
        req.postalCode  = '1012LG';
        req.houseNumber = '1';

        // set mocks
        mocks.startStubbing();
        mocks.when( m_srv.lookupAddress( '1012LG', '1' ) ).thenReturn( mockAddress );
        mocks.stopStubbing();

        // When - invoke the flow action
        List<Flow_AddressLookup.Response> responses = Flow_AddressLookup.lookupAddresses(
            new List<Flow_AddressLookup.Request>{ req }
        );

        // Then - response indicates address found with correct field values
        System.Assert.areEqual( 1, responses.size(), 'Expected exactly 1 response' );
        Flow_AddressLookup.Response resp = responses[ 0 ];
        System.Assert.isTrue( resp.addressFound, 'addressFound should be true when address is returned' );
        System.Assert.areEqual( 'Damrak', resp.street, 'Street should match stubbed value' );
        System.Assert.areEqual( 'Amsterdam', resp.city, 'City should match stubbed value' );
        System.Assert.areEqual( 'Amsterdam', resp.municipality, 'Municipality should match stubbed value' );
        System.Assert.areEqual( 'Noord-Holland', resp.province, 'Province should match stubbed value' );
        System.Assert.isNull( resp.errorMessage, 'errorMessage should be null on success' );
    }

    /**
     * When the service returns null (404 from API), addressFound should be false
     * and errorMessage should mention the postal code.
     */
    @IsTest
    private static void lookupAddresses_addressNotFound(){
        // create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        SRVo_PostalCodeValidation m_srv = ( SRVo_PostalCodeValidation ) dfflib.service.defineMock( mocks, SRVo_PostalCodeValidation.class );

        // Given - request for an unknown postal code; service returns null
        Flow_AddressLookup.Request req = new Flow_AddressLookup.Request();
        req.postalCode  = '9999ZZ';
        req.houseNumber = '99';

        // set mocks
        mocks.startStubbing();
        mocks.when( m_srv.lookupAddress( '9999ZZ', '99' ) ).thenReturn( null );
        mocks.stopStubbing();

        // When - invoke the flow action
        List<Flow_AddressLookup.Response> responses = Flow_AddressLookup.lookupAddresses(
            new List<Flow_AddressLookup.Request>{ req }
        );

        // Then - addressFound is false and errorMessage references the postal code
        System.Assert.areEqual( 1, responses.size(), 'Expected exactly 1 response' );
        Flow_AddressLookup.Response resp = responses[ 0 ];
        System.Assert.isFalse( resp.addressFound, 'addressFound should be false when address is not found' );
        System.Assert.isTrue(
            resp.errorMessage.contains( '9999ZZ' ),
            'errorMessage should reference the postal code, got: ' + resp.errorMessage
        );
    }

    /**
     * When the service throws an exception, addressFound should be false
     * and errorMessage should be populated with the exception message.
     */
    @IsTest
    private static void lookupAddresses_serviceException(){
        // create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        SRVo_PostalCodeValidation m_srv = ( SRVo_PostalCodeValidation ) dfflib.service.defineMock( mocks, SRVo_PostalCodeValidation.class );

        // Given - request for which the service throws an InvalidInputValueException
        Flow_AddressLookup.Request req = new Flow_AddressLookup.Request();
        req.postalCode  = '1234AB';
        req.houseNumber = '10';

        // set mocks
        mocks.startStubbing();
        mocks.when( m_srv.lookupAddress( '1234AB', '10' ) )
            .thenThrow( new dfflib_Utils.InvalidInputValueException( 'PostcodeAPI returned 500: Internal Server Error' ) );
        mocks.stopStubbing();

        // When - invoke the flow action
        List<Flow_AddressLookup.Response> responses = Flow_AddressLookup.lookupAddresses(
            new List<Flow_AddressLookup.Request>{ req }
        );

        // Then - exception is caught, addressFound is false, errorMessage is set
        System.Assert.areEqual( 1, responses.size(), 'Expected exactly 1 response' );
        Flow_AddressLookup.Response resp = responses[ 0 ];
        System.Assert.isFalse( resp.addressFound, 'addressFound should be false when exception is thrown' );
        System.Assert.isNotNull( resp.errorMessage, 'errorMessage should not be null after exception' );
        System.Assert.isFalse( String.isBlank( resp.errorMessage ), 'errorMessage should not be blank after exception' );
    }

    /**
     * Multiple requests in a single invocation are all processed independently.
     * Both should return addressFound = true with the correct address data.
     */
    @IsTest
    private static void lookupAddresses_multipleRequests(){
        // create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        SRVo_PostalCodeValidation m_srv = ( SRVo_PostalCodeValidation ) dfflib.service.defineMock( mocks, SRVo_PostalCodeValidation.class );

        // Given - two requests for different postal codes, each with its own AddressResult
        SRVo_PostalCodeValidation.AddressResult amsterdam = new SRVo_PostalCodeValidation.AddressResult();
        amsterdam.street = 'Damrak';
        amsterdam.city   = 'Amsterdam';

        SRVo_PostalCodeValidation.AddressResult rotterdam = new SRVo_PostalCodeValidation.AddressResult();
        rotterdam.street = 'Coolsingel';
        rotterdam.city   = 'Rotterdam';

        Flow_AddressLookup.Request req1 = new Flow_AddressLookup.Request();
        req1.postalCode  = '1012LG';
        req1.houseNumber = '1';

        Flow_AddressLookup.Request req2 = new Flow_AddressLookup.Request();
        req2.postalCode  = '3011AD';
        req2.houseNumber = '5';

        // set mocks
        mocks.startStubbing();
        mocks.when( m_srv.lookupAddress( '1012LG', '1' ) ).thenReturn( amsterdam );
        mocks.when( m_srv.lookupAddress( '3011AD', '5' ) ).thenReturn( rotterdam );
        mocks.stopStubbing();

        // When - invoke the flow action with two requests
        List<Flow_AddressLookup.Response> responses = Flow_AddressLookup.lookupAddresses(
            new List<Flow_AddressLookup.Request>{ req1, req2 }
        );

        // Then - both responses are returned and both addresses are found
        System.Assert.areEqual( 2, responses.size(), 'Expected exactly 2 responses' );

        System.Assert.isTrue( responses[ 0 ].addressFound, 'First response: addressFound should be true' );
        System.Assert.areEqual( 'Damrak', responses[ 0 ].street, 'First response: street should be Damrak' );
        System.Assert.areEqual( 'Amsterdam', responses[ 0 ].city, 'First response: city should be Amsterdam' );

        System.Assert.isTrue( responses[ 1 ].addressFound, 'Second response: addressFound should be true' );
        System.Assert.areEqual( 'Coolsingel', responses[ 1 ].street, 'Second response: street should be Coolsingel' );
        System.Assert.areEqual( 'Rotterdam', responses[ 1 ].city, 'Second response: city should be Rotterdam' );
    }
}