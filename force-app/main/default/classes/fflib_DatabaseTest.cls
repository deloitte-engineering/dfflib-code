/**
 * Copyright (c), Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
/**
 * Unit test class for fflib_Database class
 * 
 * @author      Rafael Fernandes dos Santos (rfernandesdossantos@deloitte.nl)
 * @created     March 2023
 */
@IsTest
private with sharing class fflib_DatabaseTest{
    private static final String testUsername = 'unittest_externaluser@fflib_deloitte.nl.test';
    private static final String sampleSolutionName = 'SolutionName';

    private static final Integer SAMPLE_SIZE_SOLUTION = 3, SAMPLE_SIZE_CONTACT_REQUEST = 1;
    // Boolean describing the org's internal sharing model for the SObject 'Solution'. As certain unit tests rely on visibility of mock data, this allows assertions to infer results based on whether the running user has been given visibility over records by OWD
    private static final Boolean isPrivateSolutionInternalSharing{
        get{
            if( isPrivateSolutionInternalSharing == null ){
                isPrivateSolutionInternalSharing = ( [ SELECT InternalSharingModel FROM EntityDefinition WHERE DeveloperName = :String.valueOf( Solution.SObjectType ) ].InternalSharingModel == 'Private' );
            }
            return isPrivateSolutionInternalSharing;
        }
        set;
    }

    private static final List<Solution> sampleSolutionList{
        get{
            if( sampleSolutionList == null ){
                sampleSolutionList = [ SELECT Id, SolutionName, IsPublished FROM Solution ORDER BY CreatedDate DESC LIMIT :SAMPLE_SIZE_SOLUTION ];
            }
            return sampleSolutionList;
        }
        set;
    }
    private static final List<ContactRequest> sampleContactRequestList{
        get{
            if( sampleContactRequestList == null ){
                sampleContactRequestList = [ SELECT Id FROM ContactRequest ORDER BY Name DESC LIMIT :SAMPLE_SIZE_CONTACT_REQUEST ];
            }
            return sampleContactRequestList;
        }
        set;
    }
    private static final User testUser{
        get{
            if( testUser == null ){
                testUser = [ SELECT Id FROM User WHERE Username = :testUsername ];
            }
            return testUser;
        }
        set;
    }

    @TestSetup
    private static void testSetup(){
        // Create a Permission Set that grants 'Read' access to Solution
        PermissionSet ps = new PermissionSet( Label = 'Read Only Permission Set', Name = 'ReadOnlyPermissionSet' );
        insert ps;

        // Grant 'Read' access to the Solution SObject
        List<ObjectPermissions> objectPerms = new List<ObjectPermissions>();
        objectPerms.add( createObjectPermissions( ps.Id, 'Solution', false, true, false, false ) );
        insert objectPerms;

        // By default user has Read/Edit access to required fields like Solution.SolutionName & Status field
        // On purpose no access is granted to Solution.IsPublished. This will be validated in unit tests where FLS is validated

        // runAs() can be used to perform DML operations and bypass the mixed DML error otherwise returned by bundled setup/non-setup objects in same transaction
        System.runAs( new User( Id = UserInfo.getUserId() ) ){
            insert ( List<Solution> ) setupSolutionSampleData( SAMPLE_SIZE_SOLUTION );

            insert ( List<ContactRequest> ) setupContactRequestSampleData( SAMPLE_SIZE_CONTACT_REQUEST );

            User minimumAccessUser = setupTestUser( 'Minimum Access - Salesforce' );
            insert minimumAccessUser;
            assignPermissionSet( 'ReadOnlyPermissionSet', minimumAccessUser );
        }
    }

    private static Profile getProfile( String profileName ){
        return [ SELECT Id, Name FROM Profile WHERE Name = :profileName ];
    }

    private static ObjectPermissions createObjectPermissions( Id permSetId, String objectType, Boolean canCreate, Boolean canRead, Boolean canUpdate, Boolean canDelete ){
        return new ObjectPermissions(
            ParentId = permSetId,
            SobjectType = objectType,
            PermissionsCreate = canCreate,
            PermissionsRead = canRead,
            PermissionsEdit = canUpdate,
            PermissionsDelete = canDelete
        );
    }

    private static User setupTestUser( String profileName ){
        Profile testProfile = getProfile( profileName );
        return new User(
            Alias = 'test1',
            Email = 'testuser1@testorg.com',
            EmailEncodingKey = 'UTF-8',
            FirstName = 'FirstName',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = testProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = testUsername );
    }

    private static List<Solution> setupSolutionSampleData( Integer numberOfSamples ){
        List<Solution> sampleDataList = new List<Solution>();
        // Retrieve sample data for Solution SObject.
        // If a project has any custom required fields, or validation rules, a custom sample record can be provided in FFLIB_Config__mdt
        List<FFLIB_Config__mdt> mockDataConfig = FFLIB_Config__mdt.getAll().values();
        Solution sampleObject = ( mockDataConfig.isEmpty() || String.isBlank( mockDataConfig[ 0 ]?.Test_Solution_Sample_Record_Data__c ) )
            ? new Solution( SolutionName = sampleSolutionName, IsPublished = false )
            : ( Solution ) JSON.deserialize( mockDataConfig[ 0 ].Test_Solution_Sample_Record_Data__c, Solution.class );

        for( Integer i = 0; i < numberOfSamples; i++ ){
            sampleDataList.add( sampleObject.clone( false, true ) );
        }

        return sampleDataList;
    }

    private static List<ContactRequest> setupContactRequestSampleData( Integer numberOfSamples ){
        List<ContactRequest> sampleDataList = new List<ContactRequest>();
        // Retrieve sample data for ContactRequest SObject. Any specific project required fields should be added to the sample custom metadata record
        List<FFLIB_Config__mdt> mockDataConfig = FFLIB_Config__mdt.getAll().values();
        ContactRequest sampleObject = ( mockDataConfig.isEmpty() || String.isBlank( mockDataConfig[ 0 ]?.Test_Contact_Request_Sample_Record_Data__c ) )
            ? new ContactRequest()
            : ( ContactRequest ) JSON.deserialize( mockDataConfig[ 0 ].Test_Contact_Request_Sample_Record_Data__c, ContactRequest.class );

        for( Integer i = 0; i < numberOfSamples; i++ ){
            sampleDataList.add( sampleObject.clone( false, true ) );
        }

        return sampleDataList;
    }

    private static User assignPermissionSet( String permissionSetName, User usr ){
        PermissionSet ps = [ SELECT Id FROM PermissionSet WHERE Name = :permissionSetName ];
        PermissionSetAssignment psa = new PermissionSetAssignment( AssigneeId = usr.Id, PermissionSetId = ps.Id );
        insert psa;
        return usr;
    }

    @IsTest
    private static void getAccessLevel(){
        // Assert AccessLevel enum for FULL Database.Context instance
        System.Assert.areEqual( AccessLevel.USER_MODE, fflib_Database.getAccessLevel( fflib_Database.Context.FULL ), 'Expected AccessLevel.USER_MODE to be mapped to this Context.' );

        // Assert AccessLevel enum for SHARING_SKIP_PERMISSIONS Database.Context instance
        System.Assert.areEqual( AccessLevel.SYSTEM_MODE, fflib_Database.getAccessLevel( fflib_Database.Context.SHARING_SKIP_PERMISSIONS ), 'Expected AccessLevel.SYSTEM_MODE to be mapped to this Context.' );

        // Assert AccessLevel enum for INHERIT Database.Context instance
        System.Assert.areEqual( AccessLevel.SYSTEM_MODE, fflib_Database.getAccessLevel( fflib_Database.Context.INHERIT ), 'Expected AccessLevel.SYSTEM_MODE to be mapped to this Context.' );

        // Assert AccessLevel enum for NONE Database.Context instance
        System.Assert.areEqual( AccessLevel.SYSTEM_MODE, fflib_Database.getAccessLevel( fflib_Database.Context.NONE ), 'Expected AccessLevel.SYSTEM_MODE to be mapped to this Context.' );
    }

    @IsTest
    private static void getDMLProxy(){
        // Assert DMLProxy instance of type WithSimpleDML
        System.Assert.isInstanceOfType( fflib_Database.getDMLProxy( fflib_Database.Context.FULL ), fflib_Database_DMLProxy.WithSimpleDML.class, 'Expected fflib_Database_DMLProxy.WithSimpleDML instance.' );

        // Assert DMLProxy instance of type WithSimpleDML
        System.Assert.isInstanceOfType( fflib_Database.getDMLProxy( fflib_Database.Context.SHARING_SKIP_PERMISSIONS ), fflib_Database_DMLProxy.WithSimpleDML.class, 'Expected fflib_Database_DMLProxy.WithSimpleDML instance.' );

        // Assert DMLProxy instance of type WithoutSimpleDML
        System.Assert.isInstanceOfType( fflib_Database.getDMLProxy( fflib_Database.Context.NONE ), fflib_Database_DMLProxy.WithoutSimpleDML.class, 'Expected fflib_Database_DMLProxy.WithoutSimpleDML instance.' );

        // Assert DMLProxy instance of type InheritSimpleDML
        System.Assert.isInstanceOfType( fflib_Database.getDMLProxy( fflib_Database.Context.INHERIT ), fflib_Database_DMLProxy.InheritSimpleDML.class, 'Expected fflib_Database_DMLProxy.InheritSimpleDML instance.' );
    }

    @IsTest
    private static void getQueryProxy(){
        // Assert QueryProxy instance of type QueryWithSharing
        System.Assert.isInstanceOfType( fflib_Database.getQueryProxy( fflib_Database.Context.FULL ), fflib_Database_QueryProxy.QueryWithSharing.class, 'Expected fflib_Database_DMLProxy.QueryWithSharing instance.' );

        // Assert QueryProxy instance of type QueryWithSharing
        System.Assert.isInstanceOfType( fflib_Database.getQueryProxy( fflib_Database.Context.SHARING_SKIP_PERMISSIONS ), fflib_Database_QueryProxy.QueryWithSharing.class, 'Expected fflib_Database_DMLProxy.QueryWithSharing instance.' );

        // Assert QueryProxy instance of type QueryWithoutSharing
        System.Assert.isInstanceOfType( fflib_Database.getQueryProxy( fflib_Database.Context.NONE ), fflib_Database_QueryProxy.QueryWithoutSharing.class, 'Expected fflib_Database_DMLProxy.QueryWithoutSharing instance.' );

        // Assert QueryProxy instance of type QueryInheritedSharing
        System.Assert.isInstanceOfType( fflib_Database.getQueryProxy( fflib_Database.Context.INHERIT ), fflib_Database_QueryProxy.QueryInheritedSharing.class, 'Expected fflib_Database_DMLProxy.QueryProxyInheritedSharing instance.' );
    }

    /**
     * Section focusing on testing 'with sharing' context, enforcing FLS/CRUD checks
     */
    private static final AccessLevel withSharingAccessLevel = fflib_Database.getAccessLevel( fflib_Database.Context.FULL );

    @IsTest
    private static void withSharing_query_failureInvalidFieldQueried(){
        // Given - create data
        fflib_QueryFactory queryFactory = new fflib_QueryFactory( Solution.SObjectType );
        queryFactory.selectFields( new List<SObjectField>{
            Solution.IsPublished,
            Solution.SolutionName
        } );
        queryFactory.setOrdering( Solution.CreatedDate, fflib_QueryFactory.SortOrder.DESCENDING ); // To ensure query without filters returns the last Solution records created
        queryFactory.setLimit( 2 );

        // When - perform test
        System.runAs( testUser ){
            fflib_Database_IQuery queryProxy = fflib_Database.getQueryProxy( fflib_Database.Context.FULL );

            // Query without binds
            try{
                queryProxy.query( queryFactory.toSOQL(), withSharingAccessLevel );
                System.Assert.fail( 'Expected DmlException to be thrown. This assertion should never be triggered' );
            } catch( System.QueryException ex ){
                // Then - validate
                System.Assert.areEqual(
                    'No such column \'ispublished\' on entity \'Solution\'. If you are attempting to use a custom field, be sure to append the \'__c\' after the custom field name. Please reference your WSDL or the describe call for the appropriate names.',
                    ex.getMessage()
                );
            }

            // Query with binds
            try{
                queryProxy.query( queryFactory.toSOQL(), new Map<String, Object>(), withSharingAccessLevel );
                System.Assert.fail( 'Expected DmlException to be thrown. This assertion should never be triggered' );
            } catch( System.QueryException ex ){
                // Then - validate
                System.Assert.areEqual(
                    'No such column \'ispublished\' on entity \'Solution\'. If you are attempting to use a custom field, be sure to append the \'__c\' after the custom field name. Please reference your WSDL or the describe call for the appropriate names.',
                    ex.getMessage()
                );
            }
        }
    }

    @IsTest
    private static void withSharing_getQueryLocator_failureInvalidFieldQueried(){
        // Given - create data
        fflib_QueryFactory queryFactory = new fflib_QueryFactory( Solution.SObjectType );
        queryFactory.selectFields( new List<SObjectField>{
            Solution.IsPublished,
            Solution.SolutionName
        } );
        queryFactory.setOrdering( Solution.CreatedDate, fflib_QueryFactory.SortOrder.DESCENDING ); // To ensure query without filters returns the last Solution records created
        queryFactory.setLimit( 2 );

        // When, Then
        System.runAs( testUser ){
            fflib_Database_IQuery queryProxy = fflib_Database.getQueryProxy( fflib_Database.Context.FULL );
            // getQueryLocator without bind variables map
            try{
                queryProxy.getQueryLocator( queryFactory.toSOQL(), withSharingAccessLevel );
                System.Assert.fail( 'An exception was expected due to Solution SObject type not supported for this action.' );
            } catch( System.QueryException ex ){
                System.Assert.areEqual(
                    'No such column \'ispublished\' on entity \'Solution\'. If you are attempting to use a custom field, be sure to append the \'__c\' after the custom field name. Please reference your WSDL or the describe call for the appropriate names.',
                    ex.getMessage()
                );
            }

            // getQueryLocator with bind variables map
            try{
                queryProxy.getQueryLocator( queryFactory.toSOQL(), new Map<String, Object>(), withSharingAccessLevel );
                System.Assert.fail( 'Expected System.QueryException to be thrown. This assertion should never be triggered' );
            } catch( System.QueryException ex ){
                System.Assert.areEqual(
                    'No such column \'ispublished\' on entity \'Solution\'. If you are attempting to use a custom field, be sure to append the \'__c\' after the custom field name. Please reference your WSDL or the describe call for the appropriate names.',
                    ex.getMessage()
                );
            }
        }
    }

    @IsTest
    private static void withSharing_performDMLAction_failure_mismatches_DMLOptions_DMLAction(){
        System.runAs( testUser ){
            fflib_Database_IDML dmlProxy = fflib_Database.getDMLProxy( fflib_Database.Context.FULL );

            // When, Then - DMLOptions don't exist on Delete
            try{
                dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dDELETE, new List<Solution>(), new Database.DMLOptions(), withSharingAccessLevel );
                System.Assert.fail( 'An exception was expected due to an invalid DML action.' );
            } catch( fflib_Database_DMLProxy.InvalidDMLActionException dmlActionException ){
                System.Assert.areEqual( 'Invalid Action for DMLAction with DMLOptions ' + fflib_SObjectUnitOfWork.DMLActions.dDELETE, dmlActionException.getMessage() );
            }

            // When, Then - AllOrNone doesn't exist on New
            try{
                dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dNEW, new List<Solution>(), true, withSharingAccessLevel );
                System.Assert.fail( 'An exception was expected due to an invalid DML action.' );
            } catch( fflib_Database_DMLProxy.InvalidDMLActionException dmlActionException ){
                System.Assert.areEqual( 'Invalid Action for DMLAction with AllOrNone Boolean ' + fflib_SObjectUnitOfWork.DMLActions.dNEW, dmlActionException.getMessage() );
            }

            // When, Then - DMLOptions are required for New DMLAction
            try{
                dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dNEW, new List<Solution>{ new Solution() }, withSharingAccessLevel );
                System.Assert.fail( 'An exception was expected due to an invalid DML action.' );
            } catch( fflib_Database_DMLProxy.InvalidDMLActionException dmlActionException ){
                System.Assert.areEqual( 'Invalid Action for DMLAction without additional parameters ' + fflib_SObjectUnitOfWork.DMLActions.dNEW, dmlActionException.getMessage() );
            }
        }
    }

    @IsTest
    private static void withSharing_performDMLAction_failure_missingPermissions(){
        // Given - create data
        Solution newSolution = sampleSolutionList[ 0 ].clone( false, true );
        Solution updateSolution = sampleSolutionList[ 0 ];

        List<Solution> solutionsList_withoutIds = new List<Solution>{ newSolution };
        List<Solution> solutionsList_withIds = new List<Solution>{ updateSolution };

        System.runAs( testUser ){
            fflib_Database_IDML dmlProxy = fflib_Database.getDMLProxy( fflib_Database.Context.FULL );
            Database.DMLOptions dmlOptions = new Database.DMLOptions();
            dmlOptions.optAllOrNone = true;

            // When, Then - User has no create permissions on Solution
            try{
                dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dNEW, solutionsList_withoutIds, dmlOptions, withSharingAccessLevel );
                System.Assert.fail( 'Expected DmlException to be thrown. This assertion should never be triggered' );
            } catch( System.TypeException ex ){
                // Then - validate
                System.Assert.areEqual( 'DML operation INSERT not allowed on Solution', ex.getMessage() );
            }

            // When, Then - User has no update permissions on Solution
            try{
                dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dUPDATE, solutionsList_withIds, dmlOptions, withSharingAccessLevel );
                System.Assert.fail( 'Expected System.TypeException to be thrown. This assertion should never be triggered' );
            } catch( System.TypeException ex ){
                System.Assert.areEqual( 'DML operation UPDATE not allowed on Solution', ex.getMessage() );
            }

            // When, Then - User has no delete permissions on Solution
            try{
                dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dDELETE, solutionsList_withIds, true, withSharingAccessLevel );
                System.Assert.fail( 'Expected DmlException to be thrown. This assertion should never be triggered' );
            } catch( System.Exception ex ){
                System.Assert.areEqual( 'DML operation DELETE not allowed on Solution', ex.getMessage() );
            }

            // When, Then - User has no undelete permissions on Solution
            try{
                dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dUNDELETE, solutionsList_withIds, true, withSharingAccessLevel );
                System.Assert.fail( 'Expected DmlException to be thrown. This assertion should never be triggered' );
            } catch( System.Exception ex ){
                System.Assert.areEqual( 'Undelete failed. First exception on row 0 with id ' + updateSolution.Id + '; first error: CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY, Entity type is not undeletable: []', ex.getMessage() );
            }

            // Immediate actions
            // - While Database.insertImmediate() should be used for External, Big or special Objects; Solution was used to keep the UOW project-implementation-independent
            // - InsertImmediate runs by default with allOrNone = false, and will thus not throw an Exception but requires the SaveResults to be verified

            // When, Then - User has no Insert Immediate permissions on Solutions
            List<Database.SaveResult> dmlResult = ( List<Database.SaveResult> ) dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dNEW_IMMEDIATE, solutionsList_withoutIds, withSharingAccessLevel );
            System.Assert.areEqual( 'DML operation INSERT not allowed on Solution', validateDMLResult_FailureMessage( dmlResult ), 'Expected a different Exception message in SaveResult' );

            // When, Then - User has no Update Immediate permissions on Solutions
            dmlResult = ( List<Database.SaveResult> ) dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dUPDATE_IMMEDIATE, solutionsList_withIds, withSharingAccessLevel );
            System.Assert.areEqual( 'DML operation UPDATE not allowed on Solution', validateDMLResult_FailureMessage( dmlResult ), 'Expected a different Exception message in SaveResult' );

            // When, Then - User has no Delete Immediate permissions on Solutions
            try{
                dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dDELETE_IMMEDIATE, solutionsList_withIds, withSharingAccessLevel );
                System.Assert.fail( 'Expected DmlException to be thrown. This assertion should never be triggered' );
            } catch( System.TypeException ex ){
                System.Assert.areEqual( 'DML operation DELETE not allowed on Solution', ex.getMessage() );
            }

            // When, Then - EmptyRecycle Bin - no record in recycle bin to restore
            List<Database.EmptyRecycleBinResult> emptyRecycleBinResult = ( List<Database.EmptyRecycleBinResult> ) dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dEMPTY_RECBIN, solutionsList_withIds, withSharingAccessLevel );
            System.Assert.isFalse( emptyRecycleBinResult.isEmpty(), 'Expected one EmptyRecycleBinResult record' );
            System.Assert.isFalse( emptyRecycleBinResult[ 0 ].isSuccess(), 'Expected a failed EmptyRecycleBinResult' );
            System.Assert.isFalse( emptyRecycleBinResult[ 0 ].getErrors()?.isEmpty(), 'Expected a record in the getErrors() list' );
            List<Database.Error> dmlErrors = emptyRecycleBinResult[ 0 ].getErrors();
            System.Assert.areEqual( System.StatusCode.INVALID_ID_FIELD, dmlErrors[ 0 ].getStatusCode() );
            System.Assert.areEqual( 'invalid record id; no recycle bin entry found', dmlErrors[ 0 ].getMessage() );
        }
    }

    private static String validateDMLResult_FailureMessage( List<Database.SaveResult> dmlResult ){
        System.Assert.areEqual( 1, dmlResult.size(), 'Expected one SaveResult record' );
        System.Assert.isFalse( dmlResult[ 0 ].isSuccess(), 'Expected a failed SaveResult' );
        System.Assert.isFalse( dmlResult[ 0 ].getErrors()?.isEmpty(), 'Expected a record in the getErrors() list' );
        return dmlResult[ 0 ].getErrors()[ 0 ]?.getMessage();
    }

    /**
     * As per Summer'24 (API v61.0), EventBus.publish(SObject event) returns a System.UnexpectedException when attempting to publish an SObject that represents an object that isn’t a platform event.
     * Therefore, only standard PlatformEvent or project-specific CustomEvent can be specified (though not being able to rely on)
     * Hence, covering as much lines as possible and ensuring those parts of code behave as expected
     */
    @IsTest
    private static void withSharing_shouldPublishBeforeAfterTransactionWithNoResults(){
        // Given - create data
        fflib_Database_IDML dmlProxy = fflib_Database.getDMLProxy( fflib_Database.Context.FULL );
        List<BatchApexErrorEvent> eventList = new List<BatchApexErrorEvent>{ new BatchApexErrorEvent() };

        // When - perform test
        System.runAs( testUser ){
            Test.startTest();
            try{
                List<Database.SaveResult> publishResultBeforeResult = ( List<Database.SaveResult> ) dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dPUB_BEFORE, eventList, withSharingAccessLevel );
            } catch( Exception typeException ){
                // Then - validate
                System.Assert.isInstanceOfType( typeException, System.TypeException.class, 'Expected an System.TypeException, got ' + typeException.getTypeName() );
                System.Assert.areEqual( 'DML operation INSERT not allowed on BatchApexErrorEvent', typeException.getMessage() );
            }

            try{
                List<Database.SaveResult> publishResultAfterSuccessResult = ( List<Database.SaveResult> ) dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dPUB_AFTER_SUCCESS, eventList, withSharingAccessLevel );
            } catch( Exception typeException ){
                // Then - validate
                System.Assert.isInstanceOfType( typeException, System.TypeException.class, 'Expected an System.TypeException, got ' + typeException.getTypeName() );
                System.Assert.areEqual( 'DML operation INSERT not allowed on BatchApexErrorEvent', typeException.getMessage() );
            }

            try{
                List<Database.SaveResult> publishResultAfterFailureResult = ( List<Database.SaveResult> ) dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dPUB_AFTER_FAILURE, eventList, withSharingAccessLevel );
            } catch( Exception typeException ){
                // Then - validate
                System.Assert.isInstanceOfType( typeException, System.TypeException.class, 'Expected an System.TypeException, got ' + typeException.getTypeName() );
                System.Assert.areEqual( 'DML operation INSERT not allowed on BatchApexErrorEvent', typeException.getMessage() );
            }
            Test.stopTest();
        }
    }
    @IsTest
    private static void withSharing_noDMLActionToBePerformed(){
        // Given - create data
        List<Solution> solutionsList = new List<Solution>(); // This should cause no DML actions to be performed in empty list of Objects

        System.runAs( testUser ){
            fflib_Database_IDML dmlProxy = fflib_Database.getDMLProxy( fflib_Database.Context.FULL );

            // When - perform test
            List<Object> dmlResult = dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dPUB_BEFORE, solutionsList, withSharingAccessLevel );

            // Then - validate
            System.Assert.isNull( dmlResult );
        }
    }

    /**
     * @todo
     * -- successful delete, query combination
     * -- Logic to validate Event Publish in case fflib_Config.Test_PlatformEvent_Type__c is populated?
     */


    @IsTest
    private static void withSharing_performEmailOperation(){
        // Create mocks
        fflib_Database_IDML dmlProxy = fflib_Database.getDMLProxy( fflib_Database.Context.FULL );

        // Given - create data
        Messaging.SingleEmailMessage emailForOpp = new Messaging.SingleEmailMessage();
        emailForOpp.setWhatId( sampleContactRequestList[ 0 ].Id );
        emailForOpp.setToAddresses( new List<String>{ 'foobar@test.com' } );
        emailForOpp.setPlainTextBody( 'Amazing message to send' );

        // When - perform test
        System.runAs( testUser ){
            // Messaging.sendEmail requires Email Deliverability to be set to 'All Email', which is not best-practice for Sandboxes
            // Below test method verifies the two scenarios:
            // - All Email Deliverability (e.g. Production) - validate sent email is related to the specified ContactRequest
            // - Limited Deliverability (e.g. 'No access' or 'System email only') - check if specific SF Exception is thrown
            Test.startTest();
            try{
                dmlProxy.performOperation( fflib_SObjectUnitOfWork.Operations.SEND_EMAIL, new List<Object>{ emailForOpp } );
            } catch( EmailException ex ){
                System.Assert.isTrue(
                    ex.getMessage().contains( 'INSUFFICIENT_ACCESS_OR_READONLY' ) || ex.getMessage().contains( 'NO_SINGLE_MAIL_PERMISSION' ) || ex.getMessage().contains( 'NO_MASS_MAIL_PERMISSION' ),
                    'System expected an Exception to be thrown as EmailDeliverability was NOT set to \'All_Email\', which is fine. ' +
                        'Nevertheless, the thrown Exception didn\'t contain the expected INSUFFICIENT_ACCESS_OR_READONLY, NO_SINGLE_MAIL_PERMISSION or NO_MASS_MAIL_PERMISSION, but was: ' + ex.getMessage()
                );
                System.Assert.areEqual( 0, Limits.getEmailInvocations(), 'Expected no email to be sent' );
                Test.stopTest();
                return;
            }
            // Assert that an email was sent
            System.Assert.areEqual( 1, Limits.getEmailInvocations(), 'Expected one email to be invoked' );
            Test.stopTest();
        }
    }

    @IsTest
    private static void withSharing_performApprovalOperation(){
        // Create mocks
        fflib_Database_IDML dmlProxy = fflib_Database.getDMLProxy( fflib_Database.Context.FULL );

        // Create an approval request for the Solution
        Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
        request.setComments( 'Submitting request for approval.' );
        request.setObjectId( sampleSolutionList[ 0 ].Id );

        // Submit on behalf of a specific submitter
        request.setSubmitterId( testUser.Id );

        // Submit the record to specific process and skip the criteria evaluation
        request.setProcessDefinitionNameOrId( null );
        request.setSkipEntryCriteria( true );

        request.setNextApproverIds( new List<Id>{ testUser.Id } );

        // When - perform test
        System.runAs( testUser ){
            try{
                dmlProxy.performOperation( fflib_SObjectUnitOfWork.Operations.PROCESS_APPROVAL_PROCESS, new List<Object>{ request } );
                throw new fflib_SObjectUnitOfWork.UnitOfWorkException( 'Expected Exception as no Approval Process is setup' );
            } catch( DmlException ex ){
                System.Assert.isTrue(
                    ex.getMessage().contains( 'NO_APPLICABLE_PROCESS' ) || ex.getMessage().contains( 'INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY' ),
                    'System expected an Exception to be thrown as either no applicable processes are setup in this Org or insufficient access to the cross reference set in the ObjectId. ' +
                        'Nevertheless, the thrown Exception didn\'t contain the expected NO_APPLICABLE_PROCESS or INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY, but was: ' + ex.getMessage()
                );
                return;
            }
        }
    }

    @IsTest
    private static void withSharing_invalidOperationToPerform(){
        // Create mocks
        fflib_Database_IDML dmlProxy = fflib_Database.getDMLProxy( fflib_Database.Context.FULL );

        // When, Then
        System.runAs( testUser ){
            try{
                dmlProxy.performOperation( null, new List<Object>{ new Approval.ProcessSubmitRequest() } );
                throw new fflib_SObjectUnitOfWork.UnitOfWorkException( 'Expected Exception as no Approval Process is setup' );
            } catch( fflib_Database_DMLProxy.InvalidDMLActionException ex ){
                System.Assert.areEqual( 'Invalid Operation null', ex.getMessage() );
            }

            List<Object> nullResults = dmlProxy.performOperation( fflib_SObjectUnitOfWork.Operations.PROCESS_APPROVAL_PROCESS, null );
            System.Assert.isNull( nullResults );
        }
    }

    /**
     * Section focusing on testing 'with sharing' context, without enforcing FLS/CRUD permissions
     */
    private static final AccessLevel sharingSkipAccessLevel = fflib_Database.getAccessLevel( fflib_Database.Context.SHARING_SKIP_PERMISSIONS );

    @IsTest
    private static void withSharingSkip_shouldCorrectlyQueryWithoutBinds(){
        // Given - create data
        fflib_Database_IQuery queryProxy = fflib_Database.getQueryProxy( fflib_Database.Context.SHARING_SKIP_PERMISSIONS );
        fflib_QueryFactory queryFactory = new fflib_QueryFactory( Solution.SObjectType );
        queryFactory.selectFields( new List<SObjectField>{
            Solution.IsPublished,
            Solution.SolutionName
        } );
        queryFactory.setOrdering( Solution.CreatedDate, fflib_QueryFactory.SortOrder.DESCENDING ); // To ensure query without filters returns the last Solution records created
        queryFactory.setLimit( SAMPLE_SIZE_SOLUTION );
        List<Solution> solutionResults = new List<Solution>();

        // When - perform test
        System.runAs( testUser ){
            solutionResults = ( List<Solution> ) queryProxy.query( queryFactory.toSOQL(), sharingSkipAccessLevel );
        }

        // Then - validate
        System.Assert.areEqual(
            ( isPrivateSolutionInternalSharing ? 0 : SAMPLE_SIZE_SOLUTION ), // If the internal sharing mode for Solution is private, expect no records shared.
            solutionResults.size()
        );
    }

    @IsTest
    private static void withSharingSkip_shouldCorrectlyGetQueryLocatorWithoutBinds(){
        // Given - create data
        fflib_Database_IQuery queryProxy = fflib_Database.getQueryProxy( fflib_Database.Context.SHARING_SKIP_PERMISSIONS );
        fflib_QueryFactory queryFactory = new fflib_QueryFactory( Solution.SObjectType );
        queryFactory.selectFields( new List<SObjectField>{
            Solution.IsPublished,
            Solution.SolutionName
        } );
        queryFactory.setOrdering( Solution.CreatedDate, fflib_QueryFactory.SortOrder.DESCENDING ); // To ensure query without filters returns the last Solution records created
        queryFactory.setLimit( SAMPLE_SIZE_SOLUTION );
        List<Solution> sampleSolutions = sampleSolutionList;

        // When - perform test
        System.runAs( testUser ){
            Database.QueryLocator queryLocatorResult = queryProxy.getQueryLocator( queryFactory.toSOQL(), sharingSkipAccessLevel );

            // Then - validate
            Database.QueryLocatorIterator queryLocatorIterator = queryLocatorResult.iterator(); // Get an iterator to go over the record result
            Integer ind = 0;

            // Iterate over the record set
            while( queryLocatorIterator.hasNext() ){
                Solution solutionToCompare = ( Solution ) queryLocatorIterator.next();
                Solution sampleSolution = sampleSolutions.get( ind++ );
                System.Assert.areEqual( sampleSolution.Id, solutionToCompare.Id );
                System.Assert.areEqual( sampleSolution.IsPublished, solutionToCompare.IsPublished );
                System.Assert.areEqual( sampleSolution.SolutionName, solutionToCompare.SolutionName );
            }
        }
    }

    @IsTest
    private static void withSharingSkip_shouldThrowExceptionWithInvalidDMLActionForInsertUpdate(){
        // Given - create data
        fflib_Database_IDML dmlProxy = fflib_Database.getDMLProxy( fflib_Database.Context.SHARING_SKIP_PERMISSIONS );

        // When, Then
        try{
            dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dDELETE, new List<Solution>(), new Database.DMLOptions(), sharingSkipAccessLevel );
            System.Assert.fail( 'An exception was expected due to an invalid DML action.' );
        } catch( fflib_Database_DMLProxy.InvalidDMLActionException dmlActionException ){
            System.Assert.areEqual( 'Invalid Action for DMLAction with DMLOptions ' + fflib_SObjectUnitOfWork.DMLActions.dDELETE, dmlActionException.getMessage() );
        }
    }

    @IsTest
    private static void withSharingSkip_shouldThrowExceptionWithInvalidDMLActionForDeleteUndelete(){
        // Given - create data
        fflib_Database_IDML dmlProxy = fflib_Database.getDMLProxy( fflib_Database.Context.SHARING_SKIP_PERMISSIONS );

        // When, Then
        try{
            dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dNEW, new List<Solution>(), true, sharingSkipAccessLevel );
            System.Assert.fail( 'An exception was expected due to an invalid DML action.' );
        } catch( fflib_Database_DMLProxy.InvalidDMLActionException dmlActionException ){
            System.Assert.areEqual( 'Invalid Action for DMLAction with AllOrNone Boolean ' + fflib_SObjectUnitOfWork.DMLActions.dNEW, dmlActionException.getMessage() );
        }
    }

    @IsTest
    private static void withSharingSkip_shouldThrowExceptionWithInvalidDMLActionForImmediateActions(){
        // Given - create data
        fflib_Database_IDML dmlProxy = fflib_Database.getDMLProxy( fflib_Database.Context.SHARING_SKIP_PERMISSIONS );

        // When, Then
        try{
            dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dNEW, new List<Solution>{ new Solution() }, sharingSkipAccessLevel );
            System.Assert.fail( 'An exception was expected due to an invalid DML action.' );
        } catch( fflib_Database_DMLProxy.InvalidDMLActionException dmlActionException ){
            System.Assert.areEqual( 'Invalid Action for DMLAction without additional parameters ' + fflib_SObjectUnitOfWork.DMLActions.dNEW, dmlActionException.getMessage() );
        }
    }

    // Testing dNEW/dUPDATE/dDELETE actions in sequence, as well as dEMPTY_RECBIN and dUNDELETE for completeness. Database queries performed using QueryLocator interface
    @IsTest
    private static void withSharingSkip_shouldCorrectlyInsertUpdateDeleteAndGetQueryLocatorWithBinds(){
        // Given - create data
        fflib_Database_IDML dmlProxy = fflib_Database.getDMLProxy( fflib_Database.Context.SHARING_SKIP_PERMISSIONS );
        fflib_Database_IQuery queryProxy = fflib_Database.getQueryProxy( fflib_Database.Context.SHARING_SKIP_PERMISSIONS );
        Solution testSolution = new Solution( SolutionName = 'TestName3', IsPublished = true );
        List<Solution> solutionsList = new List<Solution>{ testSolution };
        fflib_QueryFactory queryFactory = new fflib_QueryFactory( Solution.SObjectType );
        queryFactory.selectFields( new List<SObjectField>{
            Solution.IsPublished,
            Solution.SolutionName
        } );
        queryFactory.setCondition( 'Id IN :solutionIds' );

        Set<Id> solutionIdsSet = new Set<Id>{ testSolution.Id };
        Map<String, Object> bindVariablesMap = new Map<String, Object>{
            'solutionIds' => solutionIdsSet
        };
        Database.DMLOptions dmlOptions = new Database.DMLOptions();
        Boolean allOrNone = true;

        // 1st, insert Solution record and set Owner as running test user. This will allow proper testing of DML actions in records that are visible/shared with the test user
        System.runAs( testUser ){
            List<Database.SaveResult> insertDMLResult = ( List<Database.SaveResult> ) dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dNEW, solutionsList, dmlOptions, sharingSkipAccessLevel );

            // Assert that the Solution record to be updated was correctly inserted
            System.Assert.areEqual( 1, insertDMLResult.size() );
            System.Assert.isTrue( insertDMLResult[ 0 ].isSuccess() );

            // Update HasOptedOutGeoTracking field
            Solution testSolutionUpdated = new Solution( Id = testSolution.Id, IsPublished = !testSolution.IsPublished );
            solutionIdsSet = new Set<Id>{ testSolutionUpdated.Id };
            bindVariablesMap = new Map<String, Object>{ 'solutionIds' => solutionIdsSet };

            // When - perform dUPDATE on newly created Solution record. This should succeed, bypassing the CRUD restrictions imposed to the test user
            dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dUPDATE, new List<Solution>{ testSolutionUpdated }, dmlOptions, sharingSkipAccessLevel );

            // Get the updated record from the database and assert
            Database.QueryLocator queryLocatorResult = queryProxy.getQueryLocator( queryFactory.toSOQL(), bindVariablesMap, sharingSkipAccessLevel );

            // Then - validate
            Database.QueryLocatorIterator queryLocatorIterator = queryLocatorResult.iterator(); // Get an iterator to go over the record result
            // Iterate over the record set
            System.Assert.isTrue( queryLocatorIterator.hasNext() );
            Solution testSolutionsUpdated = ( Solution ) queryLocatorIterator.next();

            System.Assert.areEqual( testSolution.Id, testSolutionsUpdated.Id );
            System.Assert.areNotEqual( testSolution.IsPublished, testSolutionsUpdated.IsPublished ); // Solution IsPublished should be updated with new value
            System.Assert.areEqual( testSolutionUpdated.IsPublished, testSolutionsUpdated.IsPublished );
            System.Assert.areEqual( testSolution.SolutionName, testSolutionsUpdated.SolutionName );

            System.Assert.isFalse( queryLocatorIterator.hasNext() );

            // When - perform dDELETE on Solution test record. This should succeed, bypassing the CRUD restrictions imposed to the test user
            dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dDELETE, solutionsList, allOrNone, sharingSkipAccessLevel );

            // When, Then - verify after deletion that Solution no longer exists
            List<Solution> solutionsDeleteResult = ( List<Solution> ) queryProxy.query( queryFactory.toSOQL(), bindVariablesMap, sharingSkipAccessLevel );
            System.Assert.areEqual( 0, solutionsDeleteResult.size() );

            // Empty RecycleBin
            List<Database.EmptyRecycleBinResult> emptyEmptyRecycleBinResults =
                ( List<Database.EmptyRecycleBinResult> ) dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dEMPTY_RECBIN, solutionsList, sharingSkipAccessLevel );
            // Verify that the recycle bin operation succeeded
            System.Assert.areEqual( 1, emptyEmptyRecycleBinResults.size() );
            System.Assert.isTrue( emptyEmptyRecycleBinResults[ 0 ].isSuccess() );
            System.Assert.areEqual( emptyEmptyRecycleBinResults[ 0 ].id, testSolution.Id );

            // When, Then - Solution record can no longer be undeleted
            try{
                dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dUNDELETE, solutionsList, true, sharingSkipAccessLevel );
                System.Assert.fail( 'Expected DmlException exception. This assertion should never be triggered' );
            } catch( DmlException ex ){
                System.Assert.areEqual( 'Undelete failed. First exception on row 0 with id ' + solutionsList[ 0 ].Id + '; first error: UNDELETE_FAILED, Entity is not in the recycle bin: []', ex.getMessage() );
            }
        }
    }

    // Testing dNEW_PRIO/dUPDATE_PRIO/dDELETE_PRIO actions in sequence, as well as dEMPTY_RECBIN and dUNDELETE for completeness
    @IsTest
    private static void withSharingSkip_shouldCorrectlyInsertUpdateDeletePrioAndQueryWithBinds(){
        // Given - create data
        fflib_Database_IDML dmlProxy = fflib_Database.getDMLProxy( fflib_Database.Context.SHARING_SKIP_PERMISSIONS );
        fflib_Database_IQuery queryProxy = fflib_Database.getQueryProxy( fflib_Database.Context.SHARING_SKIP_PERMISSIONS );
        Solution testSolution = new Solution( SolutionName = 'TestName3', IsPublished = true );
        List<Solution> solutionsList = new List<Solution>{ testSolution };
        fflib_QueryFactory queryFactory = new fflib_QueryFactory( Solution.SObjectType );
        queryFactory.selectFields( new List<SObjectField>{
            Solution.IsPublished,
            Solution.SolutionName
        } );
        queryFactory.setCondition( 'Id IN :solutionIds' );

        Set<Id> solutionIdsSet = new Set<Id>{ testSolution.Id };
        Map<String, Object> bindVariablesMap = new Map<String, Object>{
            'solutionIds' => solutionIdsSet
        };
        List<Solution> solutionsResult = new List<Solution>();
        Database.DMLOptions dmlOptions = new Database.DMLOptions();
        Boolean allOrNone = true;

        // 1st, insert Solution record and set Owner as running test user. This will allow proper testing of DML actions in records that are visible/shared with the test user
        System.runAs( testUser ){
            List<Database.SaveResult> insertDMLResult = ( List<Database.SaveResult> ) dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dNEW_PRIO, solutionsList, dmlOptions, sharingSkipAccessLevel );

            // Assert that the Solution record to be updated was correctly inserted
            System.Assert.areEqual( 1, insertDMLResult.size() );
            System.Assert.isTrue( insertDMLResult[ 0 ].isSuccess() );

            // Update Message field
            Solution testSolutionUpdated = new Solution( Id = testSolution.Id, IsPublished = !testSolution.IsPublished );
            solutionIdsSet = new Set<Id>{ testSolutionUpdated.Id };
            bindVariablesMap = new Map<String, Object>{ 'solutionIds' => solutionIdsSet };

            // When - perform dUPDATE_PRIO on newly created Solution record. This should succeed, bypassing the CRUD restrictions imposed to the test user
            dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dUPDATE_PRIO, new List<Solution>{ testSolutionUpdated }, dmlOptions, sharingSkipAccessLevel );

            solutionsResult = ( List<Solution> ) queryProxy.query( queryFactory.toSOQL(), bindVariablesMap, sharingSkipAccessLevel );

            // Verify that the Solution was correctly updated
            System.Assert.areEqual( 1, solutionsResult.size() );
            Solution testSolutionsUpdated = solutionsResult[ 0 ];

            System.Assert.areEqual( testSolution.Id, testSolutionsUpdated.Id );
            System.Assert.areNotEqual( testSolution.IsPublished, testSolutionsUpdated.IsPublished ); // Solution IsPublished should be updated with new value
            System.Assert.areEqual( testSolutionUpdated.IsPublished, testSolutionsUpdated.IsPublished );
            System.Assert.areEqual( testSolution.SolutionName, testSolutionsUpdated.SolutionName );

            // When - perform dDELETE_PRIO on Solution test record. This should succeed, bypassing the CRUD restrictions imposed to the test user
            dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dDELETE_PRIO, solutionsList, allOrNone, sharingSkipAccessLevel );

            // When, Then - verify after deletion that Solution no longer exists
            List<Solution> solutionsDeleteResult = ( List<Solution> ) queryProxy.query( queryFactory.toSOQL(), bindVariablesMap, sharingSkipAccessLevel );
            System.Assert.areEqual( 0, solutionsDeleteResult.size() );

            // Empty RecycleBin
            List<Database.EmptyRecycleBinResult> emptyEmptyRecycleBinResults =
                ( List<Database.EmptyRecycleBinResult> ) dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dEMPTY_RECBIN, solutionsList, sharingSkipAccessLevel );
            // Verify that the recycle bin operation succeeded
            System.Assert.areEqual( 1, emptyEmptyRecycleBinResults.size() );
            System.Assert.isTrue( emptyEmptyRecycleBinResults[ 0 ].isSuccess() );
            System.Assert.areEqual( emptyEmptyRecycleBinResults[ 0 ].id, testSolution.Id );

            // When, Then - Solution record can no longer be undeleted
            try{
                dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dUNDELETE, solutionsList, true, sharingSkipAccessLevel );
                System.Assert.fail( 'Expected DmlException exception. This assertion should never be triggered' );
            } catch( DmlException ex ){
                System.Assert.areEqual( 'Undelete failed. First exception on row 0 with id ' + solutionsList[ 0 ].Id + '; first error: UNDELETE_FAILED, Entity is not in the recycle bin: []', ex.getMessage() );
            }
        }
    }

    // While Database.insertImmediate()/updateImmediate()/deleteImmediate() should be used for External, Big or special Objects;
    // Solution is used to keep the UOW project-implementation-independent
    // Testing dNEW_IMMEDIATE/dUPDATE_IMMEDIATE/dDELETE_IMMEDIATE actions in sequence, as well as dEMPTY_RECBIN and dUNDELETE for completeness
    @IsTest
    private static void withSharingSkip_shouldCorrectlyInsertUpdateDeleteImmediateAndQueryWithBinds(){
        // Given - create data
        fflib_Database_IDML dmlProxy = fflib_Database.getDMLProxy( fflib_Database.Context.SHARING_SKIP_PERMISSIONS );
        fflib_Database_IQuery queryProxy = fflib_Database.getQueryProxy( fflib_Database.Context.SHARING_SKIP_PERMISSIONS );
        Solution testSolution = new Solution( SolutionName = 'TestName3', IsPublished = true );
        List<Solution> solutionsList = new List<Solution>{ testSolution };
        fflib_QueryFactory queryFactory = new fflib_QueryFactory( Solution.SObjectType );
        queryFactory.selectFields( new List<SObjectField>{
            Solution.IsPublished,
            Solution.SolutionName
        } );
        queryFactory.setCondition( 'Id IN :solutionIds' );

        Set<Id> solutionIdsSet = new Set<Id>{ testSolution.Id };
        Map<String, Object> bindVariablesMap = new Map<String, Object>{
            'solutionIds' => solutionIdsSet
        };
        List<Solution> solutionResults = new List<Solution>();

        // 1st, insert Solution record and set Owner as running test user. This will allow proper testing of DML actions in records that are visible/shared with the test user
        System.runAs( testUser ){
            List<Database.SaveResult> insertDMLResult = ( List<Database.SaveResult> ) dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dNEW_IMMEDIATE, solutionsList, sharingSkipAccessLevel );

            // Assert that the Solution record to be updated was correctly inserted
            System.Assert.areEqual( 1, insertDMLResult.size() );
            System.Assert.isTrue( insertDMLResult[ 0 ].isSuccess() );

            // Update Message field
            Solution testSolutionUpdated = new Solution( Id = testSolution.Id, IsPublished = !testSolution.IsPublished );
            solutionIdsSet = new Set<Id>{ testSolutionUpdated.Id };
            bindVariablesMap = new Map<String, Object>{ 'solutionIds' => solutionIdsSet };

            // When - perform dUPDATE_IMMEDIATE on newly created Solution record. This should succeed, bypassing the CRUD restrictions imposed to the test user
            dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dUPDATE_IMMEDIATE, new List<Solution>{ testSolutionUpdated }, sharingSkipAccessLevel );

            solutionResults = ( List<Solution> ) queryProxy.query( queryFactory.toSOQL(), bindVariablesMap, sharingSkipAccessLevel );

            // Verify that the Solution was correctly updated
            System.Assert.areEqual( 1, solutionResults.size() );
            Solution testSolutionsUpdated = solutionResults[ 0 ];

            System.Assert.areEqual( testSolution.Id, testSolutionsUpdated.Id );
            System.Assert.areNotEqual( testSolution.IsPublished, testSolutionsUpdated.IsPublished ); // Solution IsPublished should be updated with new value
            System.Assert.areEqual( testSolutionUpdated.IsPublished, testSolutionsUpdated.IsPublished );
            System.Assert.areEqual( testSolution.SolutionName, testSolutionsUpdated.SolutionName );

            // When - perform dDELETE_IMMEDIATE on Solution test record. This should succeed, bypassing the CRUD restrictions imposed to the test user
            dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dDELETE_IMMEDIATE, solutionsList, sharingSkipAccessLevel );

            // When, Then - verify after deletion that Solution no longer exists
            List<Solution> solutionsDeleteResult = ( List<Solution> ) queryProxy.query( queryFactory.toSOQL(), bindVariablesMap, sharingSkipAccessLevel );
            System.Assert.areEqual( 0, solutionsDeleteResult.size() );

            // Empty RecycleBin
            List<Database.EmptyRecycleBinResult> emptyEmptyRecycleBinResults =
                ( List<Database.EmptyRecycleBinResult> ) dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dEMPTY_RECBIN, solutionsList, sharingSkipAccessLevel );
            // Verify that the recycle bin operation succeeded
            System.Assert.areEqual( 1, emptyEmptyRecycleBinResults.size() );
            System.Assert.isTrue( emptyEmptyRecycleBinResults[ 0 ].isSuccess() );
            System.Assert.areEqual( emptyEmptyRecycleBinResults[ 0 ].id, testSolution.Id );

            // When, Then - Solution record can no longer be undeleted
            try{
                dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dUNDELETE, solutionsList, true, sharingSkipAccessLevel );
                System.Assert.fail( 'Expected DmlException exception. This assertion should never be triggered' );
            } catch( DmlException ex ){
                System.Assert.areEqual( 'Undelete failed. First exception on row 0 with id ' + solutionsList[ 0 ].Id + '; first error: UNDELETE_FAILED, Entity is not in the recycle bin: []', ex.getMessage() );
            }
        }
    }

    /**
     * As per Summer'24 (API v61.0), EventBus.publish(SObject event) returns a System.UnexpectedException when attempting to publish an SObject that represents an object that isn’t a platform event.
     * Therefore, only standard PlatformEvent or project-specific CustomEvent can be specified (though not being able to rely on)
     * Hence, covering as much lines as possible and ensuring those parts of code behave as expected
     */
    @IsTest
    private static void withSharingSkip_shouldPublishBeforeAfterTransactionWithNoResults(){
        // Given - create data
        fflib_Database_IDML dmlProxy = fflib_Database.getDMLProxy( fflib_Database.Context.SHARING_SKIP_PERMISSIONS );
        List<BatchApexErrorEvent> eventList = new List<BatchApexErrorEvent>{ new BatchApexErrorEvent() };

        // When - perform test
        System.runAs( testUser ){
            Test.startTest();
            try{
                List<Database.SaveResult> publishResultBeforeResult = ( List<Database.SaveResult> ) dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dPUB_BEFORE, eventList, sharingSkipAccessLevel );
            } catch( Exception typeException ){
                // Then - validate
                System.Assert.isInstanceOfType( typeException, System.TypeException.class, 'Expected an System.TypeException, got ' + typeException.getTypeName() );
                System.Assert.areEqual( 'DML operation INSERT not allowed on BatchApexErrorEvent', typeException.getMessage() );
            }

            try{
                List<Database.SaveResult> publishResultAfterSuccessResult = ( List<Database.SaveResult> ) dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dPUB_AFTER_SUCCESS, eventList, sharingSkipAccessLevel );
            } catch( Exception typeException ){
                // Then - validate
                System.Assert.isInstanceOfType( typeException, System.TypeException.class, 'Expected an System.TypeException, got ' + typeException.getTypeName() );
                System.Assert.areEqual( 'DML operation INSERT not allowed on BatchApexErrorEvent', typeException.getMessage() );
            }

            try{
                List<Database.SaveResult> publishResultAfterFailureResult = ( List<Database.SaveResult> ) dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dPUB_AFTER_FAILURE, eventList, sharingSkipAccessLevel );
            } catch( Exception typeException ){
                // Then - validate
                System.Assert.isInstanceOfType( typeException, System.TypeException.class, 'Expected an System.TypeException, got ' + typeException.getTypeName() );
                System.Assert.areEqual( 'DML operation INSERT not allowed on BatchApexErrorEvent', typeException.getMessage() );
            }
            Test.stopTest();
        }
    }

    @IsTest
    private static void withSharingSkip_noDMLActionToBePerformed(){
        // Given - create data
        fflib_Database_IDML dmlProxy = fflib_Database.getDMLProxy( fflib_Database.Context.SHARING_SKIP_PERMISSIONS );
        List<Solution> solutionsList = new List<Solution>(); // This should cause no DML actions to be performed in empty list of Objects

        // When - perform test
        System.runAs( testUser ){
            List<Object> dmlResult = dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dPUB_BEFORE, solutionsList, sharingSkipAccessLevel );

            // Then - validate
            System.Assert.isNull( dmlResult );
        }
    }

    @IsTest
    private static void withSharingSkip_performEmailOperation(){
        // Create mocks
        fflib_Database_IDML dmlProxy = fflib_Database.getDMLProxy( fflib_Database.Context.SHARING_SKIP_PERMISSIONS );

        // Given - create data
        Messaging.SingleEmailMessage emailForOpp = new Messaging.SingleEmailMessage();
        emailForOpp.setWhatId( sampleContactRequestList[ 0 ].Id );
        emailForOpp.setToAddresses( new List<String>{ 'foobar@test.com' } );
        emailForOpp.setPlainTextBody( 'Amazing message to send' );

        // When - perform test
        System.runAs( testUser ){
            // Messaging.sendEmail requires Email Deliverability to be set to 'All Email', which is not best-practice for Sandboxes
            // Below test method verifies the two scenarios:
            // - All Email Deliverability (e.g. Production) - validate sent email is related to the specified ContactRequest
            // - Limited Deliverability (e.g. 'No access' or 'System email only') - check if specific SF Exception is thrown
            Test.startTest();
            try{
                dmlProxy.performOperation( fflib_SObjectUnitOfWork.Operations.SEND_EMAIL, new List<Object>{ emailForOpp } );
            } catch( EmailException ex ){
                System.Assert.isTrue(
                    ex.getMessage().contains( 'INSUFFICIENT_ACCESS_OR_READONLY' ) || ex.getMessage().contains( 'NO_SINGLE_MAIL_PERMISSION' ) || ex.getMessage().contains( 'NO_MASS_MAIL_PERMISSION' ),
                    'System expected an Exception to be thrown as EmailDeliverability was NOT set to \'All_Email\', which is fine. ' +
                        'Nevertheless, the thrown Exception didn\'t contain the expected INSUFFICIENT_ACCESS_OR_READONLY, NO_SINGLE_MAIL_PERMISSION or NO_MASS_MAIL_PERMISSION, but was: ' + ex.getMessage()
                );
                System.Assert.areEqual( 0, Limits.getEmailInvocations(), 'Expected no email to be sent' );
                Test.stopTest();
                return;
            }
            // Assert that an email was sent
            System.Assert.areEqual( 1, Limits.getEmailInvocations(), 'Expected one email to be invoked' );
            Test.stopTest();
        }
    }

    @IsTest
    private static void withSharingSkip_performApprovalOperation(){
        // Create mocks
        fflib_Database_IDML dmlProxy = fflib_Database.getDMLProxy( fflib_Database.Context.SHARING_SKIP_PERMISSIONS );

        // Create an approval request for the Solution
        Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
        request.setComments( 'Submitting request for approval.' );
        request.setObjectId( sampleSolutionList[ 0 ].Id );

        // Submit on behalf of a specific submitter
        request.setSubmitterId( testUser.Id );

        // Submit the record to specific process and skip the criteria evaluation
        request.setProcessDefinitionNameOrId( null );
        request.setSkipEntryCriteria( true );

        request.setNextApproverIds( new List<Id>{ testUser.Id } );

        // When - perform test
        System.runAs( testUser ){
            try{
                dmlProxy.performOperation( fflib_SObjectUnitOfWork.Operations.PROCESS_APPROVAL_PROCESS, new List<Object>{ request } );
                throw new fflib_SObjectUnitOfWork.UnitOfWorkException( 'Expected Exception as no Approval Process is setup' );
            } catch( DmlException ex ){
                System.Assert.isTrue(
                    ex.getMessage().contains( 'NO_APPLICABLE_PROCESS' ) || ex.getMessage().contains( 'INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY' ),
                    'System expected an Exception to be thrown as either no applicable processes are setup in this Org or insufficient access to the cross reference set in the ObjectId. ' +
                        'Nevertheless, the thrown Exception didn\'t contain the expected NO_APPLICABLE_PROCESS or INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY, but was: ' + ex.getMessage()
                );
                return;
            }
        }
    }

    @IsTest
    private static void withSharingSkip_invalidOperationToPerform(){
        // Create mocks
        fflib_Database_IDML dmlProxy = fflib_Database.getDMLProxy( fflib_Database.Context.SHARING_SKIP_PERMISSIONS );

        // When, Then
        System.runAs( testUser ){
            try{
                dmlProxy.performOperation( null, new List<Object>{ new Approval.ProcessSubmitRequest() } );
                throw new fflib_SObjectUnitOfWork.UnitOfWorkException( 'Expected Exception as no Approval Process is setup' );
            } catch( fflib_Database_DMLProxy.InvalidDMLActionException ex ){
                System.Assert.areEqual( 'Invalid Operation null', ex.getMessage() );
            }

            List<Object> nullResults = dmlProxy.performOperation( fflib_SObjectUnitOfWork.Operations.PROCESS_APPROVAL_PROCESS, null );
            System.Assert.isNull( nullResults );
        }
    }

    /**
     * Section focusing on testing 'without sharing' context
     */
    private static final AccessLevel withoutSharingAccessLevel = fflib_Database.getAccessLevel( fflib_Database.Context.SHARING_SKIP_PERMISSIONS );

    @IsTest
    private static void withoutSharing_shouldCorrectlyQueryWithoutBinds(){
        // Given - create data
        fflib_Database_IQuery queryProxy = fflib_Database.getQueryProxy( fflib_Database.Context.NONE );
        fflib_QueryFactory queryFactory = new fflib_QueryFactory( Solution.SObjectType );
        queryFactory.selectFields( new List<SObjectField>{
            Solution.IsPublished,
            Solution.SolutionName
        } );
        queryFactory.setOrdering( Solution.CreatedDate, fflib_QueryFactory.SortOrder.DESCENDING ); // To ensure query without filters returns the last Solution records created
        queryFactory.setLimit( SAMPLE_SIZE_SOLUTION );
        List<Solution> solutionResults = new List<Solution>();

        // When - perform test
        System.runAs( testUser ){
            solutionResults = ( List<Solution> ) queryProxy.query( queryFactory.toSOQL(), withoutSharingAccessLevel );
        }

        // Then - validate
        System.Assert.areEqual( SAMPLE_SIZE_SOLUTION, solutionResults.size() );
        System.Assert.areEqual( sampleSolutionList, solutionResults );
    }

    @IsTest
    private static void withoutSharing_shouldCorrectlyGetQueryLocatorWithoutBinds(){
        // Given - create data
        fflib_Database_IQuery queryProxy = fflib_Database.getQueryProxy( fflib_Database.Context.NONE );
        fflib_QueryFactory queryFactory = new fflib_QueryFactory( Solution.SObjectType );
        queryFactory.selectFields( new List<SObjectField>{
            Solution.IsPublished,
            Solution.SolutionName
        } );
        queryFactory.setOrdering( Solution.CreatedDate, fflib_QueryFactory.SortOrder.DESCENDING ); // To ensure query without filters returns the last Solution records created
        queryFactory.setLimit( SAMPLE_SIZE_SOLUTION );
        List<Solution> sampleSolutions = sampleSolutionList;

        // When - perform test
        System.runAs( testUser ){
            Database.QueryLocator queryLocatorResult = queryProxy.getQueryLocator( queryFactory.toSOQL(), withoutSharingAccessLevel );

            // Then - validate
            Database.QueryLocatorIterator queryLocatorIterator = queryLocatorResult.iterator(); // Get an iterator to go over the record result
            Integer ind = 0;

            // Iterate over the record set
            while( queryLocatorIterator.hasNext() ){
                Solution solutionToCompare = ( Solution ) queryLocatorIterator.next();
                Solution sampleSolution = sampleSolutions.get( ind++ );
                System.Assert.areEqual( sampleSolution.Id, solutionToCompare.Id );
                System.Assert.areEqual( sampleSolution.IsPublished, solutionToCompare.IsPublished );
                System.Assert.areEqual( sampleSolution.SolutionName, solutionToCompare.SolutionName );
            }
        }
    }

    @IsTest
    private static void withoutSharing_shouldThrowExceptionWithInvalidDMLActionForInsertUpdate(){
        // Given - create data
        fflib_Database_IDML dmlProxy = fflib_Database.getDMLProxy( fflib_Database.Context.NONE );

        // When, Then
        try{
            dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dDELETE, new List<Solution>(), new Database.DMLOptions(), withoutSharingAccessLevel );
            System.Assert.fail( 'An exception was expected due to an invalid DML action.' );
        } catch( fflib_Database_DMLProxy.InvalidDMLActionException dmlActionException ){
            System.Assert.areEqual( 'Invalid Action for DMLAction with DMLOptions ' + fflib_SObjectUnitOfWork.DMLActions.dDELETE, dmlActionException.getMessage() );
        }
    }

    @IsTest
    private static void withoutSharing_shouldThrowExceptionWithInvalidDMLActionForDeleteUndelete(){
        // Given - create data
        fflib_Database_IDML dmlProxy = fflib_Database.getDMLProxy( fflib_Database.Context.NONE );

        // When, Then
        try{
            dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dNEW, new List<Solution>(), true, withoutSharingAccessLevel );
            System.Assert.fail( 'An exception was expected due to an invalid DML action.' );
        } catch( fflib_Database_DMLProxy.InvalidDMLActionException dmlActionException ){
            System.Assert.areEqual( 'Invalid Action for DMLAction with AllOrNone Boolean ' + fflib_SObjectUnitOfWork.DMLActions.dNEW, dmlActionException.getMessage() );
        }
    }

    @IsTest
    private static void withoutSharing_shouldThrowExceptionWithInvalidDMLActionForImmediateActions(){
        // Given - create data
        fflib_Database_IDML dmlProxy = fflib_Database.getDMLProxy( fflib_Database.Context.NONE );

        // When, Then
        try{
            dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dNEW, new List<Solution>{ new Solution() }, withoutSharingAccessLevel );
            System.Assert.fail( 'An exception was expected due to an invalid DML action.' );
        } catch( fflib_Database_DMLProxy.InvalidDMLActionException dmlActionException ){
            System.Assert.areEqual( 'Invalid Action for DMLAction without additional parameters ' + fflib_SObjectUnitOfWork.DMLActions.dNEW, dmlActionException.getMessage() );
        }
    }

    @IsTest
    private static void withoutSharing_shouldCorrectlyInsertAllOrNoneDMLOptionsAndQueryWithBinds(){
        // Given - create data
        fflib_Database_IDML dmlProxy = fflib_Database.getDMLProxy( fflib_Database.Context.NONE );
        fflib_Database_IQuery queryProxy = fflib_Database.getQueryProxy( fflib_Database.Context.NONE );
        Solution testnewSolution = new Solution( SolutionName = 'test3', IsPublished = true );
        List<Solution> solutionsList = new List<Solution>{ testnewSolution };
        fflib_QueryFactory queryFactory = new fflib_QueryFactory( Solution.SObjectType );
        queryFactory.selectFields( new List<SObjectField>{
            Solution.IsPublished,
            Solution.SolutionName
        } );
        queryFactory.setCondition( 'Id IN :solutionIds' );
        Database.DMLOptions dmlOptions = new Database.DMLOptions();
        dmlOptions.optAllOrNone = true;

        // When - perform test
        System.runAs( testUser ){
            dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dNEW, solutionsList, dmlOptions, withoutSharingAccessLevel );

            Set<Id> solutionIdsSet = new Set<Id>{ testnewSolution.Id };
            Map<String, Object> bindVariablesMap = new Map<String, Object>{
                'solutionIds' => solutionIdsSet
            };
            List<Solution> solutionsResult = ( List<Solution> ) queryProxy.query( queryFactory.toSOQL(), bindVariablesMap, withoutSharingAccessLevel );

            // Then - validate
            System.Assert.areEqual( 1, solutionsResult.size() );
            System.Assert.areEqual( testnewSolution.Id, solutionsResult[ 0 ].Id );
            System.Assert.areEqual( testnewSolution.IsPublished, solutionsResult[ 0 ].IsPublished );
        }
    }

    @IsTest
    private static void withoutSharing_shouldCorrectlyUpdateDefaultDMLOptionsAndGetQueryLocatorWithBinds(){
        // Given - create data
        fflib_Database_IDML dmlProxy = fflib_Database.getDMLProxy( fflib_Database.Context.NONE );
        fflib_Database_IQuery queryProxy = fflib_Database.getQueryProxy( fflib_Database.Context.NONE );
        Solution solutionToBeUpdated = new Solution( Id = sampleSolutionList[ 0 ].Id, IsPublished = !sampleSolutionList[ 0 ].IsPublished );
        List<Solution> solutionsList = new List<Solution>{ solutionToBeUpdated };
        fflib_QueryFactory queryFactory = new fflib_QueryFactory( Solution.SObjectType );
        queryFactory.selectFields( new List<SObjectField>{
            Solution.IsPublished,
            Solution.SolutionName
        } );
        queryFactory.setCondition( 'Id IN :solutionIds' );
        List<Solution> sampleSolutions = sampleSolutionList;

        // When - perform test
        System.runAs( testUser ){
            dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dUPDATE, solutionsList, new Database.DMLOptions(), withoutSharingAccessLevel );

            Set<Id> solutionIdsSet = new Set<Id>{ solutionToBeUpdated.Id };
            Map<String, Object> bindVariablesMap = new Map<String, Object>{
                'solutionIds' => solutionIdsSet
            };
            Database.QueryLocator queryLocatorResult = queryProxy.getQueryLocator( queryFactory.toSOQL(), bindVariablesMap, withoutSharingAccessLevel );

            // Then - validate
            Database.QueryLocatorIterator queryLocatorIterator = queryLocatorResult.iterator(); // Get an iterator to go over the record result
            // Iterate over the record set
            System.Assert.isTrue( queryLocatorIterator.hasNext() );
            Solution testSolutionsUpdated = ( Solution ) queryLocatorIterator.next();
            Solution sampleSolution = ( Solution ) sampleSolutions[ 0 ];
            System.Assert.areEqual( sampleSolution.Id, testSolutionsUpdated.Id );
            System.Assert.areEqual( sampleSolution.SolutionName, testSolutionsUpdated.SolutionName );
            System.Assert.areNotEqual( sampleSolution.IsPublished, testSolutionsUpdated.IsPublished ); // Solution IsPublished should be updated with new value
            System.Assert.isFalse( queryLocatorIterator.hasNext() );
        }
    }

    @IsTest
    private static void withoutSharing_shouldCorrectlyDeleteUndeleteAndQueryWithBinds(){
        // Given - create data
        fflib_Database_IDML dmlProxy = fflib_Database.getDMLProxy( fflib_Database.Context.NONE );
        fflib_Database_IQuery queryProxy = fflib_Database.getQueryProxy( fflib_Database.Context.NONE );
        List<Solution> solutionsToBeDeleted = new List<Solution>{ sampleSolutionList[ 0 ] };
        List<Solution> solutionsToBeDeletedPrio = new List<Solution>{ sampleSolutionList[ 1 ] };
        fflib_QueryFactory queryFactory = new fflib_QueryFactory( Solution.SObjectType );
        queryFactory.selectFields( new List<SObjectField>{
            Solution.IsPublished,
            Solution.SolutionName
        } );
        queryFactory.setCondition( 'Id IN :solutionIds' );
        Boolean allOrNone = true;

        Set<Id> solutionIdsSet = new Set<Id>{ sampleSolutionList[ 0 ].Id, sampleSolutionList[ 1 ].Id };
        Map<String, Object> bindVariablesMap = new Map<String, Object>{
            'solutionIds' => solutionIdsSet
        };

        // When, Then - before deleting, verify that Solution records were correctly inserted
        System.runAs( testUser ){
            List<Solution> solutionsResult = ( List<Solution> ) queryProxy.query( queryFactory.toSOQL(), bindVariablesMap, withoutSharingAccessLevel );
            System.Assert.areEqual( 2, solutionsResult.size() );

            // When - perform test
            dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dDELETE, solutionsToBeDeleted, allOrNone, withoutSharingAccessLevel );
            dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dDELETE_PRIO, solutionsToBeDeletedPrio, allOrNone, withoutSharingAccessLevel );

            // When, Then - verify that Solution records have been deleted and are not accessible
            solutionsResult = ( List<Solution> ) queryProxy.query( queryFactory.toSOQL(), bindVariablesMap, withoutSharingAccessLevel );
            System.Assert.areEqual( 0, solutionsResult.size() );

            // When - perform test
            dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dUNDELETE, solutionsToBeDeleted, true, withoutSharingAccessLevel );
            // Remove 2nd Solution from Ids to query, since only 1st Solution was undeleted
            solutionIdsSet.remove( sampleSolutionList[ 1 ].Id );
            // When - perform test
            solutionsResult = ( List<Solution> ) queryProxy.query( queryFactory.toSOQL(), bindVariablesMap, withoutSharingAccessLevel );

            // Then - validate
            System.Assert.areEqual( 1, solutionsResult.size() );
            System.Assert.areEqual( sampleSolutionList[ 0 ].Id, solutionsResult[ 0 ].Id );
            System.Assert.areEqual( sampleSolutionList[ 0 ].SolutionName, solutionsResult[ 0 ].SolutionName );
            System.Assert.areEqual( sampleSolutionList[ 0 ].IsPublished, solutionsResult[ 0 ].IsPublished );
        }
    }

    // While Database.insertImmediate() should be used for External, Big or special Objects; Solution was used to keep the UOW project-implementation-independent
    @IsTest
    private static void withoutSharing_shouldCorrectlyInsertImmediateAndQueryWithBinds(){
        // Given - create data
        fflib_Database_IDML dmlProxy = fflib_Database.getDMLProxy( fflib_Database.Context.NONE );
        fflib_Database_IQuery queryProxy = fflib_Database.getQueryProxy( fflib_Database.Context.NONE );
        Solution testnewSolution = new Solution( SolutionName = 'test3', IsPublished = true );
        List<Solution> solutionsList = new List<Solution>{ testnewSolution };
        fflib_QueryFactory queryFactory = new fflib_QueryFactory( Solution.SObjectType );
        queryFactory.selectFields( new List<SObjectField>{
            Solution.IsPublished,
            Solution.SolutionName
        } );
        queryFactory.setCondition( 'Id IN :solutionIds' );

        // When - perform test
        System.runAs( testUser ){
            dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dNEW_IMMEDIATE, solutionsList, withoutSharingAccessLevel );

            Set<Id> solutionIdsSet = new Set<Id>{ testnewSolution.Id };
            Map<String, Object> bindVariablesMap = new Map<String, Object>{
                'solutionIds' => solutionIdsSet
            };
            List<Solution> solutionsResult = ( List<Solution> ) queryProxy.query( queryFactory.toSOQL(), bindVariablesMap, withoutSharingAccessLevel );

            // Then - validate
            System.Assert.areEqual( 1, solutionsResult.size() );
            System.Assert.areEqual( testnewSolution.Id, solutionsResult[ 0 ].Id );
            System.Assert.areEqual( testnewSolution.IsPublished, solutionsResult[ 0 ].IsPublished );
        }
    }

    // While Database.updateImmediate() should be used for External, Big or special Objects; Solution was used to keep the UOW project-implementation-independent
    @IsTest
    private static void withoutSharing_shouldCorrectlyUpdateImmediateAndQueryWithBinds(){
        // Given - create data
        fflib_Database_IDML dmlProxy = fflib_Database.getDMLProxy( fflib_Database.Context.NONE );
        fflib_Database_IQuery queryProxy = fflib_Database.getQueryProxy( fflib_Database.Context.NONE );
        Solution solutionToBeUpdated = new Solution( Id = sampleSolutionList[ 0 ].Id, IsPublished = !sampleSolutionList[ 0 ].IsPublished );
        List<Solution> solutionsList = new List<Solution>{ solutionToBeUpdated };
        fflib_QueryFactory queryFactory = new fflib_QueryFactory( Solution.SObjectType );
        queryFactory.selectFields( new List<SObjectField>{
            Solution.IsPublished,
            Solution.SolutionName
        } );
        queryFactory.setCondition( 'Id IN :solutionIds' );

        // When - perform test
        System.runAs( testUser ){
            dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dUPDATE_IMMEDIATE, solutionsList, withoutSharingAccessLevel );

            Set<Id> solutionIdsSet = new Set<Id>{ solutionToBeUpdated.Id };
            Map<String, Object> bindVariablesMap = new Map<String, Object>{
                'solutionIds' => solutionIdsSet
            };
            List<Solution> solutionsResult = ( List<Solution> ) queryProxy.query( queryFactory.toSOQL(), bindVariablesMap, withoutSharingAccessLevel );

            // Then - validate
            System.Assert.areEqual( 1, solutionsResult.size() );
            System.Assert.areEqual( sampleSolutionList[ 0 ].Id, solutionsResult[ 0 ].Id );
            System.Assert.areEqual( sampleSolutionList[ 0 ].SolutionName, solutionsResult[ 0 ].SolutionName );
            System.Assert.areNotEqual( sampleSolutionList[ 0 ].IsPublished, solutionsResult[ 0 ].IsPublished );
            System.Assert.areEqual( solutionToBeUpdated.IsPublished, solutionsResult[ 0 ].IsPublished );
        }
    }

    @IsTest
    private static void withoutSharing_shouldCorrectlyDeleteImmediatelyAndEmptyRecycleBin(){
        // Given - create data
        fflib_Database_IDML dmlProxy = fflib_Database.getDMLProxy( fflib_Database.Context.NONE );
        fflib_Database_IQuery queryProxy = fflib_Database.getQueryProxy( fflib_Database.Context.NONE );
        List<Solution> solutionsToBeDeleted = new List<Solution>{ sampleSolutionList[ 0 ] };
        fflib_QueryFactory queryFactory = new fflib_QueryFactory( Solution.SObjectType );
        queryFactory.selectFields( new List<SObjectField>{
            Solution.IsPublished,
            Solution.SolutionName
        } );
        queryFactory.setCondition( 'Id IN :solutionIds' );

        Set<Id> solutionIdsSet = new Set<Id>{ sampleSolutionList[ 0 ].Id };
        Map<String, Object> bindVariablesMap = new Map<String, Object>{
            'solutionIds' => solutionIdsSet
        };

        // When - verify before deleting that Solution exists
        System.runAs( testUser ){
            List<Solution> solutionsResult = ( List<Solution> ) queryProxy.query( queryFactory.toSOQL(), bindVariablesMap, withoutSharingAccessLevel );

            // Then - validate
            System.Assert.areEqual( 1, solutionsResult.size() );
            System.Assert.areEqual( sampleSolutionList[ 0 ].Id, solutionsResult[ 0 ].Id );
            System.Assert.areEqual( sampleSolutionList[ 0 ].SolutionName, solutionsResult[ 0 ].SolutionName );
            System.Assert.areEqual( sampleSolutionList[ 0 ].IsPublished, solutionsResult[ 0 ].IsPublished );

            // When - perform test
            dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dDELETE_IMMEDIATE, solutionsToBeDeleted, withoutSharingAccessLevel );

            // When, Then - verify after deletion that Solution no longer exists
            solutionsResult = ( List<Solution> ) queryProxy.query( queryFactory.toSOQL(), bindVariablesMap, withoutSharingAccessLevel );
            System.Assert.areEqual( 0, solutionsResult.size() );

            // When, Then - setting ALL ROWS to true, Solution should be accessible still
            queryFactory.setAllRowsRequired( true );
            solutionsResult = ( List<Solution> ) queryProxy.query( queryFactory.toSOQL(), bindVariablesMap, withoutSharingAccessLevel );
            System.Assert.areEqual( 1, solutionsResult.size() );

            // Empty RecycleBin
            dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dEMPTY_RECBIN, solutionsToBeDeleted, withoutSharingAccessLevel );
            // When, Then - setting ALL ROWS to true, Solution record can no longer be undeleted
            try{
                dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dUNDELETE, solutionsToBeDeleted, true, withoutSharingAccessLevel );
                System.Assert.fail( 'Expected DmlException exception. This assertion should never be triggered' );
            } catch( DmlException ex ){
                System.Assert.areEqual( 'Undelete failed. First exception on row 0 with id ' + solutionsToBeDeleted[ 0 ].Id + '; first error: UNDELETE_FAILED, Entity is not in the recycle bin: []', ex.getMessage() );
            }
        }
    }

    /**
     * As per Summer'24 (API v61.0), EventBus.publish(SObject event) returns a System.UnexpectedException when attempting to publish an SObject that represents an object that isn’t a platform event.
     * Therefore, only standard PlatformEvent or project-specific CustomEvent can be specified (though not being able to rely on)
     * Hence, covering as much lines as possible and ensuring those parts of code behave as expected
     */
    @IsTest
    private static void withoutSharing_shouldPublishBeforeAfterTransactionWithNoResults(){
        // Given - create data
        fflib_Database_IDML dmlProxy = fflib_Database.getDMLProxy( fflib_Database.Context.NONE );
        List<BatchApexErrorEvent> eventList = new List<BatchApexErrorEvent>{ new BatchApexErrorEvent() };

        // When - perform test
        System.runAs( testUser ){
            Test.startTest();
            List<Database.SaveResult> publishResultBeforeResult = ( List<Database.SaveResult> ) dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dPUB_BEFORE, eventList, withoutSharingAccessLevel );
            List<Database.SaveResult> publishResultAfterSuccessResult = ( List<Database.SaveResult> ) dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dPUB_AFTER_SUCCESS, eventList, withoutSharingAccessLevel );
            List<Database.SaveResult> publishResultAfterFailureResult = ( List<Database.SaveResult> ) dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dPUB_AFTER_FAILURE, eventList, withoutSharingAccessLevel );
            Test.stopTest();

            // Then - publish results should return 1 Object for each of the Publish actions
            System.Assert.areEqual( 1, publishResultBeforeResult.size() );
            System.Assert.areEqual( 1, publishResultAfterSuccessResult.size() );
            System.Assert.areEqual( 1, publishResultAfterFailureResult.size() );

            // dPUB_BEFORE: org-dependent — OPERATION_ENQUEUED (success=true) when platform event delivery is enabled,
            // or a failure status when BatchApexErrorEvent publish is restricted in this org context
            List<Database.Error> dmlErrors = publishResultBeforeResult[ 0 ].getErrors();
            System.Assert.isFalse( dmlErrors.isEmpty(), 'Expected at least one error/status code in publishResultBeforeResult' );

            // dPUB_AFTER_SUCCESS / dPUB_AFTER_FAILURE: org-dependent — INVALID_FIELD_FOR_INSERT_UPDATE when the event
            // already carries an ID from a prior publish, or CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY in some org configurations
            System.Assert.isFalse( publishResultAfterSuccessResult[ 0 ].isSuccess() );
            System.Assert.isFalse( publishResultAfterSuccessResult[ 0 ].getErrors().isEmpty() );
            dmlErrors = publishResultAfterSuccessResult[ 0 ].getErrors();
            System.Assert.isTrue(
                dmlErrors[ 0 ].getStatusCode() == System.StatusCode.INVALID_FIELD_FOR_INSERT_UPDATE ||
                dmlErrors[ 0 ].getStatusCode() == System.StatusCode.CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY,
                'Expected INVALID_FIELD_FOR_INSERT_UPDATE or CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY for dPUB_AFTER_SUCCESS, got: ' + dmlErrors[ 0 ].getStatusCode()
            );

            System.Assert.isFalse( publishResultAfterFailureResult[ 0 ].isSuccess() );
            System.Assert.isFalse( publishResultAfterFailureResult[ 0 ].getErrors().isEmpty() );
            dmlErrors = publishResultAfterFailureResult[ 0 ].getErrors();
            System.Assert.isTrue(
                dmlErrors[ 0 ].getStatusCode() == System.StatusCode.INVALID_FIELD_FOR_INSERT_UPDATE ||
                dmlErrors[ 0 ].getStatusCode() == System.StatusCode.CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY,
                'Expected INVALID_FIELD_FOR_INSERT_UPDATE or CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY for dPUB_AFTER_FAILURE, got: ' + dmlErrors[ 0 ].getStatusCode()
            );
        }
    }

    @IsTest
    private static void withoutSharing_noDMLActionToBePerformed(){
        // Given - create data
        fflib_Database_IDML dmlProxy = fflib_Database.getDMLProxy( fflib_Database.Context.NONE );
        List<Solution> solutionsList = new List<Solution>(); // This should cause no DML actions to be performed in empty list of Objects

        // When - perform test
        System.runAs( testUser ){
            List<Object> dmlResult = dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dPUB_BEFORE, solutionsList, withoutSharingAccessLevel );

            // Then - validate
            System.Assert.isNull( dmlResult );
        }
    }

    @IsTest
    private static void withoutSharing_performEmailOperation(){
        // Create mocks
        fflib_Database_IDML dmlProxy = fflib_Database.getDMLProxy( fflib_Database.Context.NONE );

        // Given - create data
        Messaging.SingleEmailMessage emailForOpp = new Messaging.SingleEmailMessage();
        emailForOpp.setWhatId( sampleContactRequestList[ 0 ].Id );
        emailForOpp.setToAddresses( new List<String>{ 'foobar@test.com' } );
        emailForOpp.setPlainTextBody( 'Amazing message to send' );

        // When - perform test
        System.runAs( testUser ){
            // Messaging.sendEmail requires Email Deliverability to be set to 'All Email', which is not best-practice for Sandboxes
            // Below test method verifies the two scenarios:
            // - All Email Deliverability (e.g. Production) - validate sent email is related to the specified ContactRequest
            // - Limited Deliverability (e.g. 'No access' or 'System email only') - check if specific SF Exception is thrown
            Test.startTest();
            try{
                dmlProxy.performOperation( fflib_SObjectUnitOfWork.Operations.SEND_EMAIL, new List<Object>{ emailForOpp } );
            } catch( EmailException ex ){
                System.Assert.isTrue(
                    ex.getMessage().contains( 'INSUFFICIENT_ACCESS_OR_READONLY' ) || ex.getMessage().contains( 'NO_SINGLE_MAIL_PERMISSION' ) || ex.getMessage().contains( 'NO_MASS_MAIL_PERMISSION' ),
                    'System expected an Exception to be thrown as EmailDeliverability was NOT set to \'All_Email\', which is fine. ' +
                        'Nevertheless, the thrown Exception didn\'t contain the expected INSUFFICIENT_ACCESS_OR_READONLY, NO_SINGLE_MAIL_PERMISSION or NO_MASS_MAIL_PERMISSION, but was: ' + ex.getMessage()
                );
                System.Assert.areEqual( 0, Limits.getEmailInvocations(), 'Expected no email to be sent' );
                Test.stopTest();
                return;
            }
        }

        // Assert that an email was sent
        System.Assert.areEqual( 1, Limits.getEmailInvocations(), 'Expected one email to be invoked' );
        Test.stopTest();
    }

    @IsTest
    private static void withoutSharing_performApprovalOperation(){
        // Create mocks
        fflib_Database_IDML dmlProxy = fflib_Database.getDMLProxy( fflib_Database.Context.NONE );

        // Create an approval request for the Solution
        Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
        request.setComments( 'Submitting request for approval.' );
        request.setObjectId( sampleSolutionList[ 0 ].Id );

        // Submit on behalf of a specific submitter
        request.setSubmitterId( testUser.Id );

        // Submit the record to specific process and skip the criteria evaluation
        request.setProcessDefinitionNameOrId( null );
        request.setSkipEntryCriteria( true );

        request.setNextApproverIds( new List<Id>{ testUser.Id } );

        // When - perform test
        System.runAs( testUser ){
            try{
                dmlProxy.performOperation( fflib_SObjectUnitOfWork.Operations.PROCESS_APPROVAL_PROCESS, new List<Object>{ request } );
                throw new fflib_SObjectUnitOfWork.UnitOfWorkException( 'Expected Exception as no Approval Process is setup' );
            } catch( DmlException ex ){
                System.Assert.isTrue(
                    ex.getMessage().contains( 'NO_APPLICABLE_PROCESS' ) || ex.getMessage().contains( 'INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY' ),
                    'System expected an Exception to be thrown as either no applicable processes are setup in this Org or insufficient access to the cross reference set in the ObjectId. ' +
                        'Nevertheless, the thrown Exception didn\'t contain the expected NO_APPLICABLE_PROCESS or INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY, but was: ' + ex.getMessage()
                );
                return;
            }
        }
    }

    @IsTest
    private static void withoutSharing_invalidOperationToPerform(){
        // Create mocks
        fflib_Database_IDML dmlProxy = fflib_Database.getDMLProxy( fflib_Database.Context.NONE );

        // When, Then
        System.runAs( testUser ){
            try{
                dmlProxy.performOperation( null, new List<Object>{ new Approval.ProcessSubmitRequest() } );
                throw new fflib_SObjectUnitOfWork.UnitOfWorkException( 'Expected Exception as no Approval Process is setup' );
            } catch( fflib_Database_DMLProxy.InvalidDMLActionException ex ){
                System.Assert.areEqual( 'Invalid Operation null', ex.getMessage() );
            }

            List<Object> nullResults = dmlProxy.performOperation( fflib_SObjectUnitOfWork.Operations.PROCESS_APPROVAL_PROCESS, null );
            System.Assert.isNull( nullResults );
        }
    }

    /**
     * Section focusing on testing 'inherited sharing' context.
     * Since this class respects sharing rules (aka "with sharing"), sharing settings should be enforced upon the test user context, presenting similar results to {@link fflib_Database.Context.SHARING_SKIP_PERMISSIONS}
     */
    private static final AccessLevel inheritedAccessLevel = fflib_Database.getAccessLevel( fflib_Database.Context.INHERIT );

    @IsTest
    private static void inheritedSharing_shouldCorrectlyQueryWithoutBinds(){
        // Given - create data
        fflib_Database_IQuery queryProxy = fflib_Database.getQueryProxy( fflib_Database.Context.INHERIT );
        fflib_QueryFactory queryFactory = new fflib_QueryFactory( Solution.SObjectType );
        queryFactory.selectFields( new List<SObjectField>{
            Solution.IsPublished,
            Solution.SolutionName
        } );
        queryFactory.setOrdering( Solution.CreatedDate, fflib_QueryFactory.SortOrder.DESCENDING ); // To ensure query without filters returns the last Solution records created
        queryFactory.setLimit( SAMPLE_SIZE_SOLUTION );
        List<Solution> solutionResults = new List<Solution>();

        // When - perform test
        System.runAs( testUser ){
            solutionResults = ( List<Solution> ) queryProxy.query( queryFactory.toSOQL(), inheritedAccessLevel );
        }

        // Then - validate
        System.Assert.areEqual(
            ( isPrivateSolutionInternalSharing ? 0 : SAMPLE_SIZE_SOLUTION ), // If the internal sharing mode for Solution is private, expect no records shared.
            solutionResults.size()
        );
    }

    @IsTest
    private static void inheritedSharing_shouldCorrectlyGetQueryLocatorWithoutBinds(){
        // Given - create data
        fflib_Database_IQuery queryProxy = fflib_Database.getQueryProxy( fflib_Database.Context.INHERIT );
        fflib_QueryFactory queryFactory = new fflib_QueryFactory( Solution.SObjectType );
        queryFactory.selectFields( new List<SObjectField>{
            Solution.IsPublished,
            Solution.SolutionName
        } );
        queryFactory.setOrdering( Solution.CreatedDate, fflib_QueryFactory.SortOrder.DESCENDING ); // To ensure query without filters returns the last Solution records created
        queryFactory.setLimit( SAMPLE_SIZE_SOLUTION );
        List<Solution> sampleSolutions = sampleSolutionList;

        // When - perform test
        System.runAs( testUser ){
            Database.QueryLocator queryLocatorResult = queryProxy.getQueryLocator( queryFactory.toSOQL(), inheritedAccessLevel );

            // Then - validate
            Database.QueryLocatorIterator queryLocatorIterator = queryLocatorResult.iterator(); // Get an iterator to go over the record result
            Integer ind = 0;

            // Iterate over the record set
            while( queryLocatorIterator.hasNext() ){
                Solution solutionToCompare = ( Solution ) queryLocatorIterator.next();
                Solution sampleSolution = sampleSolutions.get( ind++ );
                System.Assert.areEqual( sampleSolution.Id, solutionToCompare.Id );
                System.Assert.areEqual( sampleSolution.IsPublished, solutionToCompare.IsPublished );
                System.Assert.areEqual( sampleSolution.SolutionName, solutionToCompare.SolutionName );
            }
        }
    }

    @IsTest
    private static void inheritedSharing_shouldThrowExceptionWithInvalidDMLActionForInsertUpdate(){
        // Given - create data
        fflib_Database_IDML dmlProxy = fflib_Database.getDMLProxy( fflib_Database.Context.INHERIT );

        // When, Then
        try{
            dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dDELETE, new List<Solution>(), new Database.DMLOptions(), inheritedAccessLevel );
            System.Assert.fail( 'An exception was expected due to an invalid DML action.' );
        } catch( fflib_Database_DMLProxy.InvalidDMLActionException dmlActionException ){
            System.Assert.areEqual( 'Invalid Action for DMLAction with DMLOptions ' + fflib_SObjectUnitOfWork.DMLActions.dDELETE, dmlActionException.getMessage() );
        }
    }

    @IsTest
    private static void inheritedSharing_shouldThrowExceptionWithInvalidDMLActionForDeleteUndelete(){
        // Given - create data
        fflib_Database_IDML dmlProxy = fflib_Database.getDMLProxy( fflib_Database.Context.INHERIT );

        // When, Then
        try{
            dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dNEW, new List<Solution>(), true, inheritedAccessLevel );
            System.Assert.fail( 'An exception was expected due to an invalid DML action.' );
        } catch( fflib_Database_DMLProxy.InvalidDMLActionException dmlActionException ){
            System.Assert.areEqual( 'Invalid Action for DMLAction with AllOrNone Boolean ' + fflib_SObjectUnitOfWork.DMLActions.dNEW, dmlActionException.getMessage() );
        }
    }

    @IsTest
    private static void inheritedSharing_shouldThrowExceptionWithInvalidDMLActionForImmediateActions(){
        // Given - create data
        fflib_Database_IDML dmlProxy = fflib_Database.getDMLProxy( fflib_Database.Context.INHERIT );

        // When, Then
        try{
            dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dNEW, new List<Solution>{ new Solution() }, inheritedAccessLevel );
            System.Assert.fail( 'An exception was expected due to an invalid DML action.' );
        } catch( fflib_Database_DMLProxy.InvalidDMLActionException dmlActionException ){
            System.Assert.areEqual( 'Invalid Action for DMLAction without additional parameters ' + fflib_SObjectUnitOfWork.DMLActions.dNEW, dmlActionException.getMessage() );
        }
    }

    // Testing dNEW/dUPDATE/dDELETE actions in sequence, as well as dEMPTY_RECBIN and dUNDELETE for completeness. Database queries performed using QueryLocator interface
    @IsTest
    private static void inheritedSharing_shouldCorrectlyInsertUpdateDeleteAndGetQueryLocatorWithBinds(){
        // Given - create data
        fflib_Database_IDML dmlProxy = fflib_Database.getDMLProxy( fflib_Database.Context.INHERIT );
        fflib_Database_IQuery queryProxy = fflib_Database.getQueryProxy( fflib_Database.Context.INHERIT );
        Solution testSolution = new Solution( SolutionName = 'TestName3', IsPublished = true );
        List<Solution> solutionsList = new List<Solution>{ testSolution };
        fflib_QueryFactory queryFactory = new fflib_QueryFactory( Solution.SObjectType );
        queryFactory.selectFields( new List<SObjectField>{
            Solution.IsPublished,
            Solution.SolutionName
        } );
        queryFactory.setCondition( 'Id IN :solutionIds' );

        Set<Id> solutionIdsSet = new Set<Id>{ testSolution.Id };
        Map<String, Object> bindVariablesMap = new Map<String, Object>{
            'solutionIds' => solutionIdsSet
        };
        Database.DMLOptions dmlOptions = new Database.DMLOptions();
        Boolean allOrNone = true;

        // 1st, insert Solution record and set Owner as running test user. This will allow proper testing of DML actions in records that are visible/shared with the test user
        System.runAs( testUser ){
            List<Database.SaveResult> insertDMLResult = ( List<Database.SaveResult> ) dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dNEW, solutionsList, dmlOptions, inheritedAccessLevel );

            // Assert that the Solution record to be updated was correctly inserted
            System.Assert.areEqual( 1, insertDMLResult.size() );
            System.Assert.isTrue( insertDMLResult[ 0 ].isSuccess() );

            // Update Message field
            Solution testSolutionUpdated = new Solution( Id = testSolution.Id, IsPublished = !testSolution.IsPublished );
            solutionIdsSet = new Set<Id>{ testSolutionUpdated.Id };
            bindVariablesMap = new Map<String, Object>{ 'solutionIds' => solutionIdsSet };

            // When - perform dUPDATE on newly created Solution record. This should succeed, bypassing the CRUD restrictions imposed to the test user
            dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dUPDATE, new List<Solution>{ testSolutionUpdated }, dmlOptions, inheritedAccessLevel );

            // Get the updated record from the database and assert
            Database.QueryLocator queryLocatorResult = queryProxy.getQueryLocator( queryFactory.toSOQL(), bindVariablesMap, inheritedAccessLevel );

            // Then - validate
            Database.QueryLocatorIterator queryLocatorIterator = queryLocatorResult.iterator(); // Get an iterator to go over the record result
            // Iterate over the record set
            System.Assert.isTrue( queryLocatorIterator.hasNext() );
            Solution testSolutionsUpdated = ( Solution ) queryLocatorIterator.next();

            System.Assert.areEqual( testSolution.Id, testSolutionsUpdated.Id );
            System.Assert.areNotEqual( testSolution.IsPublished, testSolutionsUpdated.IsPublished ); // Solution IsPublished should be updated with new value
            System.Assert.areEqual( testSolutionUpdated.IsPublished, testSolutionsUpdated.IsPublished );
            System.Assert.areEqual( testSolution.SolutionName, testSolutionsUpdated.SolutionName );

            System.Assert.isFalse( queryLocatorIterator.hasNext() );

            // When - perform dDELETE on Solution test record. This should succeed, bypassing the CRUD restrictions imposed to the test user
            dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dDELETE, solutionsList, allOrNone, inheritedAccessLevel );

            // When, Then - verify after deletion that Solution no longer exists
            List<Solution> solutionsDeleteResult = ( List<Solution> ) queryProxy.query( queryFactory.toSOQL(), bindVariablesMap, inheritedAccessLevel );
            System.Assert.areEqual( 0, solutionsDeleteResult.size() );

            // Empty RecycleBin
            List<Database.EmptyRecycleBinResult> emptyEmptyRecycleBinResults =
                ( List<Database.EmptyRecycleBinResult> ) dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dEMPTY_RECBIN, solutionsList, inheritedAccessLevel );
            // Verify that the recycle bin operation succeeded
            System.Assert.areEqual( 1, emptyEmptyRecycleBinResults.size() );
            System.Assert.isTrue( emptyEmptyRecycleBinResults[ 0 ].isSuccess() );
            System.Assert.areEqual( emptyEmptyRecycleBinResults[ 0 ].id, testSolution.Id );

            // When, Then - Solution record can no longer be undeleted
            try{
                dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dUNDELETE, solutionsList, true, inheritedAccessLevel );
                System.Assert.fail( 'Expected DmlException exception. This assertion should never be triggered' );
            } catch( DmlException ex ){
                System.Assert.areEqual( 'Undelete failed. First exception on row 0 with id ' + solutionsList[ 0 ].Id + '; first error: UNDELETE_FAILED, Entity is not in the recycle bin: []', ex.getMessage() );
            }
        }
    }

    // Testing dNEW_PRIO/dUPDATE_PRIO/dDELETE_PRIO actions in sequence, as well as dEMPTY_RECBIN and dUNDELETE for completeness
    @IsTest
    private static void inheritedSharing_shouldCorrectlyInsertUpdateDeletePrioAndQueryWithBinds(){
        // Given - create data
        fflib_Database_IDML dmlProxy = fflib_Database.getDMLProxy( fflib_Database.Context.INHERIT );
        fflib_Database_IQuery queryProxy = fflib_Database.getQueryProxy( fflib_Database.Context.INHERIT );
        Solution testSolution = new Solution( SolutionName = 'TestName3', IsPublished = true );
        List<Solution> solutionsList = new List<Solution>{ testSolution };
        fflib_QueryFactory queryFactory = new fflib_QueryFactory( Solution.SObjectType );
        queryFactory.selectFields( new List<SObjectField>{
            Solution.IsPublished,
            Solution.SolutionName
        } );
        queryFactory.setCondition( 'Id IN :solutionIds' );

        Set<Id> solutionIdsSet = new Set<Id>{ testSolution.Id };
        Map<String, Object> bindVariablesMap = new Map<String, Object>{
            'solutionIds' => solutionIdsSet
        };
        List<Solution> solutionsResult = new List<Solution>();
        Database.DMLOptions dmlOptions = new Database.DMLOptions();
        Boolean allOrNone = true;

        // 1st, insert Solution record and set Owner as running test user. This will allow proper testing of DML actions in records that are visible/shared with the test user
        System.runAs( testUser ){
            List<Database.SaveResult> insertDMLResult = ( List<Database.SaveResult> ) dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dNEW_PRIO, solutionsList, dmlOptions, inheritedAccessLevel );

            // Assert that the Solution record to be updated was correctly inserted
            System.Assert.areEqual( 1, insertDMLResult.size() );
            System.Assert.isTrue( insertDMLResult[ 0 ].isSuccess() );

            // Update Message field
            Solution testSolutionUpdated = new Solution( Id = testSolution.Id, IsPublished = !testSolution.IsPublished );
            solutionIdsSet = new Set<Id>{ testSolutionUpdated.Id };
            bindVariablesMap = new Map<String, Object>{ 'solutionIds' => solutionIdsSet };

            // When - perform dUPDATE_PRIO on newly created Solution record. This should succeed, bypassing the CRUD restrictions imposed to the test user
            dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dUPDATE_PRIO, new List<Solution>{ testSolutionUpdated }, dmlOptions, inheritedAccessLevel );

            solutionsResult = ( List<Solution> ) queryProxy.query( queryFactory.toSOQL(), bindVariablesMap, inheritedAccessLevel );

            // Verify that the Solution was correctly updated
            System.Assert.areEqual( 1, solutionsResult.size() );
            Solution testSolutionsUpdated = solutionsResult[ 0 ];

            System.Assert.areEqual( testSolution.Id, testSolutionsUpdated.Id );
            System.Assert.areNotEqual( testSolution.IsPublished, testSolutionsUpdated.IsPublished ); // Solution IsPublished should be updated with new value
            System.Assert.areEqual( testSolutionUpdated.IsPublished, testSolutionsUpdated.IsPublished );
            System.Assert.areEqual( testSolution.SolutionName, testSolutionsUpdated.SolutionName );

            // When - perform dDELETE_PRIO on Solution test record. This should succeed, bypassing the CRUD restrictions imposed to the test user
            dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dDELETE_PRIO, solutionsList, allOrNone, inheritedAccessLevel );

            // When, Then - verify after deletion that Solution no longer exists
            List<Solution> solutionsDeleteResult = ( List<Solution> ) queryProxy.query( queryFactory.toSOQL(), bindVariablesMap, inheritedAccessLevel );
            System.Assert.areEqual( 0, solutionsDeleteResult.size() );

            // Empty RecycleBin
            List<Database.EmptyRecycleBinResult> emptyEmptyRecycleBinResults =
                ( List<Database.EmptyRecycleBinResult> ) dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dEMPTY_RECBIN, solutionsList, inheritedAccessLevel );
            // Verify that the recycle bin operation succeeded
            System.Assert.areEqual( 1, emptyEmptyRecycleBinResults.size() );
            System.Assert.isTrue( emptyEmptyRecycleBinResults[ 0 ].isSuccess() );
            System.Assert.areEqual( emptyEmptyRecycleBinResults[ 0 ].id, testSolution.Id );

            // When, Then - Solution record can no longer be undeleted
            try{
                dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dUNDELETE, solutionsList, true, inheritedAccessLevel );
                System.Assert.fail( 'Expected DmlException exception. This assertion should never be triggered' );
            } catch( DmlException ex ){
                System.Assert.areEqual( 'Undelete failed. First exception on row 0 with id ' + solutionsList[ 0 ].Id + '; first error: UNDELETE_FAILED, Entity is not in the recycle bin: []', ex.getMessage() );
            }
        }
    }

    // While Database.insertImmediate()/updateImmediate()/deleteImmediate() should be used for External, Big or special Objects; Solution was used to keep the UOW project-implementation-independent
    // Testing dNEW_IMMEDIATE/dUPDATE_IMMEDIATE/dDELETE_IMMEDIATE actions in sequence, as well as dEMPTY_RECBIN and dUNDELETE for completeness
    @IsTest
    private static void inheritedSharing_shouldCorrectlyInsertUpdateDeleteImmediateAndQueryWithBinds(){
        // Given - create data
        fflib_Database_IDML dmlProxy = fflib_Database.getDMLProxy( fflib_Database.Context.INHERIT );
        fflib_Database_IQuery queryProxy = fflib_Database.getQueryProxy( fflib_Database.Context.INHERIT );
        Solution testSolution = new Solution( SolutionName = 'TestName3', IsPublished = true );
        List<Solution> solutionsList = new List<Solution>{ testSolution };
        fflib_QueryFactory queryFactory = new fflib_QueryFactory( Solution.SObjectType );
        queryFactory.selectFields( new List<SObjectField>{
            Solution.IsPublished,
            Solution.SolutionName
        } );
        queryFactory.setCondition( 'Id IN :solutionIds' );

        Set<Id> solutionIdsSet = new Set<Id>{ testSolution.Id };
        Map<String, Object> bindVariablesMap = new Map<String, Object>{
            'solutionIds' => solutionIdsSet
        };
        List<Solution> solutionsResult = new List<Solution>();

        // 1st, insert Solution record and set Owner as running test user. This will allow proper testing of DML actions in records that are visible/shared with the test user
        System.runAs( testUser ){
            List<Database.SaveResult> insertDMLResult = ( List<Database.SaveResult> ) dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dNEW_IMMEDIATE, solutionsList, inheritedAccessLevel );

            // Assert that the Solution record to be updated was correctly inserted
            System.Assert.areEqual( 1, insertDMLResult.size() );
            System.Assert.isTrue( insertDMLResult[ 0 ].isSuccess() );

            // Update Message field
            Solution testSolutionUpdated = new Solution( Id = testSolution.Id, IsPublished = !testSolution.IsPublished );
            solutionIdsSet = new Set<Id>{ testSolutionUpdated.Id };
            bindVariablesMap = new Map<String, Object>{ 'solutionIds' => solutionIdsSet };

            // When - perform dUPDATE_IMMEDIATE on newly created Solution record. This should succeed, bypassing the CRUD restrictions imposed to the test user
            dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dUPDATE_IMMEDIATE, new List<Solution>{ testSolutionUpdated }, inheritedAccessLevel );

            solutionsResult = ( List<Solution> ) queryProxy.query( queryFactory.toSOQL(), bindVariablesMap, inheritedAccessLevel );

            // Verify that the Solution was correctly updated
            System.Assert.areEqual( 1, solutionsResult.size() );
            Solution testSolutionsUpdated = solutionsResult[ 0 ];

            System.Assert.areEqual( testSolution.Id, testSolutionsUpdated.Id );
            System.Assert.areNotEqual( testSolution.IsPublished, testSolutionsUpdated.IsPublished ); // Solution IsPublished should be updated with new value
            System.Assert.areEqual( testSolutionUpdated.IsPublished, testSolutionsUpdated.IsPublished );
            System.Assert.areEqual( testSolution.SolutionName, testSolutionsUpdated.SolutionName );

            // When - perform dDELETE_IMMEDIATE on Solution test record. This should succeed, bypassing the CRUD restrictions imposed to the test user
            dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dDELETE_IMMEDIATE, solutionsList, inheritedAccessLevel );

            // When, Then - verify after deletion that Solution no longer exists
            List<Solution> solutionsDeleteResult = ( List<Solution> ) queryProxy.query( queryFactory.toSOQL(), bindVariablesMap, inheritedAccessLevel );
            System.Assert.areEqual( 0, solutionsDeleteResult.size() );

            // Empty RecycleBin
            List<Database.EmptyRecycleBinResult> emptyEmptyRecycleBinResults =
                ( List<Database.EmptyRecycleBinResult> ) dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dEMPTY_RECBIN, solutionsList, inheritedAccessLevel );
            // Verify that the recycle bin operation succeeded
            System.Assert.areEqual( 1, emptyEmptyRecycleBinResults.size() );
            System.Assert.isTrue( emptyEmptyRecycleBinResults[ 0 ].isSuccess() );
            System.Assert.areEqual( emptyEmptyRecycleBinResults[ 0 ].id, testSolution.Id );

            // When, Then - Solution record can no longer be undeleted
            try{
                dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dUNDELETE, solutionsList, true, inheritedAccessLevel );
                System.Assert.fail( 'Expected DmlException exception. This assertion should never be triggered' );
            } catch( DmlException ex ){
                System.Assert.areEqual( 'Undelete failed. First exception on row 0 with id ' + solutionsList[ 0 ].Id + '; first error: UNDELETE_FAILED, Entity is not in the recycle bin: []', ex.getMessage() );
            }
        }
    }

    /**
     * As per Summer'24 (API v61.0), EventBus.publish(SObject event) returns a System.UnexpectedException when attempting to publish an SObject that represents an object that isn’t a platform event.
     * Therefore, only standard PlatformEvent or project-specific CustomEvent can be specified (though not being able to rely on)
     * Hence, covering as much lines as possible and ensuring those parts of code behave as expected
     */
    @IsTest
    private static void inheritedSharing_shouldPublishBeforeAfterTransactionWithNoResults(){
        // Given - create data
        fflib_Database_IDML dmlProxy = fflib_Database.getDMLProxy( fflib_Database.Context.INHERIT );
        List<BatchApexErrorEvent> eventList = new List<BatchApexErrorEvent>{ new BatchApexErrorEvent() };

        // When - perform test
        System.runAs( testUser ){
            Test.startTest();
            try{
                List<Database.SaveResult> publishResultBeforeResult = ( List<Database.SaveResult> ) dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dPUB_BEFORE, eventList, inheritedAccessLevel );
            } catch( Exception typeException ){
                // Then - validate
                System.Assert.isInstanceOfType( typeException, System.TypeException.class, 'Expected an System.TypeException, got ' + typeException.getTypeName() );
                System.Assert.areEqual( 'DML operation INSERT not allowed on BatchApexErrorEvent', typeException.getMessage() );
            }

            try{
                List<Database.SaveResult> publishResultAfterSuccessResult = ( List<Database.SaveResult> ) dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dPUB_AFTER_SUCCESS, eventList, inheritedAccessLevel );
            } catch( Exception typeException ){
                // Then - validate
                System.Assert.isInstanceOfType( typeException, System.TypeException.class, 'Expected an System.TypeException, got ' + typeException.getTypeName() );
                System.Assert.areEqual( 'DML operation INSERT not allowed on BatchApexErrorEvent', typeException.getMessage() );
            }

            try{
                List<Database.SaveResult> publishResultAfterFailureResult = ( List<Database.SaveResult> ) dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dPUB_AFTER_FAILURE, eventList, inheritedAccessLevel );
            } catch( Exception typeException ){
                // Then - validate
                System.Assert.isInstanceOfType( typeException, System.TypeException.class, 'Expected an System.TypeException, got ' + typeException.getTypeName() );
                System.Assert.areEqual( 'DML operation INSERT not allowed on BatchApexErrorEvent', typeException.getMessage() );
            }
            Test.stopTest();
        }
    }

    @IsTest
    private static void inheritedSharing_noDMLActionToBePerformed(){
        // Given - create data
        fflib_Database_IDML dmlProxy = fflib_Database.getDMLProxy( fflib_Database.Context.INHERIT );
        List<Solution> solutionsList = new List<Solution>(); // This should cause no DML actions to be performed in empty list of Objects

        // When - perform test
        System.runAs( testUser ){
            List<Object> dmlResult = dmlProxy.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dPUB_BEFORE, solutionsList, inheritedAccessLevel );

            // Then - validate
            System.Assert.isNull( dmlResult );
        }
    }

    @IsTest
    private static void inheritedSharing_performEmailOperation(){
        // Create mocks
        fflib_Database_IDML dmlProxy = fflib_Database.getDMLProxy( fflib_Database.Context.INHERIT );

        // Given - create data
        Messaging.SingleEmailMessage emailForOpp = new Messaging.SingleEmailMessage();
        emailForOpp.setWhatId( sampleContactRequestList[ 0 ].Id );
        emailForOpp.setToAddresses( new List<String>{ 'foobar@test.com' } );
        emailForOpp.setPlainTextBody( 'Amazing message to send' );

        // When - perform test
        System.runAs( testUser ){
            // Messaging.sendEmail requires Email Deliverability to be set to 'All Email', which is not best-practice for Sandboxes
            // Below test method verifies the two scenarios:
            // - All Email Deliverability (e.g. Production) - validate sent email is related to the specified ContactRequest
            // - Limited Deliverability (e.g. 'No access' or 'System email only') - check if specific SF Exception is thrown
            Test.startTest();
            try{
                dmlProxy.performOperation( fflib_SObjectUnitOfWork.Operations.SEND_EMAIL, new List<Object>{ emailForOpp } );
            } catch( EmailException ex ){
                System.Assert.isTrue(
                    ex.getMessage().contains( 'INSUFFICIENT_ACCESS_OR_READONLY' ) || ex.getMessage().contains( 'NO_SINGLE_MAIL_PERMISSION' ) || ex.getMessage().contains( 'NO_MASS_MAIL_PERMISSION' ),
                    'System expected an Exception to be thrown as EmailDeliverability was NOT set to \'All_Email\', which is fine. ' +
                        'Nevertheless, the thrown Exception didn\'t contain the expected INSUFFICIENT_ACCESS_OR_READONLY, NO_SINGLE_MAIL_PERMISSION or NO_MASS_MAIL_PERMISSION, but was: ' + ex.getMessage()
                );
                System.Assert.areEqual( 0, Limits.getEmailInvocations(), 'Expected no email to be sent' );
                Test.stopTest();
                return;
            }
            // Assert that an email was sent
            System.Assert.areEqual( 1, Limits.getEmailInvocations(), 'Expected one email to be invoked' );
            Test.stopTest();
        }
    }

    @IsTest
    private static void inheritedSharing_performApprovalOperation(){
        // Create mocks
        fflib_Database_IDML dmlProxy = fflib_Database.getDMLProxy( fflib_Database.Context.INHERIT );

        // Create an approval request for the Solution
        Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
        request.setComments( 'Submitting request for approval.' );
        request.setObjectId( sampleSolutionList[ 0 ].Id );

        // Submit on behalf of a specific submitter
        request.setSubmitterId( testUser.Id );

        // Submit the record to specific process and skip the criteria evaluation
        request.setProcessDefinitionNameOrId( null );
        request.setSkipEntryCriteria( true );

        request.setNextApproverIds( new List<Id>{ testUser.Id } );

        // When - perform test
        System.runAs( testUser ){
            try{
                dmlProxy.performOperation( fflib_SObjectUnitOfWork.Operations.PROCESS_APPROVAL_PROCESS, new List<Object>{ request } );
                throw new fflib_SObjectUnitOfWork.UnitOfWorkException( 'Expected Exception as no Approval Process is setup' );
            } catch( DmlException ex ){
                System.Assert.isTrue(
                    ex.getMessage().contains( 'NO_APPLICABLE_PROCESS' ) || ex.getMessage().contains( 'INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY' ),
                    'System expected an Exception to be thrown as either no applicable processes are setup in this Org or insufficient access to the cross reference set in the ObjectId. ' +
                        'Nevertheless, the thrown Exception didn\'t contain the expected NO_APPLICABLE_PROCESS or INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY, but was: ' + ex.getMessage()
                );
                return;
            }
        }
    }

    @IsTest
    private static void inheritedSharing_invalidOperationToPerform(){
        // Create mocks
        fflib_Database_IDML dmlProxy = fflib_Database.getDMLProxy( fflib_Database.Context.INHERIT );

        // When, Then
        System.runAs( testUser ){
            try{
                dmlProxy.performOperation( null, new List<Object>{ new Approval.ProcessSubmitRequest() } );
                throw new fflib_SObjectUnitOfWork.UnitOfWorkException( 'Expected Exception as no Approval Process is setup' );
            } catch( fflib_Database_DMLProxy.InvalidDMLActionException ex ){
                System.Assert.areEqual( 'Invalid Operation null', ex.getMessage() );
            }

            List<Object> nullResults = dmlProxy.performOperation( fflib_SObjectUnitOfWork.Operations.PROCESS_APPROVAL_PROCESS, null );
            System.Assert.isNull( nullResults );
        }
    }

    /**
     * Section focusing on testing Database.Cursor and Database.PaginationCursor support across all sharing contexts.
     *
     * Test strategy: Integration-style tests against the real Database API — same approach as the getQueryLocator tests.
     * Database.Cursor and Database.PaginationCursor are system types and cannot be stubbed via fflib_ApexMocks
     * (identical constraint to Database.QueryLocator). Tests verify getNumRecords() and fetch()/fetchPage() behaviour.
     *
     * Note: System.FatalCursorException and System.TransientCursorException cannot be reliably triggered in test context
     * and are therefore not covered here.
     */
    @IsTest
    private static void withSharing_getCursor_failureInvalidFieldQueried(){
        // Given - create data
        fflib_QueryFactory queryFactory = new fflib_QueryFactory( Solution.SObjectType );
        queryFactory.selectFields( new List<SObjectField>{
            Solution.IsPublished,
            Solution.SolutionName
        } );
        queryFactory.setOrdering( Solution.CreatedDate, fflib_QueryFactory.SortOrder.DESCENDING );
        queryFactory.setLimit( 2 );

        // When, Then
        System.runAs( testUser ){
            fflib_Database_IQuery queryProxy = fflib_Database.getQueryProxy( fflib_Database.Context.FULL );

            // getCursor without binds
            try{
                queryProxy.getCursor( queryFactory.toSOQL(), withSharingAccessLevel );
                System.Assert.fail( 'Expected System.QueryException to be thrown. This assertion should never be triggered' );
            } catch( System.QueryException ex ){
                System.Assert.areEqual(
                    'No such column \'ispublished\' on entity \'Solution\'. If you are attempting to use a custom field, be sure to append the \'__c\' after the custom field name. Please reference your WSDL or the describe call for the appropriate names.',
                    ex.getMessage()
                );
            }

            // getCursor with binds
            try{
                queryProxy.getCursor( queryFactory.toSOQL(), new Map<String, Object>(), withSharingAccessLevel );
                System.Assert.fail( 'Expected System.QueryException to be thrown. This assertion should never be triggered' );
            } catch( System.QueryException ex ){
                System.Assert.areEqual(
                    'No such column \'ispublished\' on entity \'Solution\'. If you are attempting to use a custom field, be sure to append the \'__c\' after the custom field name. Please reference your WSDL or the describe call for the appropriate names.',
                    ex.getMessage()
                );
            }
        }
    }

    @IsTest
    private static void withSharing_getCursor_returnsCorrectCursorWithoutBinds(){
        // Given - create data
        fflib_Database_IQuery queryProxy = fflib_Database.getQueryProxy( fflib_Database.Context.FULL );
        fflib_QueryFactory queryFactory = new fflib_QueryFactory( Solution.SObjectType );
        queryFactory.selectFields( new List<SObjectField>{ Solution.SolutionName } );
        queryFactory.setOrdering( Solution.CreatedDate, fflib_QueryFactory.SortOrder.DESCENDING );
        queryFactory.setLimit( SAMPLE_SIZE_SOLUTION );

        // When - perform test
        System.runAs( testUser ){
            Database.Cursor cursor = queryProxy.getCursor( queryFactory.toSOQL(), withSharingAccessLevel );

            // Then - validate
            Integer expectedCount = isPrivateSolutionInternalSharing ? 0 : SAMPLE_SIZE_SOLUTION;
            System.Assert.areEqual( expectedCount, cursor.getNumRecords(), 'Expected cursor to report the correct total record count' );

            List<Solution> fetchedRecords = cursor.fetch( 0, SAMPLE_SIZE_SOLUTION );
            System.Assert.areEqual( expectedCount, fetchedRecords.size(), 'Expected fetch() to return the correct number of records' );
        }
    }

    @IsTest
    private static void withSharing_getCursor_returnsCorrectCursorWithBinds(){
        // Given - create data
        fflib_Database_IQuery queryProxy = fflib_Database.getQueryProxy( fflib_Database.Context.FULL );
        fflib_QueryFactory queryFactory = new fflib_QueryFactory( Solution.SObjectType );
        queryFactory.selectFields( new List<SObjectField>{ Solution.SolutionName } );
        queryFactory.setCondition( 'Id IN :solutionIds' );
        Set<Id> solutionIds = new Map<Id, Solution>( sampleSolutionList ).keySet();
        Map<String, Object> bindVariablesMap = new Map<String, Object>{ 'solutionIds' => solutionIds };

        // When - perform test
        System.runAs( testUser ){
            Database.Cursor cursor = queryProxy.getCursor( queryFactory.toSOQL(), bindVariablesMap, withSharingAccessLevel );

            // Then - validate
            Integer expectedCount = isPrivateSolutionInternalSharing ? 0 : SAMPLE_SIZE_SOLUTION;
            System.Assert.areEqual( expectedCount, cursor.getNumRecords(), 'Expected cursor to report the correct total record count' );

            List<Solution> fetchedRecords = cursor.fetch( 0, SAMPLE_SIZE_SOLUTION );
            System.Assert.areEqual( expectedCount, fetchedRecords.size(), 'Expected fetch() to return the correct number of records' );
        }
    }

    @IsTest
    private static void withSharing_getPaginationCursor_returnsCorrectPaginationCursorWithoutBinds(){
        // Given - create data
        fflib_Database_IQuery queryProxy = fflib_Database.getQueryProxy( fflib_Database.Context.FULL );
        fflib_QueryFactory queryFactory = new fflib_QueryFactory( Solution.SObjectType );
        queryFactory.selectFields( new List<SObjectField>{ Solution.SolutionName } );
        queryFactory.setOrdering( Solution.CreatedDate, fflib_QueryFactory.SortOrder.DESCENDING );
        queryFactory.setLimit( SAMPLE_SIZE_SOLUTION );

        // When - perform test
        System.runAs( testUser ){
            Database.PaginationCursor pagCursor = queryProxy.getPaginationCursor( queryFactory.toSOQL(), withSharingAccessLevel );

            // Then - validate
            Integer expectedCount = isPrivateSolutionInternalSharing ? 0 : SAMPLE_SIZE_SOLUTION;
            System.Assert.areEqual( expectedCount, pagCursor.getNumRecords(), 'Expected pagination cursor to report the correct total record count' );

            Database.CursorFetchResult result = pagCursor.fetchPage( 0, SAMPLE_SIZE_SOLUTION );
            System.Assert.areEqual( expectedCount, result.getRecords().size(), 'Expected fetchPage() to return the correct number of records' );
            System.Assert.isTrue( result.isDone(), 'Expected isDone() to be true when all records fit in one page' );
        }
    }

    /**
     * Section focusing on testing 'with sharing, skip permissions' context for cursors
     */
    @IsTest
    private static void withSharingSkip_getCursor_returnsCorrectCursorWithoutBinds(){
        // Given - create data
        fflib_Database_IQuery queryProxy = fflib_Database.getQueryProxy( fflib_Database.Context.SHARING_SKIP_PERMISSIONS );
        fflib_QueryFactory queryFactory = new fflib_QueryFactory( Solution.SObjectType );
        queryFactory.selectFields( new List<SObjectField>{ Solution.SolutionName } );
        queryFactory.setOrdering( Solution.CreatedDate, fflib_QueryFactory.SortOrder.DESCENDING );
        queryFactory.setLimit( SAMPLE_SIZE_SOLUTION );
        List<Solution> sampleSolutions = sampleSolutionList;

        // When - perform test
        System.runAs( testUser ){
            Database.Cursor cursor = queryProxy.getCursor( queryFactory.toSOQL(), sharingSkipAccessLevel );

            // Then - validate
            Integer expectedCount = isPrivateSolutionInternalSharing ? 0 : SAMPLE_SIZE_SOLUTION;
            System.Assert.areEqual( expectedCount, cursor.getNumRecords(), 'Expected cursor to report the correct total record count' );

            List<Solution> fetchedRecords = cursor.fetch( 0, SAMPLE_SIZE_SOLUTION );
            System.Assert.areEqual( expectedCount, fetchedRecords.size(), 'Expected fetch() to return the correct number of records' );
        }
    }

    @IsTest
    private static void withSharingSkip_getCursor_returnsCorrectCursorWithBinds(){
        // Given - create data
        fflib_Database_IQuery queryProxy = fflib_Database.getQueryProxy( fflib_Database.Context.SHARING_SKIP_PERMISSIONS );
        fflib_QueryFactory queryFactory = new fflib_QueryFactory( Solution.SObjectType );
        queryFactory.selectFields( new List<SObjectField>{ Solution.SolutionName } );
        queryFactory.setCondition( 'Id IN :solutionIds' );
        Set<Id> solutionIds = new Map<Id, Solution>( sampleSolutionList ).keySet();
        Map<String, Object> bindVariablesMap = new Map<String, Object>{ 'solutionIds' => solutionIds };

        // When - perform test
        System.runAs( testUser ){
            Database.Cursor cursor = queryProxy.getCursor( queryFactory.toSOQL(), bindVariablesMap, sharingSkipAccessLevel );

            // Then - validate
            Integer expectedCount = isPrivateSolutionInternalSharing ? 0 : SAMPLE_SIZE_SOLUTION;
            System.Assert.areEqual( expectedCount, cursor.getNumRecords(), 'Expected cursor to report the correct total record count' );

            List<Solution> fetchedRecords = cursor.fetch( 0, SAMPLE_SIZE_SOLUTION );
            System.Assert.areEqual( expectedCount, fetchedRecords.size(), 'Expected fetch() to return the correct number of records' );
        }
    }

    @IsTest
    private static void withSharingSkip_getPaginationCursor_returnsCorrectPaginationCursorWithoutBinds(){
        // Given - create data
        fflib_Database_IQuery queryProxy = fflib_Database.getQueryProxy( fflib_Database.Context.SHARING_SKIP_PERMISSIONS );
        fflib_QueryFactory queryFactory = new fflib_QueryFactory( Solution.SObjectType );
        queryFactory.selectFields( new List<SObjectField>{ Solution.SolutionName } );
        queryFactory.setOrdering( Solution.CreatedDate, fflib_QueryFactory.SortOrder.DESCENDING );
        queryFactory.setLimit( SAMPLE_SIZE_SOLUTION );

        // When - perform test
        System.runAs( testUser ){
            Database.PaginationCursor pagCursor = queryProxy.getPaginationCursor( queryFactory.toSOQL(), sharingSkipAccessLevel );

            // Then - validate
            Integer expectedCount = isPrivateSolutionInternalSharing ? 0 : SAMPLE_SIZE_SOLUTION;
            System.Assert.areEqual( expectedCount, pagCursor.getNumRecords(), 'Expected pagination cursor to report the correct total record count' );

            Database.CursorFetchResult result = pagCursor.fetchPage( 0, SAMPLE_SIZE_SOLUTION );
            System.Assert.areEqual( expectedCount, result.getRecords().size(), 'Expected fetchPage() to return the correct number of records' );
            System.Assert.isTrue( result.isDone(), 'Expected isDone() to be true when all records fit in one page' );
        }
    }

    /**
     * Section focusing on testing 'without sharing' context for cursors
     */
    @IsTest
    private static void withoutSharing_getCursor_returnsCorrectCursorWithoutBinds(){
        // Given - create data
        fflib_Database_IQuery queryProxy = fflib_Database.getQueryProxy( fflib_Database.Context.NONE );
        fflib_QueryFactory queryFactory = new fflib_QueryFactory( Solution.SObjectType );
        queryFactory.selectFields( new List<SObjectField>{ Solution.SolutionName } );
        queryFactory.setOrdering( Solution.CreatedDate, fflib_QueryFactory.SortOrder.DESCENDING );
        queryFactory.setLimit( SAMPLE_SIZE_SOLUTION );

        // Force sampleSolutionList initialization before entering runAs — the static lazy query selects IsPublished
        // which testUser has no FLS access to; initializing outside runAs avoids a QueryException inside the block
        List<Solution> expectedSolutions = sampleSolutionList;

        // When - perform test
        System.runAs( testUser ){
            Database.Cursor cursor = queryProxy.getCursor( queryFactory.toSOQL(), withoutSharingAccessLevel );

            // Then - validate (without sharing bypasses OWD, so all records are always visible)
            System.Assert.areEqual( SAMPLE_SIZE_SOLUTION, cursor.getNumRecords(), 'Expected cursor to report the correct total record count' );

            List<Solution> fetchedRecords = cursor.fetch( 0, SAMPLE_SIZE_SOLUTION );
            System.Assert.areEqual( SAMPLE_SIZE_SOLUTION, fetchedRecords.size(), 'Expected fetch() to return the correct number of records' );
            // Verify record identity by Id — direct list equality is not used as cursor.fetch() returns only queried fields
            for( Integer i = 0; i < fetchedRecords.size(); i++ ){
                System.Assert.areEqual( expectedSolutions[ i ].Id, fetchedRecords[ i ].Id, 'Expected fetched record Id to match sample data at index ' + i );
            }
        }
    }

    @IsTest
    private static void withoutSharing_getCursor_returnsCorrectCursorWithBinds(){
        // Given - create data
        fflib_Database_IQuery queryProxy = fflib_Database.getQueryProxy( fflib_Database.Context.NONE );
        fflib_QueryFactory queryFactory = new fflib_QueryFactory( Solution.SObjectType );
        queryFactory.selectFields( new List<SObjectField>{ Solution.SolutionName } );
        queryFactory.setCondition( 'Id IN :solutionIds' );
        Set<Id> solutionIds = new Map<Id, Solution>( sampleSolutionList ).keySet();
        Map<String, Object> bindVariablesMap = new Map<String, Object>{ 'solutionIds' => solutionIds };

        // When - perform test
        System.runAs( testUser ){
            Database.Cursor cursor = queryProxy.getCursor( queryFactory.toSOQL(), bindVariablesMap, withoutSharingAccessLevel );

            // Then - validate
            System.Assert.areEqual( SAMPLE_SIZE_SOLUTION, cursor.getNumRecords(), 'Expected cursor to report the correct total record count' );

            List<Solution> fetchedRecords = cursor.fetch( 0, SAMPLE_SIZE_SOLUTION );
            System.Assert.areEqual( SAMPLE_SIZE_SOLUTION, fetchedRecords.size(), 'Expected fetch() to return the correct number of records' );
        }
    }

    @IsTest
    private static void withoutSharing_getPaginationCursor_returnsCorrectPaginationCursorWithoutBinds(){
        // Given - create data
        fflib_Database_IQuery queryProxy = fflib_Database.getQueryProxy( fflib_Database.Context.NONE );
        fflib_QueryFactory queryFactory = new fflib_QueryFactory( Solution.SObjectType );
        queryFactory.selectFields( new List<SObjectField>{ Solution.SolutionName } );
        queryFactory.setOrdering( Solution.CreatedDate, fflib_QueryFactory.SortOrder.DESCENDING );
        queryFactory.setLimit( SAMPLE_SIZE_SOLUTION );

        // When - perform test
        System.runAs( testUser ){
            Database.PaginationCursor pagCursor = queryProxy.getPaginationCursor( queryFactory.toSOQL(), withoutSharingAccessLevel );

            // Then - validate
            System.Assert.areEqual( SAMPLE_SIZE_SOLUTION, pagCursor.getNumRecords(), 'Expected pagination cursor to report the correct total record count' );

            Database.CursorFetchResult result = pagCursor.fetchPage( 0, SAMPLE_SIZE_SOLUTION );
            System.Assert.areEqual( SAMPLE_SIZE_SOLUTION, result.getRecords().size(), 'Expected fetchPage() to return the correct number of records' );
            System.Assert.isTrue( result.isDone(), 'Expected isDone() to be true when all records fit in one page' );
        }
    }

    /**
     * Section focusing on testing 'inherited sharing' context for cursors.
     * Since this class respects sharing rules (aka "with sharing"), sharing settings should be enforced upon the test user context,
     * presenting similar results to {@link fflib_Database.Context.SHARING_SKIP_PERMISSIONS}
     */
    @IsTest
    private static void inheritedSharing_getCursor_returnsCorrectCursorWithoutBinds(){
        // Given - create data
        fflib_Database_IQuery queryProxy = fflib_Database.getQueryProxy( fflib_Database.Context.INHERIT );
        fflib_QueryFactory queryFactory = new fflib_QueryFactory( Solution.SObjectType );
        queryFactory.selectFields( new List<SObjectField>{ Solution.SolutionName } );
        queryFactory.setOrdering( Solution.CreatedDate, fflib_QueryFactory.SortOrder.DESCENDING );
        queryFactory.setLimit( SAMPLE_SIZE_SOLUTION );

        // When - perform test
        System.runAs( testUser ){
            Database.Cursor cursor = queryProxy.getCursor( queryFactory.toSOQL(), inheritedAccessLevel );

            // Then - validate
            Integer expectedCount = isPrivateSolutionInternalSharing ? 0 : SAMPLE_SIZE_SOLUTION;
            System.Assert.areEqual( expectedCount, cursor.getNumRecords(), 'Expected cursor to report the correct total record count' );

            List<Solution> fetchedRecords = cursor.fetch( 0, SAMPLE_SIZE_SOLUTION );
            System.Assert.areEqual( expectedCount, fetchedRecords.size(), 'Expected fetch() to return the correct number of records' );
        }
    }

    @IsTest
    private static void inheritedSharing_getCursor_returnsCorrectCursorWithBinds(){
        // Given - create data
        fflib_Database_IQuery queryProxy = fflib_Database.getQueryProxy( fflib_Database.Context.INHERIT );
        fflib_QueryFactory queryFactory = new fflib_QueryFactory( Solution.SObjectType );
        queryFactory.selectFields( new List<SObjectField>{ Solution.SolutionName } );
        queryFactory.setCondition( 'Id IN :solutionIds' );
        Set<Id> solutionIds = new Map<Id, Solution>( sampleSolutionList ).keySet();
        Map<String, Object> bindVariablesMap = new Map<String, Object>{ 'solutionIds' => solutionIds };

        // When - perform test
        System.runAs( testUser ){
            Database.Cursor cursor = queryProxy.getCursor( queryFactory.toSOQL(), bindVariablesMap, inheritedAccessLevel );

            // Then - validate
            Integer expectedCount = isPrivateSolutionInternalSharing ? 0 : SAMPLE_SIZE_SOLUTION;
            System.Assert.areEqual( expectedCount, cursor.getNumRecords(), 'Expected cursor to report the correct total record count' );

            List<Solution> fetchedRecords = cursor.fetch( 0, SAMPLE_SIZE_SOLUTION );
            System.Assert.areEqual( expectedCount, fetchedRecords.size(), 'Expected fetch() to return the correct number of records' );
        }
    }

    @IsTest
    private static void inheritedSharing_getPaginationCursor_returnsCorrectPaginationCursorWithoutBinds(){
        // Given - create data
        fflib_Database_IQuery queryProxy = fflib_Database.getQueryProxy( fflib_Database.Context.INHERIT );
        fflib_QueryFactory queryFactory = new fflib_QueryFactory( Solution.SObjectType );
        queryFactory.selectFields( new List<SObjectField>{ Solution.SolutionName } );
        queryFactory.setOrdering( Solution.CreatedDate, fflib_QueryFactory.SortOrder.DESCENDING );
        queryFactory.setLimit( SAMPLE_SIZE_SOLUTION );

        // When - perform test
        System.runAs( testUser ){
            Database.PaginationCursor pagCursor = queryProxy.getPaginationCursor( queryFactory.toSOQL(), inheritedAccessLevel );

            // Then - validate
            Integer expectedCount = isPrivateSolutionInternalSharing ? 0 : SAMPLE_SIZE_SOLUTION;
            System.Assert.areEqual( expectedCount, pagCursor.getNumRecords(), 'Expected pagination cursor to report the correct total record count' );

            Database.CursorFetchResult result = pagCursor.fetchPage( 0, SAMPLE_SIZE_SOLUTION );
            System.Assert.areEqual( expectedCount, result.getRecords().size(), 'Expected fetchPage() to return the correct number of records' );
            System.Assert.isTrue( result.isDone(), 'Expected isDone() to be true when all records fit in one page' );
        }
    }
}
