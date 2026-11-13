/**
 * Outgoing integration service for Dutch postal code address lookup.
 * Demonstrates the D'fflib Service pattern for external HTTP callouts:
 * - newInstance() factory method for metadata-driven implementation resolution,
 *   mockable via dfflib.service.defineMock( mocks, SRVo_PostalCodeValidation.class )
 * - SRV_Request builder for named credential enforcement
 * - Typed response wrapper (AddressResult) matching the postcode.eu API shape
 *
 * Named Credential 'PostcodeAPI' must be configured in Setup -> Named Credentials
 * pointing to https://api.postcode.eu
 */
public with sharing class SRVo_PostalCodeValidation{

    // ============================================================================
    // FACTORY METHOD
    // ============================================================================

    /**
     * Returns the service implementation resolved via the fflib metadata-driven
     * ServiceFactory (Dfflib_Service_Config__mdt custom metadata).
     *
     * @return  SRVo_PostalCodeValidation instance - either real or mocked in test context
     */
    public static SRVo_PostalCodeValidation newInstance(){
        return ( SRVo_PostalCodeValidation ) dfflib.service.newInstance( SRVo_PostalCodeValidation.class );
    }

    // ============================================================================
    // CONSTANTS
    // ============================================================================

    /** Named Credential configured in Setup -> Named Credentials */
    private static final String NAMED_CREDENTIAL = 'PostcodeAPI';

    // ============================================================================
    // SERVICE METHODS
    // ============================================================================

    /**
     * Look up a Dutch address by postal code and house number.
     * Uses the postcode.eu API format:
     * GET /rest/addresses/postcode/{postalCode}/{houseNumber}
     *
     * @param   postalCode      Dutch postal code (e.g. '1234AB') — whitespace is stripped automatically
     * @param   houseNumber     House number as string (e.g. '10')
     * @return  AddressResult with street, city, municipality etc. — null if the combination was not found (404)
     * @throws  dfflib_Utils.InvalidInputValueException  when postalCode or houseNumber is blank
     * @throws  dfflib_Utils.InvalidInputValueException  when the API returns a non-success, non-404 status code
     */
    public AddressResult lookupAddress( String postalCode, String houseNumber ){
        dfflib_Utils.verifyNotBlank( postalCode, 'postalCode' );
        dfflib_Utils.verifyNotBlank( houseNumber, 'houseNumber' );

        String path = '/rest/addresses/postcode/'
            + EncodingUtil.urlEncode( postalCode.replaceAll( '\\s', '' ), 'UTF-8' )
            + '/' + EncodingUtil.urlEncode( houseNumber, 'UTF-8' );

        HttpResponse res = SRV_Request.newInstance( NAMED_CREDENTIAL, path, 'SRVo_PostalCodeValidation' )
            .setMethod( App_HTTP.METHOD_GET )
            .setTimeout( 10000 )
            .setHeader( 'Accept', 'application/json' )
            .send();

        if( App_HTTP.isSuccess( res.getStatusCode() ) ){
            return ( AddressResult ) JSON.deserialize( res.getBody(), AddressResult.class );
        } else if( res.getStatusCode() == App_HTTP.STATUS_CODE_NOT_FOUND ){
            return null; // postal code / house number combination not found
        } else{
            throw new dfflib_Utils.InvalidInputValueException(
                'PostcodeAPI returned ' + res.getStatusCode() + ': ' + res.getBody()
            );
        }
    }

    // ============================================================================
    // INNER CLASSES
    // ============================================================================

    /**
     * Response wrapper matching the postcode.eu API address response payload.
     * Fields are mapped via JSON.deserialize — names must match the API JSON keys exactly.
     */
    public class AddressResult{
        /** Street name (e.g. 'Damrak') */
        public String street;
        /** City name (e.g. 'Amsterdam') */
        public String city;
        /** Municipality name (e.g. 'Amsterdam') */
        public String municipality;
        /** Province name (e.g. 'Noord-Holland') */
        public String province;
        /** Postcode as returned by the API (e.g. '1012LG') */
        public String postcode;
        /** House number as integer */
        public Integer houseNumber;
        /** Optional house number addition (e.g. 'A') */
        public String houseNumberAddition;
        /** Dutch RD coordinate X (Rijksdriehoek) */
        public String rdX;
        /** Dutch RD coordinate Y (Rijksdriehoek) */
        public String rdY;
    }
}