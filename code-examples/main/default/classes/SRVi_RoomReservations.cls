/**
 * Incoming REST API to book rooms for one or more guests in a single (bulk) request
 *
 * Endpoint:    POST /services/apexrest/reservations/create
 * Request:     { "bookings": [
 *                  {
 *                      "guest":       { "firstName": "Jane", "lastName": "Doe", "email": "jane.doe@example.com", "phone": "+31612345678" },
 *                      "reservation": { "roomId": "a01...", "checkInDate": "2026-12-01", "checkOutDate": "2026-12-04", "numberOfGuests": 2, "specialRequests": "Late check-in" }
 *                  }
 *              ] }
 * Response:    201 { "type": "CREATED", "message": "...", "payload": { "reservations": [ { "reservationId": "a02...", "contactId": "003..." } ] } }
 *              Reservations in the same order as the bookings in the request
 *              400 INVALID_FORMAT / INVALID_REQUEST / DML_ERROR, 500 PROCESSING_ERROR
 *
 * Demonstrates:
 * - Bulk match-or-create: all guests matched on Email in one query, otherwise a new Contact is created
 * - Multiple bookings for the same (new) guest share one Contact
 * - One Unit of Work registering all records, committed once (all-or-none across all Contacts and RoomReservation__c records)
 * - Registration of relations to link a reservation to a Contact which has no Id yet (for clean code)
 * - Reset of registered work in finally, so the Unit of Work can be reused after a failure before commitWork()
 * - Strict JSON deserialization into inner wrapper classes, each with their own validation and conversion
 * - Uniform REST response via SRV_Response, without exposing technical details
 */
