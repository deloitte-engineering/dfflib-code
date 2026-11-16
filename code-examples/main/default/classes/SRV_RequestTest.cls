/**
 * Test class for SRV_Request.
 * Validates the construction of the request (mandatory named credential endpoint and service name),
 * the fluent builder methods and the actual sending of the request.
 *
 * Test strategy:
 * - newInstance() resolves the real implementation via Dfflib_Service_Config__mdt
 * - send() is the HTTP boundary of the application, hence the only place where Test.setMock( HttpCalloutMock.class, ... ) is used;
 *   consuming services mock SRV_Request itself via dfflib.service.defineMock( mocks, SRV_Request.class )
 */
@IsTest( isParallel = true )
private with sharing class SRV_RequestTest{

    private static final String NAMED_CREDENTIAL = 'PostcodeAPI';
    private static final String PATH             = '/rest/addresses/postcode/1012LG/1';
    private static final String SERVICE_NAME     = 'SRV_RequestTest';

    /**
     * HttpCalloutMock capturing the sent request and returning a fixed response
     */
    private class CalloutMock implements HttpCalloutMock{
        private HttpRequest receivedRequest;

        public HttpResponse respond( HttpRequest req ){
            this.receivedRequest = req;
            HttpResponse res = new HttpResponse();
            res.setStatusCode( 200 );
            res.setBody( '{"status":"ok"}' );
            return res;
        }
    }

    // ============================================================================
    // newInstance
    // ============================================================================

    @IsTest
    private static void newInstance_setsEndpointAndServiceName(){
        // When
        SRV_Request service = SRV_Request.newInstance( NAMED_CREDENTIAL, PATH, SERVICE_NAME );

        // Then - named credential endpoint and service name are applied
        System.Assert.isNotNull( service.getRequest(), 'HttpRequest should be initialised' );
        System.Assert.areEqual( 'callout:' + NAMED_CREDENTIAL + PATH, service.getRequest().getEndpoint(), 'Endpoint should use the named credential and path' );
        System.Assert.areEqual( SERVICE_NAME, service.serviceName, 'Service name should be set' );
    }

    @IsTest
    private static void newInstance_returnsNewInstanceEachCall(){
        // When
        SRV_Request first  = SRV_Request.newInstance( NAMED_CREDENTIAL, PATH, SERVICE_NAME );
        SRV_Request second = SRV_Request.newInstance( NAMED_CREDENTIAL, '/other', SERVICE_NAME );

        // Then - each instance has its own request state
        System.Assert.areNotEqual( first.getRequest(), second.getRequest(), 'Instances should not share request state' );
    }

    // ============================================================================
    // Fluent builder methods
    // ============================================================================
    @IsTest
    private static void builderMethods_configureRequest(){
        // Given
        SRV_Request service = SRV_Request.newInstance( NAMED_CREDENTIAL, PATH, SERVICE_NAME );

        // When
        SRV_Request result = service
            .setMethod( App_HTTP.METHOD_POST )
            .setTimeout( 10000 )
            .setHeader( App_HTTP.HEADER_CONTENTTYPE, App_HTTP.HEADER_CONTENTTYPE_JSON )
            .setBody( '{"key":"value"}' );

        // Then - same instance is returned for chaining and the HttpRequest is configured
        HttpRequest req = service.getRequest();
        System.Assert.areEqual( service, result, 'Builder methods should return the same instance' );
        System.Assert.areEqual( App_HTTP.METHOD_POST, req.getMethod(), 'Method should be set' );
        System.Assert.areEqual( App_HTTP.HEADER_CONTENTTYPE_JSON, req.getHeader( App_HTTP.HEADER_CONTENTTYPE ), 'Header should be set' );
        System.Assert.areEqual( '{"key":"value"}', req.getBody(), 'Body should be set' );
    }

    // ============================================================================
    // send
    // ============================================================================

    @IsTest
    private static void send_returnsResponse(){
        // Given
        CalloutMock calloutMock = new CalloutMock();
        Test.setMock( HttpCalloutMock.class, calloutMock );
        SRV_Request service = SRV_Request.newInstance( NAMED_CREDENTIAL, PATH, SERVICE_NAME ).setMethod( App_HTTP.METHOD_GET );

        // When
        Test.startTest();
        HttpResponse res = service.send();
        Test.stopTest();

        // Then - configured request is sent and the response is returned unchanged
        System.Assert.areEqual( 'callout:' + NAMED_CREDENTIAL + PATH, calloutMock.receivedRequest.getEndpoint(), 'Configured endpoint should be sent' );
        System.Assert.areEqual( App_HTTP.METHOD_GET, calloutMock.receivedRequest.getMethod(), 'Configured method should be sent' );
        System.Assert.areEqual( 200, res.getStatusCode(), 'Response status code should be returned' );
        System.Assert.areEqual( '{"status":"ok"}', res.getBody(), 'Response body should be returned' );
    }
}