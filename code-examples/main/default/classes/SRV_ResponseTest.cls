/**
 * Test class for SRV_Response.
 * Validates the construction of both LWC and REST responses, the population of type, message and payload,
 * the REST specifics (statusCode, headers and responseBody) and the guards against invalid usage.
 *
 * Test strategy:
 * - newInstance() resolves the real implementation via Dfflib_Service_Config__mdt, hence no ApexMocks;
 *   consuming classes mock SRV_Response itself via dfflib.service.defineMock( mocks, SRV_Response.class ) (see CTRL_RoomReservationsTest)
 * - REST responses are constructed with a plain new RestResponse(), so no RestContext is required
 * - The REST responseBody is deserialized untyped to validate what the receiving party would actually get
 */
@IsTest( isParallel = true )
private with sharing class SRV_ResponseTest{

    private static final String PAYLOAD_KEY = 'accountObject';
    private static final String MESSAGE     = 'MATCH';

    // ============================================================================
    // newInstance
    // ============================================================================

    @IsTest
    private static void newInstance_lwc(){
        // When
        SRV_Response.Response response = SRV_Response.newInstance().getResponse();

        // Then - LWC Response is initialised without any values
        System.Assert.isInstanceOfType( response, SRV_Response.LWC_Response.class, 'Response should be an LWC_Response as no RestResponse is provided' );
        System.Assert.isNull( response.type, 'Type should not be set' );
        System.Assert.isNull( response.message, 'Message should not be set' );
        System.Assert.isNull( response.payload, 'Payload should not be set' );
        System.Assert.isNull( ( ( SRV_Response.LWC_Response ) response ).isSuccess, 'isSuccess should not be set' );
    }

    @IsTest
    private static void newInstance_rest(){
        // Given
        RestResponse res = new RestResponse();

        // When
        SRV_Response.Response response = SRV_Response.newInstance( res ).getResponse();

        // Then - REST Response is initialised with an empty payload Map and a JSON Content-Type header
        System.Assert.isInstanceOfType( response, SRV_Response.REST_Response.class, 'Response should be a REST_Response as a RestResponse is provided' );
        System.Assert.isInstanceOfType( response.payload, Map<String, Object>.class, 'Payload should be a Map' );
        System.Assert.isTrue( ( ( Map<String, Object> ) response.payload ).isEmpty(), 'Payload should be empty' );
        System.Assert.areEqual( App_HTTP.HEADER_CONTENTTYPE_JSON, res.headers.get( App_HTTP.HEADER_CONTENTTYPE ), 'Content-Type should be JSON' );
    }

    // ============================================================================
    // LWC Response
    // ============================================================================

    @IsTest
    private static void lwcResponse_success(){
        // Given
        Account account = new Account( Name = 'test' );
        SRV_Response service = SRV_Response.newInstance();

        // When
        SRV_Response result = service
            .setResponse( SRV_Response.TYPES.OK, MESSAGE )
            .setPayload( account );
        SRV_Response.LWC_Response okResponse = ( SRV_Response.LWC_Response ) result.getResponse();
        SRV_Response.LWC_Response createdResponse = ( SRV_Response.LWC_Response ) SRV_Response.newInstance()
            .setResponse( SRV_Response.TYPES.CREATED, null )
            .getResponse();

        // Then - same instance is returned for chaining and the response is populated as success
        System.Assert.areEqual( service, result, 'Builder methods should return the same instance' );
        System.Assert.areEqual( SRV_Response.TYPES.OK, okResponse.type, 'Type should be set' );
        System.Assert.areEqual( MESSAGE, okResponse.message, 'Message should be set' );
        System.Assert.areEqual( account, okResponse.payload, 'Payload should be set as provided' );
        System.Assert.isTrue( okResponse.isSuccess, 'OK should be a success' );
        System.Assert.isTrue( createdResponse.isSuccess, 'CREATED should be a success' );
    }

    @IsTest
    private static void lwcResponse_failure(){
        // Given
        String errorMessage = '1 of 2 records failed';
        Map<Integer, String> errors = new Map<Integer, String>{ 1 => 'Required field missing' };

        // When - a failure set after an initial OK, and a response without a type
        SRV_Response.LWC_Response failureResponse = ( SRV_Response.LWC_Response ) SRV_Response.newInstance()
            .setResponse( SRV_Response.TYPES.OK, null )
            .setResponse( SRV_Response.TYPES.DML_ERROR, errorMessage )
            .setPayload( errors )
            .getResponse();
        SRV_Response.LWC_Response nullTypeResponse = ( SRV_Response.LWC_Response ) SRV_Response.newInstance()
            .setResponse( null, errorMessage )
            .getResponse();

        // Then - failure overwrites the earlier OK, message and payload are kept; no type is never a success
        System.Assert.areEqual( SRV_Response.TYPES.DML_ERROR, failureResponse.type, 'Type should be overwritten' );
        System.Assert.areEqual( errorMessage, failureResponse.message, 'Message should be overwritten' );
        System.Assert.areEqual( errors, failureResponse.payload, 'Payload should be set as provided' );
        System.Assert.isFalse( failureResponse.isSuccess, 'DML_ERROR should not be a success' );
        System.Assert.isNull( nullTypeResponse.type, 'Type should be empty' );
        System.Assert.isFalse( nullTypeResponse.isSuccess, 'Empty type should not be a success' );
    }

    @IsTest
    private static void lwcResponse_invalidUsage(){
        // Given
        SRV_Response service = SRV_Response.newInstance();

        // When - payload with a key
        try{
            service.setPayload( new Account( Name = 'test' ), PAYLOAD_KEY );
            System.Assert.fail( 'Expected InvalidImplementationException for a payload key' );
        } catch( dfflib_Utils.InvalidImplementationException ex ){
            // Then
            System.Assert.areEqual( 'LWC Response Payload should NEVER contain a key', ex.getMessage(), 'Payload key should be rejected' );
        }

        // When - header on an LWC Response
        try{
            service.setHeader( App_HTTP.HEADER_ACCEPT, App_HTTP.HEADER_ACCEPT_JSON );
            System.Assert.fail( 'Expected InvalidImplementationException for a header' );
        } catch( dfflib_Utils.InvalidImplementationException ex ){
            // Then
            System.Assert.areEqual( 'LWC Responses do not have Headers', ex.getMessage(), 'Header should be rejected' );
        }
    }

    // ============================================================================
    // REST Response
    // ============================================================================

    @IsTest
    private static void restResponse_populated(){
        // Given
        RestResponse res = new RestResponse();
        SRV_Response service = SRV_Response.newInstance( res );

        // When - payload set before the response to show the sequence does not matter
        SRV_Response result = service
            .setPayload( new Account( Name = 'test' ), PAYLOAD_KEY )
            .setResponse( SRV_Response.TYPES.OK, MESSAGE )
            .setHeader( App_HTTP.HEADER_ACCEPT, App_HTTP.HEADER_ACCEPT_JSON );

        // Then - statusCode, headers and responseBody are populated for the receiving party
        Map<String, Object> body = ( Map<String, Object> ) JSON.deserializeUntyped( res.responseBody.toString() );
        Map<String, Object> payload = ( Map<String, Object> ) body.get( 'payload' );
        Map<String, Object> account = ( Map<String, Object> ) payload.get( PAYLOAD_KEY );
        System.Assert.areEqual( service, result, 'Builder methods should return the same instance' );
        System.Assert.areEqual( 200, res.statusCode, 'OK should map to status code 200' );
        System.Assert.areEqual( App_HTTP.HEADER_CONTENTTYPE_JSON, res.headers.get( App_HTTP.HEADER_CONTENTTYPE ), 'Content-Type should be JSON' );
        System.Assert.areEqual( App_HTTP.HEADER_ACCEPT_JSON, res.headers.get( App_HTTP.HEADER_ACCEPT ), 'Custom header should be set' );
        System.Assert.areEqual( 'OK', body.get( 'type' ), 'Type should be in the body' );
        System.Assert.areEqual( MESSAGE, body.get( 'message' ), 'Message should be in the body' );
        System.Assert.areEqual( 'test', account.get( 'Name' ), 'Payload should be in the body under its key' );
    }

    @IsTest
    private static void restResponse_failure(){
        // Given - one failure type per category: input, processing (functional) and processing (technical)
        RestResponse invalidRequestRes = new RestResponse();
        RestResponse noMatchRes = new RestResponse();
        RestResponse processingErrorRes = new RestResponse();

        // When
        SRV_Response.newInstance( invalidRequestRes ).setResponse( SRV_Response.TYPES.INVALID_REQUEST, 'Missing postal code' );
        SRV_Response.newInstance( noMatchRes ).setResponse( SRV_Response.TYPES.NO_MATCH, 'No account found' );
        SRV_Response.newInstance( processingErrorRes ).setResponse( SRV_Response.TYPES.PROCESSING_ERROR, 'Technical failure' );

        // Then - matching HTTP status codes and the failure in the body
        Map<String, Object> noMatchBody = ( Map<String, Object> ) JSON.deserializeUntyped( noMatchRes.responseBody.toString() );
        System.Assert.areEqual( 400, invalidRequestRes.statusCode, 'INVALID_REQUEST should map to status code 400' );
        System.Assert.areEqual( 412, noMatchRes.statusCode, 'NO_MATCH should map to status code 412' );
        System.Assert.areEqual( 500, processingErrorRes.statusCode, 'PROCESSING_ERROR should map to status code 500' );
        System.Assert.areEqual( 'NO_MATCH', noMatchBody.get( 'type' ), 'Type should be in the body' );
        System.Assert.areEqual( 'No account found', noMatchBody.get( 'message' ), 'Message should be in the body' );
    }

    @IsTest
    private static void restResponse_invalidUsage(){
        // Given
        SRV_Response service = SRV_Response.newInstance( new RestResponse() );

        // When - payload without a key
        try{
            service.setPayload( new Account( Name = 'test' ) );
            System.Assert.fail( 'Expected InvalidImplementationException for a missing payload key' );
        } catch( dfflib_Utils.InvalidImplementationException ex ){
            // Then
            System.Assert.areEqual( 'REST Response Payload should ALWAYS be set with a key', ex.getMessage(), 'Missing key should be rejected' );
        }

        // When - payload with a blank key
        try{
            service.setPayload( new Account( Name = 'test' ), ' ' );
            System.Assert.fail( 'Expected InvalidImplementationException for a blank payload key' );
        } catch( dfflib_Utils.InvalidImplementationException ex ){
            // Then
            System.Assert.areEqual( 'REST Response Payload should ALWAYS be set with a key', ex.getMessage(), 'Blank key should be rejected' );
        }
    }

    // ============================================================================
    // Response (base)
    // ============================================================================

    @IsTest
    private static void response_payloadKeyIgnored(){
        // Given - base Response via its @TestVisible constructor, as SRV_Response always constructs a subclass
        Account account = new Account( Name = 'test' );
        SRV_Response.Response response = new SRV_Response.Response();

        // When
        SRV_Response.Response result = response.setPayload( account, PAYLOAD_KEY );

        // Then - payload is set as provided and the key is ignored (no Map wrapping, no exception)
        System.Assert.areEqual( response, result, 'setPayload should return the same instance' );
        System.Assert.areEqual( account, response.payload, 'Payload should be set as provided, ignoring the key' );
    }
}