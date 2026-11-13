/**
 * Flow controller exposing address lookup functionality as an @InvocableMethod.
 * Demonstrates the D'fflib Flow Controller pattern:
 * - Bulk-safe processing of multiple requests in a single transaction
 * - Delegates to SRVo_PostalCodeValidation.newInstance() for mockable callout
 * - Isolates Flow from service layer via Request / Response wrapper classes
 * - Graceful error handling — exceptions are captured in errorMessage rather than surfaced
 */
public with sharing class Flow_AddressLookup{

    // ============================================================================
    // REQUEST / RESPONSE WRAPPERS
    // ============================================================================

    public class Request{
        @InvocableVariable( required = true label = 'Postal Code' description = 'Dutch postal code (e.g. 1234AB)' )
        public String postalCode;

        @InvocableVariable( required = true label = 'House Number' description = 'House number' )
        public String houseNumber;
    }

    public class Response{
        @InvocableVariable( label = 'Street' )
        public String street;

        @InvocableVariable( label = 'City' )
        public String city;

        @InvocableVariable( label = 'Municipality' )
        public String municipality;

        @InvocableVariable( label = 'Province' )
        public String province;

        @InvocableVariable( label = 'Address Found' )
        public Boolean addressFound;

        @InvocableVariable( label = 'Error Message' )
        public String errorMessage;
    }

    // ============================================================================
    // INVOCABLE METHOD
    // ============================================================================

    /**
     * Looks up Dutch address details for one or more postal code / house number combinations.
     * Bulk-safe: processes each request individually to isolate errors per row.
     *
     * @param   requests    List of Request objects provided by the calling Flow
     * @return  List of Response objects in the same order as the input requests
     */
    @InvocableMethod(
        label = 'Look Up Address by Postal Code'
        description = 'Calls the PostcodeAPI to retrieve address details for a Dutch postal code and house number'
        callout = true
    )
    public static List<Response> lookupAddresses( List<Request> requests ){
        List<Response> responses = new List<Response>();

        for( Integer i = 0, j = requests.size(); i < j; i++ ){
            Request req = requests[ i ];
            Response resp = new Response();

            try{
                SRVo_PostalCodeValidation.AddressResult result =
                    SRVo_PostalCodeValidation.newInstance().lookupAddress( req.postalCode, req.houseNumber );

                if( result != null ){
                    resp.street       = result.street;
                    resp.city         = result.city;
                    resp.municipality = result.municipality;
                    resp.province     = result.province;
                    resp.addressFound = true;
                } else{
                    resp.addressFound = false;
                    resp.errorMessage = 'Address not found for postal code: ' + req.postalCode;
                }
            } catch( Exception ex ){
                resp.addressFound = false;
                resp.errorMessage = ex.getMessage();
            }

            responses.add( resp );
        }

        return responses;
    }
}