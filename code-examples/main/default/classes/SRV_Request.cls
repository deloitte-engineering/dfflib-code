/**
 * HTTP request wrapper service to:
 * - Standardise outgoing integrations, enforcing e.g. named credentials for all callouts
 * - Simplify usage and avoid duplicate code for setting up HTTP requests
 * - Allowing to mock HTTP requests in unit tests
 * - Fluent builder for ease of configuration and method chaining
 */
public with sharing class SRV_Request{

    @TestVisible private HttpRequest request;
    @TestVisible private String serviceName; // for logging

    /**
     * Construction of service via Dfflib_Service_Config__mdt metadata
     * Mandatory input for named credential endpoint, path and caller service name for logging.
     *
     * @param   namedCredential     The name of the Salesforce Named Credential (e.g. 'PostcodeAPI')
     * @param   path                The resource path to append to the named credential base URL (e.g. '/rest/addresses/postcode/1234AB/10')
     * @param   serviceName         Caller service name used for logging and diagnostics (e.g. 'SRVo_PostalCodeValidation')
     * @return  SRV_Request instance - either real or mocked in test context
     * @throws  dfflib_Utils.InvalidInputValueException  when any of the parameters is blank
     */
    public static SRV_Request newInstance( String namedCredential, String path, String serviceName ){
        dfflib_Utils.verifyNotBlank( namedCredential, 'namedCredential' );
        dfflib_Utils.verifyNotBlank( path, 'path' );
        dfflib_Utils.verifyNotBlank( serviceName, 'serviceName' );

        SRV_Request service = ( SRV_Request ) dfflib.service.newInstance( SRV_Request.class );
        service.request = new HttpRequest();
        service.request.setEndpoint( 'callout:' + namedCredential + path );
        service.serviceName = serviceName;
        return service;
    }

    // ============================================================================
    // FLUENT BUILDER METHODS
    // ============================================================================

    /**
     * Sets the HTTP method (GET, POST, PUT, DELETE, PATCH).
     * Use App_HTTP.METHOD_* constants.
     *
     * @param   method  HTTP method string
     * @return  This SRV_Request instance for method chaining
     */
    public SRV_Request setMethod( String method ){
        this.request.setMethod( method );
        return this;
    }

    /**
     * Sets the request timeout in milliseconds.
     *
     * @param   timeoutMs   Timeout in milliseconds (max 120000)
     * @return  This SRV_Request instance for method chaining
     */
    public SRV_Request setTimeout( Integer timeoutMs ){
        this.request.setTimeout( timeoutMs );
        return this;
    }

    /**
     * Adds or overwrites a single request header.
     *
     * @param   key     Header name (e.g. 'Content-Type')
     * @param   value   Header value (e.g. 'application/json')
     * @return  This SRV_Request instance for method chaining
     */
    public SRV_Request setHeader( String key, String value ){
        this.request.setHeader( key, value );
        return this;
    }

    /**
     * Sets the request body (for POST / PUT / PATCH calls).
     *
     * @param   body    Request body string (typically serialised JSON)
     * @return  This SRV_Request instance for method chaining
     */
    public SRV_Request setBody( String body ){
        this.request.setBody( body );
        return this;
    }

    // ============================================================================
    // ACCESSORS
    // ============================================================================

    /**
     * Returns the underlying HttpRequest - useful for assertions in tests.
     *
     * @return  The configured HttpRequest instance
     */
    public HttpRequest getRequest(){
        return this.request;
    }

    // ============================================================================
    // EXECUTION
    // ============================================================================

    /**
     * Sends the configured request and returns the raw HttpResponse.
     * Caller is responsible for interpreting the status code.
     *
     * @return  HttpResponse from the remote endpoint
     */
    public HttpResponse send(){
        return new Http().send( this.request );
    }
}