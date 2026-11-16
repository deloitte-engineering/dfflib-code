/**
 * Controller class for Room Reservation UI actions
 *
 * Demonstrates:
 * - @AuraEnabled, both with read-only queries and write methods with proper user-friendly response
 * - Uniform response leveraging Response Service (SRV_Response) for consistency in LWC handling of failures and succeses
 * - User-friendly failure messages; technical details are logged, never shown to the user
 * - Partial-success DML via allOrNone = false and leveraging SaveResults
 * - Direct UoW registerDirty for single-field status update
 */
public with sharing class CTRL_RoomReservations{
    // User-friendly messages returned instead of technical exception details; preferably centralized elsewhere to allow reuse across controllers
    public static final String MSG_DML_ERROR        = 'Something went wrong during the database interaction, contact support if the issue persists.';
    public static final String MSG_PROCESSING_ERROR = 'Something went wrong during the operation, contact support if the issue persists.';

    /**
     * Get available rooms for a date range, can't cache despite read-only query as availability might change in between requests
     * Demonstrates: @AuraEnabled, input validation, direct Selector call from Controller
     *
     * @param   checkIn     Check-in date (inclusive)
     * @param   checkOut    Check-out date (exclusive)
     * @return  SRV_Response.Response with type OK and the available Room__c records as payload,
     *          or INVALID_REQUEST / PROCESSING_ERROR with a user-friendly message
     */
    @AuraEnabled( cacheable = false )
    public static SRV_Response.Response getAvailableRooms( Date checkIn, Date checkOut ){
        try{
            // Input validation
            dfflib_Utils.verifyNotNull( checkIn, 'checkIn date' );
            dfflib_Utils.verifyNotNull( checkOut, 'checkOut date' );
            if( checkOut <= checkIn ){
                throw new dfflib_Utils.InvalidInputValueException( DOM_RoomReservations.MSG_INVALID_DATE_RANGE );
            }

            // Retrieve data for available rooms within specified date range, enforcing full user-configured security
            // Only assigned to local variable for ease of example; normally would directly place Selector within .setPayload method
            List<Room__c> rooms = SEL_Rooms.newInstance( dfflib_Database.Context.FULL )
                .selectAvailableByDateRange( checkIn, checkOut );

            // Convert retrieved Room__c records into the response payload
            return SRV_Response.newInstance()
                .setResponse( SRV_Response.TYPES.OK, null )
                .setPayload( rooms )
                .getResponse();
        } catch( Exception ex ){
            return errorResponse( ex );
        }
    }

    /**
     * Create reservations -- supports partial success via allOrNone = false
     * Demonstrates: @AuraEnabled write, UoW with SRV_Response for structured LWC feedback
     * Returns SRV_Response.Response so LWC can check isSuccess and iterate errors by index
     *
     * @param   reservations    List of RoomReservation__c records to insert
     * @return  SRV_Response.Response with isSuccess, type, message, and optional errors payload
     */
    @AuraEnabled
    public static SRV_Response.Response createReservations( List<RoomReservation__c> reservations ){
        try{
            // Inputs validation - which throws Exceptions with user-friendly message upon failure
            dfflib_Utils.verifyNotEmpty( reservations, 'reservations' );
            DOM_RoomReservations.newInstance( reservations ).validateRecords();

            // Register and commit input via Unit of Work, enabling SaveResults due to allOrNone = false
            dfflib_ISObjectUnitOfWork uow = dfflib.unitOfWork.newInstance( dfflib_Database.Context.FULL );
            uow.registerNewAllOrNone( RoomReservation__c.SObjectType, false );
            uow.registerNew( reservations );
            uow.commitWork();

            // Loop SaveResults to collect any errors for partial success feedback
            List<Database.SaveResult> saveResults = uow.getNewResults( RoomReservation__c.SObjectType );
            Map<Integer, String> errors = new Map<Integer, String>();
            for( Integer i = 0, j = saveResults?.size() ?? 0; i < j; i++ ){
                Database.SaveResult sr = saveResults[ i ];
                if( !sr.isSuccess() ){
                    errors.put( i, sr.getErrors()[ 0 ].getMessage() );
                }
            }

            // Pass success or error message(s) to front-end
            if( errors.isEmpty() ){
                return SRV_Response.newInstance()
                    .setResponse( SRV_Response.TYPES.CREATED, null )
                    .getResponse();
            } else{
                return SRV_Response.newInstance()
                    .setResponse(
                        SRV_Response.TYPES.DML_ERROR,
                        errors.size() + ' of ' + reservations.size() + ' reservations failed'
                    )
                    .setPayload( errors )
                    .getResponse();
            }
        } catch( Exception ex ){
            return errorResponse( ex );
        }
    }

    /**
     * Cancel reservations -- changes status to Cancelled; bulk, all-or-none
     * Demonstrates: @AuraEnabled write, targeted field update via UoW registerDirty with field list
     *
     * @param   reservationIds  Ids of the RoomReservation__c records to cancel - List as Set<Id> isn't allowed for AuraEnabled
     * @return  SRV_Response.Response with type OK, or INVALID_REQUEST / DML_ERROR / PROCESSING_ERROR
     *          with a user-friendly message
     */
    @AuraEnabled
    public static SRV_Response.Response cancelReservations( List<Id> reservationIds ){
        try{
            // Input validations
            dfflib_Utils.verifyNotEmpty( reservationIds, 'reservationIds' );

            // Register reservations to be cancelled, only updating one field;
            // In this setup, allOrNone = true, thus one failure will fail the entire transaction
            // Note, given FULL Context - applying UserMode, no need to validate user-record-access
            dfflib_ISObjectUnitOfWork uow = dfflib.unitOfWork.newInstance( dfflib_Database.Context.FULL );
            for( Integer i = 0, j = reservationIds.size(); i < j; i++ ){
                uow.registerDirty(
                    new RoomReservation__c( Id = reservationIds[ i ], Status__c = DOM_RoomReservations.STATUS_CANCELLED )
                );
            }
            uow.commitWork();

            // Return success response (errors are processed in catch-block)
            return SRV_Response.newInstance()
                .setResponse( SRV_Response.TYPES.OK, null )
                .getResponse();

        } catch( Exception ex ){
            return errorResponse( ex );
        }
    }

    // ============================================================================
    // HELPERS
    // ============================================================================

    /**
     * Maps an exception to a user-friendly SRV_Response
     * Setting response type by Exception and passing Exception message
     *
     * @param   ex  The caught exception
     * @return  SRV_Response.Response describing the failure
     */
    private static SRV_Response.Response errorResponse( Exception ex ){
        SRV_Response.TYPES responseType;
        String message = ex.getMessage();
        if( ex instanceof dfflib_Utils.InvalidInputValueException ){
            responseType = SRV_Response.TYPES.INVALID_REQUEST;
        } else if( ex instanceof DmlException ){
            responseType = SRV_Response.TYPES.DML_ERROR;
            message = MSG_DML_ERROR;
        } else{
            responseType = SRV_Response.TYPES.PROCESSING_ERROR;
            message = MSG_PROCESSING_ERROR;
        }

        // Return standardized failure type and pass exception message to front-end
        // Insert a Log entry to allow tracking and debugging of the error
        return SRV_Response.newInstance()
            .setResponse( responseType, message )
            .getResponse();
    }
}