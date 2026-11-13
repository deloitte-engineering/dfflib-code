/**
 * Test class for SRVo_PostalCodeValidation.
 * Demonstrates mocking the outgoing HTTP request with ApexMocks instead of Test.setMock( HttpCalloutMock.class, ... ).
 *
 * Test strategy:
 * - dfflib.service.defineMock( mocks, SRV_Request.class ) replaces the request returned by SRV_Request.newInstance()
 * - All fluent builder methods are stubbed to return the mock itself, send() returns the HttpResponse per scenario
 * - The request configuration (method) is verified via mocks.verify()
 * - Construction of the request (endpoint, service name) is the responsibility of SRV_Request and validated in SRV_RequestTest
 */
@IsTest( isParallel = true )
private with sharing class SRVo_PostalCodeValidationTest{

    /**
     * Happy-path: valid postal code returns a populated AddressResult.
     */
    @IsTest
    private static void lookupAddress_addressFound(){
        // create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        SRV_Request m_request = ( SRV_Request ) dfflib.service.defineMock( mocks, SRV_Request.class );

        // Given - service instance; API returns a valid address JSON
        SRVo_PostalCodeValidation service = new SRVo_PostalCodeValidation();

        HttpResponse response = new HttpResponse();
        response.setStatusCode( 200 );
        response.setHeader( 'Content-Type', 'application/json' );
        response.setBody( JSON.serialize( new Map<String, Object>{
            'street'              => 'Damrak',
            'city'                => 'Amsterdam',
            'municipality'        => 'Amsterdam',
            'province'            => 'Noord-Holland',
            'postcode'            => '1012LG',
            'houseNumber'         => 1,
            'houseNumberAddition' => null,
            'rdX'                 => '121000',
            'rdY'                 => '487000'
        } ) );

        // set mocks
        mocks.startStubbing();
        mocks.when( m_request.setMethod( fflib_Match.anyString() ) ).thenReturn( m_request );
        mocks.when( m_request.setTimeout( fflib_Match.anyInteger() ) ).thenReturn( m_request );
        mocks.when( m_request.setHeader( fflib_Match.anyString(), fflib_Match.anyString() ) ).thenReturn( m_request );
        mocks.when( m_request.send() ).thenReturn( response );
        mocks.stopStubbing();

        // When - look up a known postal code
        SRVo_PostalCodeValidation.AddressResult result = service.lookupAddress( '1012LG', '1' );

        // Then - request is configured correctly and result is populated with the mocked address fields
        ( ( SRV_Request ) mocks.verify( m_request ) ).setMethod( App_HTTP.METHOD_GET );
        ( ( SRV_Request ) mocks.verify( m_request, 1 ) ).send();

        System.Assert.isNotNull( result, 'Result should not be null for a valid postal code' );
        System.Assert.areEqual( 'Damrak', result.street, 'Street should match mocked value' );
        System.Assert.areEqual( 'Amsterdam', result.city, 'City should match mocked value' );
        System.Assert.areEqual( 'Amsterdam', result.municipality, 'Municipality should match mocked value' );
        System.Assert.areEqual( 'Noord-Holland', result.province, 'Province should match mocked value' );
        System.Assert.areEqual( '1012LG', result.postcode, 'Postcode should match mocked value' );
    }

    /**
     * When the API returns 404, lookupAddress should return null (no exception).
     */
    @IsTest
    private static void lookupAddress_addressNotFound(){
        // create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        SRV_Request m_request = ( SRV_Request ) dfflib.service.defineMock( mocks, SRV_Request.class );

        // Given - service instance; API returns 404
        SRVo_PostalCodeValidation service = new SRVo_PostalCodeValidation();

        HttpResponse response = new HttpResponse();
        response.setStatusCode( 404 );
        response.setBody( '{"message":"Not found"}' );

        // set mocks
        mocks.startStubbing();
        mocks.when( m_request.setMethod( fflib_Match.anyString() ) ).thenReturn( m_request );
        mocks.when( m_request.setTimeout( fflib_Match.anyInteger() ) ).thenReturn( m_request );
        mocks.when( m_request.setHeader( fflib_Match.anyString(), fflib_Match.anyString() ) ).thenReturn( m_request );
        mocks.when( m_request.send() ).thenReturn( response );
        mocks.stopStubbing();

        // When - look up a postal code that does not exist
        SRVo_PostalCodeValidation.AddressResult result = service.lookupAddress( '9999ZZ', '99' );

        // Then - request was sent and null is returned (not found is not an error)
        ( ( SRV_Request ) mocks.verify( m_request, 1 ) ).send();

        System.Assert.isNull( result, 'Result should be null when the API returns 404' );
    }

    /**
     * When the API returns a 5xx error, lookupAddress should throw an InvalidInputValueException.
     */
    @IsTest
    private static void lookupAddress_serverError(){
        // create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        SRV_Request m_request = ( SRV_Request ) dfflib.service.defineMock( mocks, SRV_Request.class );

        // Given - service instance; API returns 500
        SRVo_PostalCodeValidation service = new SRVo_PostalCodeValidation();

        HttpResponse response = new HttpResponse();
        response.setStatusCode( 500 );
        response.setBody( '{"message":"Internal Server Error"}' );

        // set mocks
        mocks.startStubbing();
        mocks.when( m_request.setMethod( fflib_Match.anyString() ) ).thenReturn( m_request );
        mocks.when( m_request.setTimeout( fflib_Match.anyInteger() ) ).thenReturn( m_request );
        mocks.when( m_request.setHeader( fflib_Match.anyString(), fflib_Match.anyString() ) ).thenReturn( m_request );
        mocks.when( m_request.send() ).thenReturn( response );
        mocks.stopStubbing();

        // When / Then - exception is thrown containing the status code
        try{
            service.lookupAddress( '1234AB', '10' );
            System.Assert.fail( 'Expected dfflib_Utils.InvalidInputValueException to be thrown' );
        } catch( dfflib_Utils.InvalidInputValueException ex ){
            System.Assert.isTrue(
                ex.getMessage().contains( '500' ),
                'Exception message should contain the HTTP status code 500, got: ' + ex.getMessage()
            );
        }
    }

    /**
     * When postalCode is blank, verifyNotBlank should throw an InvalidInputValueException
     * before any HTTP request is built or sent.
     */
    @IsTest
    private static void lookupAddress_blankPostalCode(){
        // create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        SRV_Request m_request = ( SRV_Request ) dfflib.service.defineMock( mocks, SRV_Request.class );

        // Given - a service instance
        SRVo_PostalCodeValidation service = new SRVo_PostalCodeValidation();

        // When / Then - blank postalCode triggers validation exception
        try{
            service.lookupAddress( '', '10' );
            System.Assert.fail( 'Expected dfflib_Utils.InvalidInputValueException to be thrown for blank postalCode' );
        } catch( dfflib_Utils.InvalidInputValueException ex ){
            System.Assert.isTrue(
                ex.getMessage().contains( 'postalCode' ),
                'Exception message should reference the "postalCode" parameter, got: ' + ex.getMessage()
            );
        }

        // Then - no request was sent
        ( ( SRV_Request ) mocks.verify( m_request, 0 ) ).send();
    }
}