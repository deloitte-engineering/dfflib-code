/**
 *  Service class to centralise the way of setting and sending Responses for REST and LWC
 *  SOAP is only used for outbound interfaces and thus has no custom Responses
 *
 *  Each Response contains:
 *  - Type:     the 'API readable'/'category' response to allow receiving party to distribute
 *  - Message:  the 'human readable' response for further debugging in case of issues
 *  - Payload:  the (optional) content to share; for REST always a Map for API usage
 *
 *  Examples of usage:
 *  === LWC RESPONSE: Return a found Account
 *  Account a = new Account( name = 'test' );
 *  return SRV_Response.newInstance().setResponse( SRV_Response.TYPES.OK, null ).setPayload( a ).getResponse();
 *
 *  === REST RESPONSE: Set the statusCode and returnBody
 *  RestResponse resp = RestContext.response;
 *  Map<String, Object> restReturn = new Map<String, Object>{ 'accountObject' => a };
 *  SRV_Response.newInstance( resp ).setResponse( SRV_Response.TYPES.OK, 'MATCH' ).setPayload( restReturn );
 */
public with sharing class SRV_Response{
    // Service variables
    private Response response;    // Response (body) to be sent to caller
    private RestResponse res;     // RestResponse to alter and send to caller; also used to identify REST Response

    // Response Types used in API communication to allow system to orchestrate by 'category'
    public enum TYPES{
        CREATED, OK, NO_CONTENT,                                    // success types
        INVALID_FORMAT, INVALID_REQUEST,                            // Input issues
        DML_ERROR, DUPLICATE_MATCH, NO_MATCH, PROCESSING_ERROR      // Processing issues
    }

    // Mapping from TYPE (Response category) to a matching HTTP StatusCode
    // Non-static to avoid instantiation for non-REST Responses
    private final Map<TYPES, Integer> TYPE_TO_HTTP_STATUS = new Map<TYPES, Integer>{
        TYPES.CREATED           => App_HTTP.getStatusCode( App_HTTP.STATUS.CREATED ),
        TYPES.DML_ERROR         => App_HTTP.getStatusCode( App_HTTP.STATUS.BAD_REQUEST ),
        TYPES.DUPLICATE_MATCH   => App_HTTP.getStatusCode( App_HTTP.STATUS.AMBIGUOUS ),
        TYPES.INVALID_FORMAT    => App_HTTP.getStatusCode( App_HTTP.STATUS.BAD_REQUEST ),
        TYPES.INVALID_REQUEST   => App_HTTP.getStatusCode( App_HTTP.STATUS.BAD_REQUEST ),
        TYPES.NO_CONTENT        => App_HTTP.getStatusCode( App_HTTP.STATUS.NO_CONTENT ),
        TYPES.NO_MATCH          => App_HTTP.getStatusCode( App_HTTP.STATUS.PRECONDITION_FAILED ),
        TYPES.OK                => App_HTTP.getStatusCode( App_HTTP.STATUS.OK ),
        TYPES.PROCESSING_ERROR  => App_HTTP.getStatusCode( App_HTTP.STATUS.INTERNAL_SERVER_ERROR )
    };

    /**
     * Constructor for constructing LWC responses
     */
    public static SRV_Response newInstance(){
        SRV_Response service = ( SRV_Response ) dfflib.service.newInstance( SRV_Response.class );
        service.response = new LWC_Response();
        return service;
    }

    /**
     * Constructor for constructing REST responses
     */
    public static SRV_Response newInstance( RestResponse res ){
        SRV_Response service = ( SRV_Response ) dfflib.service.newInstance( SRV_Response.class );
        service.res = res;
        service.res.headers.put( App_HTTP.HEADER_CONTENTTYPE, App_HTTP.HEADER_CONTENTTYPE_JSON );
        service.response = new REST_Response();
        return service;
    }

    /**
     * Method to populate an HTTP Header Attribute like 'Content-Type', 'Accept', or 'Authorization' (see App_HTTP class statics)
     */
    public SRV_Response setHeader( String attribute, String value ){
        if( this.res == null ){
            throw new dfflib_Utils.InvalidImplementationException( 'LWC Responses do not have Headers' );
        }
        this.res.headers.put( attribute, value );
        return this;
    }

    /**
     * Method to populate the Response with the Type and Message
     * For a REST Response, also the statusCode and responseBody are set
     *
     * NOTE! JSON.serialize() might break, try catch is expected in calling class
     */
    public SRV_Response setResponse( TYPES responseType, String message ){
        response.setType( responseType ).setMessage( message );
        // Set RestResponse in case one provided
        if( this.res != null ){
            this.res.statusCode = TYPE_TO_HTTP_STATUS.get( responseType );
            this.res.responseBody = Blob.valueOf( JSON.serialize( response ) );
        }
        return this;
    }

    /**
     * Method to populate the Response Payload, the data which is returned
     * - REST: Always sets as Map<String, Object> to allow receiver to fetch by: response.payload.[key]; key is required
     * - LWC: Custom to implementation (e.g. Object, List, Map, or Custom Wrapper); key is not allowed
     *          Calling class is responsible to define full payload
     */
    public SRV_Response setPayload( Object payload ){ return this.setPayload( payload, null ); }
    public SRV_Response setPayload( Object payload, String key ){
        response.setPayload( payload, key );
        // Update responseBody on payload change
        if( this.res != null ){
            this.res.responseBody = Blob.valueOf( JSON.serialize( response ) );
        }
        return this;
    }

    public Response getResponse(){
        return this.response;
    }

    /**
     * Response Wrapper classes
     * - Response should be public since System.Test.createStub will else fail since class is not visible
     * - Set Constructor to private to prevent external instances to be created without usage of SRV_Response methods
     */
    public virtual class Response{
        @AuraEnabled public TYPES type;     // Type/Code Category of response; e.g. 'ok', 'dml_error'
        @AuraEnabled public String message; // Descriptive 'custom' message for specific instance
        @AuraEnabled public Object payload; // The retrieved or modified data to be sent back to caller

        @TestVisible private Response(){}

        public virtual Response setType( TYPES type ){
            this.type = type;
            return this;
        }

        public Response setMessage( String message ){
            this.message = message;
            return this;
        }
        // Key is not used in standard implementation (see REST_Response class)
        public virtual Response setPayload( Object payload, String key ){
            this.payload = payload;
            return this;
        }
    }

    /**
     * Response Wrapper class for REST specific responses
     * Payload automatically set to Map to enforce same payload distribution across REST APIs
     */
    public class REST_Response extends Response{
        // Private Constructor to prevent distinct initiation outside SRV_Response class
        private REST_Response(){
            super();
            this.payload = new Map<String, Object>();
        }

        public override Response setPayload( Object payload, String key ){
            if( String.isBlank( key ) ){
                throw new dfflib_Utils.InvalidImplementationException( 'REST Response Payload should ALWAYS be set with a key' );
            }
            ( ( Map<String, Object> ) this.payload ).put( key, payload );
            return this;
        }
    }

    /**
     * Response Wrapper class for Lightning (Web) Component server-side responses
     * Automatically populates the 'isSuccess' value by the specified code
     */
    public class LWC_Response extends Response{
        @AuraEnabled public Boolean isSuccess;
        // Private Constructor to prevent distinct initiation outside SRV_Response class
        private LWC_Response(){ super(); }

        public override Response setType( TYPES type ){
            this.type = type;
            this.isSuccess = type != null && ( type.equals( TYPES.OK ) || type.equals( TYPES.CREATED ) );
            return this;
        }

        public override Response setPayload( Object payload, String key ){
            if( String.isNotBlank( key ) ){
                throw new dfflib_Utils.InvalidImplementationException( 'LWC Response Payload should NEVER contain a key' );
            }
            this.payload = payload;
            return this;
        }
    }
}