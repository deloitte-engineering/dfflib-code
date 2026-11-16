/**
 *  Class to store all HTTP Statuses available and created map to allow fetching
 *  E.g. App_HTTP.getStatusCode( App_HTTP.STATUS.I_AM_A_TEAPOT );
 */
public with sharing class App_HTTP{
    public static final String HEADER_ACCEPT            = 'Accept';
    public static final String HEADER_ACCEPT_JSON       = 'application/json';

    public static final String HEADER_AUTHORIZATION     = 'Authorization';

    public static final String HEADER_CONTENTLENGTH     = 'Content-Length';
    public static final String HEADER_CONTENTTYPE       = 'Content-Type';
    public static final String HEADER_CONTENTTYPE_FORM  = 'application/x-www-form-urlencoded';
    public static final String HEADER_CONTENTTYPE_JSON  = 'application/json';
    public static final String HEADER_CONTENTTYPE_XML   = 'text/xml';

    public static final String METHOD_POST              = 'POST';
    public static final String METHOD_GET               = 'GET';
    public static final String METHOD_PUT               = 'PUT';
    public static final String METHOD_DELETE            = 'DELETE';
    public static final String METHOD_PATCH             = 'PATCH';

    /** Legacy integer alias — kept for backward compatibility with SRVo_PostalCodeValidation */
    public static final Integer STATUS_CODE_NOT_FOUND   = 404;

    /**
     * @return  HTTP Status code based on a Status description
     */
    public static Integer getStatusCode( STATUS status ){
        return STATUS_CODE.get( status );
    }

    /**
     * Determines whether an HTTP status code indicates a successful response.
     * Considers any 2xx status code as a success.
     *
     * @param   statusCode  The HTTP status code to evaluate
     * @return  True when status code is in the 200-299 range, false otherwise
     */
    public static Boolean isSuccess( Integer statusCode ){
        return statusCode >= 200 && statusCode < 300;
    }

    /**
     *  Mapping of available Statuses to HTTP Status Code (restricted to RestResponse values)
     *  https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_methods_system_restresponse.htm
     */
    private static final Map<STATUS, Integer> STATUS_CODE = new Map<STATUS, Integer>{
        STATUS.OK                               => 200,
        STATUS.CREATED                          => 201,
        STATUS.ACCEPTED                         => 202,
        STATUS.NO_CONTENT                       => 204,
        STATUS.PARTIAL_CONTENT                  => 206,
        STATUS.AMBIGUOUS                        => 300,
        STATUS.MOVED_PERMANENTLY                => 301,
        STATUS.FOUND                            => 302,
        STATUS.NOT_MODIFIED                     => 304,
        STATUS.BAD_REQUEST                      => 400,
        STATUS.UNAUTHORIZED                     => 401,
        STATUS.FORBIDDEN                        => 403,
        STATUS.NOT_FOUND                        => 404,
        STATUS.METHOD_NOT_ALLOWED               => 405,
        STATUS.NOT_ACCEPTABLE                   => 406,
        STATUS.CONFLICT                         => 409,
        STATUS.GONE                             => 410,
        STATUS.PRECONDITION_FAILED              => 412,
        STATUS.PAYLOAD_TOO_LARGE                => 413,
        STATUS.URI_TOO_LONG                     => 414,
        STATUS.UNSUPPORTED_MEDIA_TYPE           => 415,
        STATUS.EXPECTATION_FAILED               => 417,
        STATUS.I_AM_A_TEAPOT                    => 418,
        STATUS.INTERNAL_SERVER_ERROR            => 500,
        STATUS.SERVICE_UNAVAILABLE              => 503
    };

    // List of available HTTP Status descriptions — provided in ENUM to allow referencing in code more easily
    public enum STATUS{
        OK,
        CREATED,
        ACCEPTED,
        NO_CONTENT,
        PARTIAL_CONTENT,
        AMBIGUOUS,
        MOVED_PERMANENTLY,
        FOUND,
        NOT_MODIFIED,
        BAD_REQUEST,
        UNAUTHORIZED,
        FORBIDDEN,
        NOT_FOUND,
        METHOD_NOT_ALLOWED,
        NOT_ACCEPTABLE,
        CONFLICT,
        GONE,
        PRECONDITION_FAILED,
        PAYLOAD_TOO_LARGE,
        URI_TOO_LONG,
        UNSUPPORTED_MEDIA_TYPE,
        EXPECTATION_FAILED,
        I_AM_A_TEAPOT,
        INTERNAL_SERVER_ERROR,
        SERVICE_UNAVAILABLE
    }
}