@RestResource( UrlMapping = '/reservations/create' )
global with sharing class SRVi_RoomReservations{
    // User-friendly messages returned instead of technical exception details
    @TestVisible private static final String MSG_CREATED            = 'The reservation was successfully created';
    @TestVisible private static final String MSG_DML_ERROR          = 'Something went wrong during the database interaction, contact support if the issue persists.';
    @TestVisible private static final String MSG_INVALID_FORMAT     = 'The request body is not valid JSON or contains unknown attributes';
    @TestVisible private static final String MSG_PROCESSING_ERROR   = 'Something went wrong during the operation, contact support if the issue persists.';

    /**
     * Receives the JSON body, registers all work in one Unit of Work and returns a uniform REST response
     */
    @HttpPost
    global static void handleRequest(){
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        // Deserialize strictly, so unknown attributes are rejected instead of silently ignored
        Wrapper_Request payload;
        try{
            payload = ( Wrapper_Request ) JSON.deserializeStrict( req?.requestBody?.toString(), Wrapper_Request.class );
            dfflib_Utils.verifyNotNull( payload, 'body' );
        } catch( Exception ex ){
            setResponse( res, SRV_Response.TYPES.INVALID_FORMAT, MSG_INVALID_FORMAT );
            return;
        }

        // Initiate Unit of Work in system mode, bypassing sharing, as integration user
        dfflib_ISObjectUnitOfWork uow = dfflib.unitOfWork.newInstance( dfflib_Database.Context.NONE );
        try{
            // Validate payload for required fields
            payload.validate();
            List<Wrapper_Booking> bookings = payload.bookings;

            // Query contacts based on email
            Map<String, Contact> contactsByEmail = matchGuests( bookings );

            // Process each booking and populate output variable
            List<RoomReservation__c> reservations = new List<RoomReservation__c>();            
            for( Integer i = 0, j = bookings.size(); i < j; i++ ){
                Wrapper_Booking booking = bookings[ i ];
                
                // Validate whether Contact exists for guest email, or create new one
                String key = booking?.guest?.email?.toLowerCase();
                Contact c = contactsByEmail.get( key );
                if( c == null ){
                    c = booking.guest.convertToContact();
                    // Registered in the map, so multiple reservations of the same new guest share one Contact
                    contactsByEmail.put( key, c );
                    uow.registerNew( c );
                }

                // Create reservation and register for insertion
                // Register relationship between reservation and Contact, regardless of Contact.Id already known, or pending insertion
                RoomReservation__c reservation = booking.reservation.convertToReservation();
                uow.registerNew( reservation, RoomReservation__c.Contact__c, c );
                
                reservations.add( reservation );
            }

            // Commit work to insert Contacts, resolve relations on RoomReservation__c and insert the reservations
            uow.commitWork();

            // Ids are available on the registered records after commitWork()
            SRV_Response.newInstance( res )
                .setResponse( SRV_Response.TYPES.CREATED, MSG_CREATED )
                .setPayload( toResponsePayload( reservations ), 'reservations' );
        } catch( dfflib_Utils.InvalidInputValueException ex ){
            setResponse( res, SRV_Response.TYPES.INVALID_REQUEST, ex.getMessage() );
        } catch( DmlException ex ){
            setResponse( res, SRV_Response.TYPES.DML_ERROR, MSG_DML_ERROR );
        } catch( Exception ex ){
            setResponse( res, SRV_Response.TYPES.PROCESSING_ERROR, MSG_PROCESSING_ERROR );
        } finally{
            // Optionally, log the request for auditing purposes basd on the set Response
            // Allowing reuse of the same Unit of Work to e.g. publish a Platform Event
            // Reset explicitly to ensure when an Exception is thrown before commitWork(), the previous registered work is reset as well
            uow.resetWork();
        }
    }

    /**
     * Matches all guests to existing Contacts on Email in one query
     *
     * @param   bookings    The validated bookings from the request
     * @return  Matched Contacts keyed by lowercase Email (SOQL matches Email case-insensitively); guests without a match are absent
     */
    @TestVisible
    private static Map<String, Contact> matchGuests( List<Wrapper_Booking> bookings ){
        Set<String> emails = new Set<String>();
        for( Integer i = 0, j = bookings.size(); i < j; i++ ){
            emails.add( bookings[ i ]?.guest?.email?.toLowerCase() );
        }

        Map<String, Contact> contactsByEmail = new Map<String, Contact>();
        List<Contact> matches = SEL_Contacts.newInstance( dfflib_Database.Context.NONE ).selectByEmails( emails );
        for( Integer i = 0, j = matches.size(); i < j; i++ ){
            Contact c = matches[ i ];
            // Normally a duplicate check is added here (multiple Contacts sharing an Email), left out for sake of simplicity
            contactsByEmail.put( c?.Email?.toLowerCase(), c );
        }
        return contactsByEmail;
    }

    /**
     * Builds the response payload per reservation, in the same order as the bookings in the request
     */
    private static List<Map<String, Object>> toResponsePayload( List<RoomReservation__c> reservations ){
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        for( Integer i = 0, j = reservations.size(); i < j; i++ ){
            RoomReservation__c res = reservations[ i ];
            result.add( new Map<String, Object>{
                'reservationId' => res?.Id,
                'contactId'     => res?.Contact__c
            } );
        }
        return result;
    }

    /**
     * Sets a failure response on the RestResponse
     */
    private static void setResponse( RestResponse res, SRV_Response.TYPES responseType, String message ){
        SRV_Response.newInstance( res ).setResponse( responseType, message );
    }

    // ============================================================================
    // REQUEST WRAPPERS
    // ============================================================================

    /**
     * Root of the request body
     */
    public class Wrapper_Request{
        public List<Wrapper_Booking> bookings;

        /**
         * @throws  dfflib_Utils.InvalidInputValueException when no bookings are provided, or on the first missing required attribute
         */
        public void validate(){
            dfflib_Utils.verifyNotEmpty( this.bookings, 'bookings' );
            for( Integer i = 0, j = this.bookings.size(); i < j; i++ ){
                Wrapper_Booking booking = this.bookings[ i ];
                dfflib_Utils.verifyNotNull( booking, 'booking' );
                booking.validate();
            }
        }
    }

    /**
     * Single booking: a guest with the reservation to create
     */
    public class Wrapper_Booking{
        public Wrapper_Guest guest;
        public Wrapper_Reservation reservation;

        /**
         * @throws  dfflib_Utils.InvalidInputValueException on the first missing required attribute
         */
        public void validate(){
            dfflib_Utils.verifyNotNull( this.guest, 'guest' );
            dfflib_Utils.verifyNotNull( this.reservation, 'reservation' );
            this.guest.validate();
            this.reservation.validate();
        }
    }

    /**
     * Guest details, converted to a Contact
     */
    public class Wrapper_Guest{
        public String firstName;
        public String lastName;
        public String email;
        public String phone;

        public void validate(){
            dfflib_Utils.verifyNotBlank( this.lastName, 'guest.lastName' );
            dfflib_Utils.verifyNotBlank( this.email, 'guest.email' );
        }

        public Contact convertToContact(){
            return new Contact(
                FirstName   = this.firstName,
                LastName    = this.lastName,
                Email       = this.email,
                Phone       = this.phone
            );
        }
    }

    /**
     * Reservation details, converted to a RoomReservation__c; dates in ISO-8601 format (YYYY-MM-DD)
     */
    public class Wrapper_Reservation{
        public Id roomId;
        public Date checkInDate;
        public Date checkOutDate;
        public Integer numberOfGuests;
        public String specialRequests;

        public void validate(){
            dfflib_Utils.verifyNotNull( this.roomId, 'reservation.roomId' );
            dfflib_Utils.verifyNotNull( this.checkInDate, 'reservation.checkInDate' );
            dfflib_Utils.verifyNotNull( this.checkOutDate, 'reservation.checkOutDate' );
        }

        public RoomReservation__c convertToReservation(){
            return new RoomReservation__c(
                Room__c             = this.roomId,
                CheckInDate__c      = this.checkInDate,
                CheckOutDate__c     = this.checkOutDate,
                NumberOfGuests__c   = this.numberOfGuests,
                SpecialRequests__c  = this.specialRequests,
                Status__c           = DOM_RoomReservations.STATUS_SUBMITTED
            );
        }
    }

    /**
     * Code snippet for how such integration would look without Unit of Work
     */
    /**
    private static void noFFLIB(){
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        // Deserialize strictly, so unknown attributes are rejected instead of silently ignored
        Wrapper_Request payload;
        try{
            payload = ( Wrapper_Request ) JSON.deserializeStrict( req?.requestBody?.toString(), Wrapper_Request.class );
            dfflib_Utils.verifyNotNull( payload, 'body' );
        } catch( Exception ex ){
            setResponse( res, SRV_Response.TYPES.INVALID_FORMAT, MSG_INVALID_FORMAT );
            return;
        }

        try{
            // Validate payload for required fields
            payload.validate();
            List<Wrapper_Booking> bookings = payload.bookings;

            // One Contact per guest email: existing matches up front, new Contacts are added below
            Map<String, Contact> contactsByEmail = matchGuests( bookings );

            List<Contact> contactsToInsert = new List<Contact>();
            List<RoomReservation__c> reservationsToInsert = new List<RoomReservation__c>();
            // Contact instance per reservation, aligned by index; a new Contact has no Id yet, but receives it on insert,
            // so the lookup is resolved from the same instance afterwards
            List<Contact> contactPerReservation = new List<Contact>();
            for( Integer i = 0, j = bookings.size(); i < j; i++ ){
                Wrapper_Booking booking = bookings[ i ];
                String key = booking?.guest?.email?.toLowerCase();
                Contact c = contactsByEmail.get( key );
                if( c == null ){
                    c = booking.guest.convertToContact();
                    // Registered in the map, so multiple reservations of the same new guest share one Contact
                    contactsByEmail.put( key, c );
                    contactsToInsert.add( c );
                }
                contactPerReservation.add( c );
                reservationsToInsert.add( booking.reservation.convertToReservation() );
            }

            // Manage the transaction manually, so a failing reservation insert does not leave orphan Contacts
            Savepoint sp = Database.setSavepoint();
            try{
                // Insert the Contacts first, as their Ids are required for the reservation lookup
                Database.insert( contactsToInsert, true, AccessLevel.SYSTEM_MODE );

                // Resolve the lookup from the aligned Contact instance, now holding an Id for both existing and new guests
                for( Integer i = 0, j = reservationsToInsert.size(); i < j; i++ ){
                    reservationsToInsert[ i ].Contact__c = contactPerReservation[ i ]?.Id;
                }
                Database.insert( reservationsToInsert, true, AccessLevel.SYSTEM_MODE );
            } catch( Exception ex ){
                if( sp != null ){
                    Database.rollback( sp );
                }
                // Rethrow, so the original exception type is mapped to a response below
                throw ex;
            }

            SRV_Response.newInstance( res )
                .setResponse( SRV_Response.TYPES.CREATED, MSG_CREATED )
                .setPayload( toResponsePayload( reservationsToInsert ), 'reservations' );
        } catch( dfflib_Utils.InvalidInputValueException ex ){
            setResponse( res, SRV_Response.TYPES.INVALID_REQUEST, ex.getMessage() );
        } catch( DmlException ex ){
            setResponse( res, SRV_Response.TYPES.DML_ERROR, MSG_DML_ERROR );
        } catch( Exception ex ){
            setResponse( res, SRV_Response.TYPES.PROCESSING_ERROR, MSG_PROCESSING_ERROR );
        }
    }
     */
}
