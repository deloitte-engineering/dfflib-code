/**
 * Copyright (c), FinancialForce.com, inc
 * Copyright (c) 2019, Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
@IsTest( isParallel = false )
private with sharing class dfflib_SObjectDomainTest{
    @IsTest
    private static void testValidationWithoutDML(){
        // Given - create data
        dfflib_SObjectDomain.TestSObjectDomain opps = new dfflib_SObjectDomain.TestSObjectDomain(
            new List<Opportunity>{
                new Opportunity ( Name = 'Test', Type = 'Existing Account' )
            }
        );

        // When - perform test
        opps.onValidate();

        // Then - validate
        System.Assert.areEqual( 1, dfflib_SObjectDomain.Errors.getAll().size() );
        System.Assert.areEqual( 'You must provide an Account for Opportunities for existing Customers.', dfflib_SObjectDomain.Errors.getAll()[ 0 ].message );
        System.Assert.areEqual( Opportunity.AccountId, ( ( dfflib_SObjectDomain.FieldError ) dfflib_SObjectDomain.Errors.getAll()[ 0 ] ).field );

        // Given - create data
        opps = new dfflib_SObjectDomain.TestSObjectDomain(
            new List<SObject>{
                new Opportunity( Name = 'Test', Type = 'Existing Account' )
            },
            Opportunity.SObjectType
        );

        // Then - validate
        System.Assert.areEqual( 1, dfflib_SObjectDomain.Errors.getAll().size() );
        System.Assert.areEqual( 'You must provide an Account for Opportunities for existing Customers.', dfflib_SObjectDomain.Errors.getAll()[ 0 ].message );
        System.Assert.areEqual( Opportunity.AccountId, ( ( dfflib_SObjectDomain.FieldError ) dfflib_SObjectDomain.Errors.getAll()[ 0 ] ).field );
    }

    @IsTest
    private static void testInsertValidationFailedWithoutDML(){
        // Given - create data
        Opportunity opp = new Opportunity ( Name = 'Test', Type = 'Existing Account' );
        System.Assert.isFalse( dfflib_SObjectDomain.Test.database.hasRecords() );

        // When - perform test
        dfflib_SObjectDomain.Test.database.onInsert( new List<Opportunity>{ opp } );
        System.Assert.isTrue( dfflib_SObjectDomain.Test.database.hasRecords() );
        dfflib_SObjectDomain.triggerHandler( dfflib_SObjectDomain.TestSObjectDomainConstructor.class );

        // Then - validate
        System.Assert.areEqual( 1, dfflib_SObjectDomain.Errors.getAll().size() );
        System.Assert.areEqual( 'You must provide an Account for Opportunities for existing Customers.', dfflib_SObjectDomain.Errors.getAll()[ 0 ].message );
        System.Assert.areEqual( Opportunity.AccountId, ( ( dfflib_SObjectDomain.FieldError ) dfflib_SObjectDomain.Errors.getAll()[ 0 ] ).field );
    }

    @IsTest
    private static void testUpdateValidationFailedWithoutDML(){
        // Given - create data
        Opportunity oldOpp = new Opportunity( Name = 'Test', Type = 'Existing Account' );
        Opportunity newOpp = new Opportunity( Name = 'Test', Type = 'New Account' );
        System.Assert.isFalse( dfflib_SObjectDomain.Test.database.hasRecords() );

        // When - perform test
        dfflib_SObjectDomain.Test.database.onUpdate( new List<Opportunity>{ newOpp }, new Map<Id, SObject>{ newOpp.Id => oldOpp } );
        System.Assert.isTrue( dfflib_SObjectDomain.Test.database.hasRecords() );
        dfflib_SObjectDomain.triggerHandler( dfflib_SObjectDomain.TestSObjectDomainConstructor.class );

        // Then - validate
        System.Assert.areEqual( 1, dfflib_SObjectDomain.Errors.getAll().size() );
        System.Assert.areEqual( 'You cannot change the Opportunity type once it has been created.', dfflib_SObjectDomain.Errors.getAll()[ 0 ].message );
        System.Assert.areEqual( Opportunity.Type, ( ( dfflib_SObjectDomain.FieldError ) dfflib_SObjectDomain.Errors.getAll()[ 0 ] ).field );
    }

    @IsTest
    private static void testOnBeforeDeleteWithoutDML(){
        // Given - create data
        Opportunity opp = new Opportunity( Name = 'Test', Type = 'Existing Account' );
        System.Assert.isFalse( dfflib_SObjectDomain.Test.database.hasRecords() );

        // When - perform test
        dfflib_SObjectDomain.Test.database.onDelete( new Map<Id, Opportunity>{ opp.Id => opp } );
        System.Assert.isTrue( dfflib_SObjectDomain.Test.database.hasRecords() );
        dfflib_SObjectDomain.triggerHandler( dfflib_SObjectDomain.TestSObjectDomainConstructor.class );

        // Then - validate
        System.Assert.areEqual( 1, dfflib_SObjectDomain.Errors.getAll().size() );
        System.Assert.areEqual( 'You cannot delete this Opportunity.', dfflib_SObjectDomain.Errors.getAll()[ 0 ].message );
    }

    @IsTest
    private static void testOnAfterUndeleteWithoutDML(){
        // Given - create data
        Opportunity opp = new Opportunity( Name = 'Test', Type = 'Existing Account' );
        System.Assert.isFalse( dfflib_SObjectDomain.Test.database.hasRecords() );

        // When - perform test
        dfflib_SObjectDomain.Test.database.onUndelete( new List<Opportunity>{ opp } );

        // Then - validate
        System.Assert.isTrue( dfflib_SObjectDomain.Test.database.hasRecords() );
        dfflib_SObjectDomain.triggerHandler( dfflib_SObjectDomain.TestSObjectDomainConstructor.class );
    }

    @IsTest
    private static void testObjectSecurity(){
        // Given - create data
        // Create a user which will not have access to the test object type
        User testUser = createChatterExternalUser();
        if( testUser == null ){
            return;
        } // Abort the test if unable to create a user with low enough access

        // Inject appConfig mock so the no-arg UoW constructor does not issue a SOQL query inside System.runAs.
        // An empty config list is safe here: the CRUD exception is thrown from handleAfterInsert() before
        // commitWork() is ever reached, so no SObjectType registration against the UoW takes place.
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        dfflib_ApplicationConfig configMock = ( dfflib_ApplicationConfig ) mocks.mock( dfflib_ApplicationConfig.class );
        mocks.startStubbing();
        mocks.when( configMock.getUnitOfWorkConfigs() ).thenReturn( new List<FFLIB_UOW_Config__mdt>() );
        mocks.stopStubbing();
        dfflib_Application.appConfig = configMock;

        // When - perform test
        System.runAs( testUser ){
            // Test Create object security
            Opportunity opp = new Opportunity( Name = 'Test', Type = 'New Account' );
            dfflib_SObjectDomain.Test.database.onInsert( new List<Opportunity>{ opp } );
            try{
                dfflib_SObjectDomain.triggerHandler( dfflib_SObjectDomain.TestSObjectDomainConstructor.class );
                System.Assert.fail( 'Expected access denied exception. This assertion should never be triggered' );
            } catch( Exception e ){
                System.Assert.areEqual( 'Permission to create an Opportunity denied.', e.getMessage() );
            }

            // Test Update object security
            dfflib_SObjectDomain.Test.database.onUpdate( new List<Opportunity>{ opp }, new Map<Id, Opportunity>{ opp.Id => opp } );
            try{
                dfflib_SObjectDomain.triggerHandler( dfflib_SObjectDomain.TestSObjectDomainConstructor.class );
                System.Assert.fail( 'Expected access denied exception. This assertion should never be triggered' );
            } catch( Exception e ){
                System.Assert.areEqual( 'Permission to update an Opportunity denied.', e.getMessage() );
            }

            // Then - validate
            // Test Delete object security
            dfflib_SObjectDomain.Test.database.onDelete( new Map<Id, Opportunity>{ opp.Id => opp } );
            try{
                dfflib_SObjectDomain.triggerHandler( dfflib_SObjectDomain.TestSObjectDomainConstructor.class );
                System.Assert.fail( 'Expected access denied exception. This assertion should never be triggered' );
            } catch( Exception e ){
                System.Assert.areEqual( 'Permission to delete an Opportunity denied.', e.getMessage() );
            }

            // Then - validate
            // Test Undelete object security
            dfflib_SObjectDomain.Test.database.onUndelete( new List<Opportunity>{ opp } );
            try{
                dfflib_SObjectDomain.triggerHandler( dfflib_SObjectDomain.TestSObjectDomainConstructor.class );
                System.Assert.fail( 'Expected access denied exception. This assertion should never be triggered' );
            } catch( Exception e ){
                System.Assert.areEqual( 'Permission to undelete an Opportunity denied.', e.getMessage() );
            }
        }
    }

    @IsTest
    private static void testErrorLogging(){
        // Given - create data
        // Test static helpers for raise none domain object instance errors
        Opportunity opp = new Opportunity ( Name = 'Test', Type = 'Existing Account' );
        dfflib_SObjectDomain.Errors.error( 'Error', opp );
        dfflib_SObjectDomain.Errors.error( 'Error', opp, Opportunity.Type );
        System.Assert.areEqual( 2, dfflib_SObjectDomain.Errors.getAll().size() );
        System.Assert.areEqual( 'Error', dfflib_SObjectDomain.Errors.getAll()[ 0 ].message );
        System.Assert.areEqual( 'Error', dfflib_SObjectDomain.Errors.getAll()[ 1 ].message );

        // When - perform test
        System.Assert.areEqual( Opportunity.Type, ( ( dfflib_SObjectDomain.FieldError ) dfflib_SObjectDomain.Errors.getAll()[ 1 ] ).field );
        dfflib_SObjectDomain.Errors.clearAll();

        // Then - validate
        System.Assert.areEqual( 0, dfflib_SObjectDomain.Errors.getAll().size() );
    }

    @IsTest
    private static void testTriggerState(){
        // Given - create data
        Opportunity opp = new Opportunity ( Name = 'Test', Type = 'Existing Account' );

        // When - perform test
        dfflib_SObjectDomain.Test.database.onInsert( new List<Opportunity>{ opp } );
        dfflib_SObjectDomain.triggerHandler( dfflib_SObjectDomain.TestSObjectStatefulDomainConstructor.class );

        // Then - validate
        System.Assert.areEqual( 1, dfflib_SObjectDomain.Errors.getAll().size() );
        System.Assert.areEqual( 'Error on Record Test', dfflib_SObjectDomain.Errors.getAll()[ 0 ].message );
    }

    @IsTest
    private static void testRecursiveTriggerState(){
        // Given - create data
        Opportunity opp = new Opportunity ( Name = 'Test Recursive 1', Type = 'Existing Account' );

        // When - perform test
        dfflib_SObjectDomain.Test.database.onInsert( new List<Opportunity>{ opp } );
        dfflib_SObjectDomain.triggerHandler( dfflib_SObjectDomain.TestSObjectStatefulDomainConstructor.class );

        // Then - validate
        System.Assert.areEqual( 2, dfflib_SObjectDomain.Errors.getAll().size() );
        System.Assert.areEqual( 'Error on Record Test Recursive 2', dfflib_SObjectDomain.Errors.getAll()[ 0 ].message );
        System.Assert.areEqual( 'Error on Record Test Recursive 1', dfflib_SObjectDomain.Errors.getAll()[ 1 ].message );
    }

    @IsTest
    private static void testOnValidateBehaviorDefault(){
        // Given - create data
        Opportunity oldOpp = new Opportunity( Name = 'Test Default Behaviour', Type = 'Existing Account' );
        Opportunity newOpp = new Opportunity( Name = 'Test Default Behaviour', Type = 'New Account' );

        // When - perform test
        dfflib_SObjectDomain.Test.database.onUpdate( new List<Opportunity>{ newOpp }, new Map<Id, SObject>{ newOpp.Id => oldOpp } );
        dfflib_SObjectDomain.triggerHandler( dfflib_SObjectDomain.TestSObjectOnValidateBehaviourConstructor.class );
    }

    @IsTest
    private static void testOnValidateBehaviorOld(){
        // Given - create data
        Opportunity oldOpp = new Opportunity( Name = 'Test Enable Old Behaviour', Type = 'Existing Account' );
        Opportunity newOpp = new Opportunity( Name = 'Test Enable Old Behaviour', Type = 'New Account' );

        // When - perform test
        dfflib_SObjectDomain.Test.database.onUpdate( new List<Opportunity>{ newOpp }, new Map<Id, SObject>{ newOpp.Id => oldOpp } );
        try{
            dfflib_SObjectDomain.triggerHandler( dfflib_SObjectDomain.TestSObjectOnValidateBehaviourConstructor.class );
            System.Assert.fail( 'Expected an exception to be thrown. This assertion should never be triggered' );
        } catch( Exception e ){
            // Then - validate
            System.Assert.areEqual( 'onValidate called', e.getMessage() );
        }
    }

    @IsTest
    private static void testGetChangedFieldsAsStrings(){
        // Given - create data
        Account acct1 = new Account( Name = 'Test1', AccountNumber = '12345', Site = 'Here' );
        Account acct2 = new Account( Name = 'Test2', AccountNumber = '54321', Site = 'There' );
        System.Assert.isFalse( dfflib_SObjectDomain.Test.database.hasRecords() );
        dfflib_SObjectDomain.Test.database.onInsert( new List<Account>{ acct1, acct2 } );
        System.Assert.isTrue( dfflib_SObjectDomain.Test.database.hasRecords() );
        dfflib_SObjectDomain.triggerHandler( dfflib_SObjectDomain.TestSObjectChangedRecordsConstructor.class );
        Account acct1changed = acct1.clone(),
            acct2changed = acct2.clone();
        acct1changed.Name = 'Test1changed';
        // When, Then
        dfflib_SObjectDomain.Test.database.onUpdate(
            new List<Account>{ acct1, acct2 },
            new Map<Id, Account>{
                acct1changed.Id => acct1,
                acct2changed.Id => acct2
            }
        );
    }

    @IsTest
    private static void itShouldReturnTheChangedRecordsBySObjectFields(){
        // Given - create data. Domain with old and changed records
        Id idLuke = fflib_IDGenerator.generate( Account.SObjectType );
        Id idHan = fflib_IDGenerator.generate( Account.SObjectType );
        Id idLeia = fflib_IDGenerator.generate( Account.SObjectType );
        List<Account> oldRecords = new List<Account>{
            new Account( Id = idLuke, Name = 'Luke', Description = 'Jedi' ),
            new Account( Id = idHan, Name = 'Han', Description = 'Pilot' ),
            new Account( Id = idLeia, Name = 'Leia' )
        };

        List<Account> newRecords = oldRecords.deepClone( true, true, true );
        newRecords.get( 0 ).Name = 'Luke SkyWalker';
        newRecords.get( 0 ).Description = 'Jedi Master';
        newRecords.get( 1 ).Name = 'Han Solo';
        TestAccountsDomain accounts = new TestAccountsDomain( newRecords, dfflib.unitOfWork.newInstance() );
        accounts.existingRecords = new Map<Id, SObject>( oldRecords );

        // When - perform test. We create a domain with ExistingRecords and request the changed records
        List<SObject> result = accounts.getChangedRecords(
            new Set<Schema.SObjectField>{
                Account.Name,
                Account.Description
            }
        );

        // Then - validate. It should only return the changed records
        Map<Id, SObject> resultMap = new Map<Id, SObject>( result );
        System.Assert.areEqual( 2, result.size() );
        System.Assert.isTrue( resultMap.containsKey( idLuke ) );
        System.Assert.isTrue( resultMap.containsKey( idHan ) );
    }

    @IsTest
    private static void itShouldReturnTheChangedRecordsByStringFields(){
        // Given - create data. Domain with old and changed records
        Id idLuke = fflib_IDGenerator.generate( Account.SObjectType );
        Id idHan = fflib_IDGenerator.generate( Account.SObjectType );
        Id idLeia = fflib_IDGenerator.generate( Account.SObjectType );
        List<Account> oldRecords = new List<Account>{
            new Account( Id = idLuke, Name = 'Luke', Description = 'Jedi' ),
            new Account( Id = idHan, Name = 'Han', Description = 'Pilot' ),
            new Account( Id = idLeia, Name = 'Leia' )
        };

        List<Account> newRecords = oldRecords.deepClone( true, true, true );
        newRecords.get( 0 ).Name = 'Luke SkyWalker';
        newRecords.get( 0 ).Description = 'Jedi Master';
        newRecords.get( 1 ).Name = 'Han Solo';
        TestAccountsDomain accounts = new TestAccountsDomain( newRecords, dfflib.unitOfWork.newInstance() );
        dfflib_SObjectDomain.Test.database.onUpdate( newRecords, new Map<Id, SObject>( oldRecords ) );

        // When - perform test. We create a domain with ExistingRecords and request the changed records
        List<SObject> result = accounts.getChangedRecords(
            new Set<String>{
                'Name',
                'Description'
            }
        );

        // Then - validate. It should only return the changed records
        Map<Id, SObject> resultMap = new Map<Id, SObject>( result );
        System.Assert.areEqual( 2, result.size() );
        System.Assert.isTrue( resultMap.containsKey( idLuke ) );
        System.Assert.isTrue( resultMap.containsKey( idHan ) );
    }

    /**
     * @return  User record with Chatter External user license.
     */
    private static User createChatterExternalUser(){
        // Can only proceed with test if we have a suitable profile - Chatter External license has no access to Opportunity
        List<Profile> testProfiles = [ SELECT Id FROM Profile WHERE UserLicense.Name = 'Chatter External' LIMIT 1 ];
        if( testProfiles.size() != 1 ){
            return null;
        }

        // Can only proceed with test if we can successfully insert a test user
        // Username global uniqueness is still enforced in tests
        String randomInteger = String.valueOf( Math.round( Math.random() * 1000 ) );

        dfflib_ISObjectUnitOfWork uow = dfflib.unitOfWork.newInstance( new List<SObjectType>{ User.SObjectType } );
        User u = new User(
            Username = 'test' + randomInteger + '@fake_test_domain.com',
            Alias = 'test1',
            Email = 'testuser1@testorg.com',
            EmailEncodingKey = 'UTF-8',
            FirstName = 'FirstName',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = testProfiles[ 0 ].Id,
            TimeZoneSidKey = 'America/Los_Angeles'
        );

        insert u;
        return u;
    }

    /**
     *	The following tests that the ability to enable/disable all trigger events works as required
     */
    @IsTest
    private static void testDisableTriggerEventsBehaviour(){
        // Given - create data
        Boolean bError = false;
        String sErrorMessage = '';

        Opportunity oldOpp = new Opportunity( Name = 'Test', Type = 'Existing' );
        Opportunity newOpp = new Opportunity( Name = 'Test', Type = 'New' );

        // When - perform test
        // these will be called multiple times making sure the correct error message comes back out
        // so... there are a lot of tests to do here sadly and remember everything is reversed and you need to run backwards!
        // 1 - all disabled 
        try{
            dfflib_SObjectDomain.getTriggerEvent( dfflib_SObjectDomain.TestSObjectDisableBehaviourConstructor.class ).disableAll();
            dfflib_SObjectDomain.Test.database.onInsert( new List<Opportunity>{ newOpp } );
            dfflib_SObjectDomain.triggerHandler( dfflib_SObjectDomain.TestSObjectDisableBehaviourConstructor.class );
        } catch( Exception e ){
            bError = true;
        }

        // Then - validate
        System.Assert.isFalse( bError, 'Error - Trigger events have been fired when they are disabled' );

        ////////////////////////////
        // Insert!
        try{
            // now lets go after insert and then before
            dfflib_SObjectDomain.getTriggerEvent( dfflib_SObjectDomain.TestSObjectDisableBehaviourConstructor.class ).enableAfterInsert();
            dfflib_SObjectDomain.Test.database.onInsert( new List<Opportunity>{ newOpp } );
            dfflib_SObjectDomain.triggerHandler( dfflib_SObjectDomain.TestSObjectDisableBehaviourConstructor.class );
        } catch( Exception e ){
            sErrorMessage = e.getMessage();
        }

        System.Assert.areEqual( 'onAfterInsert called', sErrorMessage, 'Error - After Insert Event is enabled but did not run' );

        try{
            // now lets go after insert and then before
            dfflib_SObjectDomain.getTriggerEvent( dfflib_SObjectDomain.TestSObjectDisableBehaviourConstructor.class ).enableBeforeInsert();
            dfflib_SObjectDomain.Test.database.onInsert( new List<Opportunity>{ newOpp } );
            dfflib_SObjectDomain.triggerHandler( dfflib_SObjectDomain.TestSObjectDisableBehaviourConstructor.class );
        } catch( Exception e ){
            sErrorMessage = e.getMessage();
        }

        System.Assert.areEqual( 'onBeforeInsert called', sErrorMessage, 'Error - Before Insert Event is enabled but did not run' );

        ////////////////////////////
        // Update!
        try{
            // now lets go after insert and then before
            dfflib_SObjectDomain.getTriggerEvent( dfflib_SObjectDomain.TestSObjectDisableBehaviourConstructor.class ).enableAfterUpdate();
            dfflib_SObjectDomain.Test.database.onUpdate( new List<Opportunity>{ newOpp }, new Map<Id, SObject>{ newOpp.Id => oldOpp } );
            dfflib_SObjectDomain.triggerHandler( dfflib_SObjectDomain.TestSObjectDisableBehaviourConstructor.class );
        } catch( Exception e ){
            sErrorMessage = e.getMessage();
        }

        System.Assert.areEqual( 'onAfterUpdate called', sErrorMessage, 'Error - After Update Event is enabled but did not run' );

        try{
            // now lets go after insert and then before
            dfflib_SObjectDomain.getTriggerEvent( dfflib_SObjectDomain.TestSObjectDisableBehaviourConstructor.class ).enableBeforeUpdate();
            dfflib_SObjectDomain.Test.database.onUpdate( new List<Opportunity>{ newOpp }, new Map<Id, SObject>{ newOpp.Id => oldOpp } );
            dfflib_SObjectDomain.triggerHandler( dfflib_SObjectDomain.TestSObjectDisableBehaviourConstructor.class );
        } catch( Exception e ){
            sErrorMessage = e.getMessage();
        }

        System.Assert.areEqual( 'onBeforeUpdate called', sErrorMessage, 'Error - Before Update Event is enabled but did not run' );

        ////////////////////////////
        // Delete!
        try{
            // now lets go after insert and then before
            dfflib_SObjectDomain.getTriggerEvent( dfflib_SObjectDomain.TestSObjectDisableBehaviourConstructor.class ).enableAfterDelete();
            dfflib_SObjectDomain.Test.database.onDelete( new Map<Id, Opportunity>{ newOpp.Id => newOpp } );
            dfflib_SObjectDomain.triggerHandler( dfflib_SObjectDomain.TestSObjectDisableBehaviourConstructor.class );
        } catch( Exception e ){
            sErrorMessage = e.getMessage();
        }

        System.Assert.areEqual( 'onAfterDelete called', sErrorMessage, 'Error - After Delete Event is enabled but did not run' );

        try{
            // now lets go after insert and then before
            dfflib_SObjectDomain.getTriggerEvent( dfflib_SObjectDomain.TestSObjectDisableBehaviourConstructor.class ).enableBeforeDelete();
            dfflib_SObjectDomain.Test.database.onDelete( new Map<Id, Opportunity>{ newOpp.Id => newOpp } );
            dfflib_SObjectDomain.triggerHandler( dfflib_SObjectDomain.TestSObjectDisableBehaviourConstructor.class );
        } catch( Exception e ){
            sErrorMessage = e.getMessage();
        }

        System.Assert.areEqual( 'onBeforeDelete called', sErrorMessage, 'Error - Before Delete Event is enabled but did not run' );

        ////////////////////////////
        // Undelete!
        try{
            // now lets go after insert and then before
            dfflib_SObjectDomain.getTriggerEvent( dfflib_SObjectDomain.TestSObjectDisableBehaviourConstructor.class ).enableAfterUndelete();
            dfflib_SObjectDomain.Test.database.onUndelete( new List<Opportunity>{ newOpp } );
            dfflib_SObjectDomain.triggerHandler( dfflib_SObjectDomain.TestSObjectDisableBehaviourConstructor.class );
        } catch( Exception e ){
            sErrorMessage = e.getMessage();
        }

        System.Assert.areEqual( 'onAfterUndelete called', sErrorMessage, 'Error - After Undelete Event is enabled but did not run' );
    }

    @IsTest
    private static void runHandler_shouldRunHandlerBeforeInsertSuccessfully(){
        // Given - create data
        Id idLuke = fflib_IDGenerator.generate( Account.SObjectType );
        Id idHan = fflib_IDGenerator.generate( Account.SObjectType );
        Id idLeia = fflib_IDGenerator.generate( Account.SObjectType );
        List<Account> accountList = new List<Account>{
            new Account( Id = idLuke, Name = 'Luke', Description = 'Jedi' ),
            new Account( Id = idHan, Name = 'Han', Description = 'Pilot' ),
            new Account( Id = idLeia, Name = 'Leia', Description = 'Also a Jedi' )
        };

        Map<Id, SObject> accountMap = new Map<Id, SObject>( accountList );

        // Validate before executing
        System.Assert.areEqual( 'Jedi', accountList[ 0 ].Description );
        System.Assert.areEqual( 'Pilot', accountList[ 1 ].Description );
        System.Assert.areEqual( 'Also a Jedi', accountList[ 2 ].Description );

        // When - perform test
        new TestAccountsDomain( accountList ).runHandler(
            TestAccountBaseHandlerImpl.class,
            dfflib_SObjectDomain.TriggerEvent.BEFORE_INSERT,
            accountMap,
            dfflib.unitOfWork.newInstance()
        );

        // Then - validate
        System.Assert.areEqual( dummyAccountDescription, accountList[ 0 ].Description );
        System.Assert.areEqual( dummyAccountDescription, accountList[ 1 ].Description );
        System.Assert.areEqual( dummyAccountDescription, accountList[ 2 ].Description );
    }

    @IsTest
    private static void runHandler_shouldVerifyTriggerEventUnsupported(){
        // Given - create data
        Id idLuke = fflib_IDGenerator.generate( Account.SObjectType );
        Id idHan = fflib_IDGenerator.generate( Account.SObjectType );
        Id idLeia = fflib_IDGenerator.generate( Account.SObjectType );
        List<Account> accountList = new List<Account>{
            new Account( Id = idLuke, Name = 'Luke', Description = 'Jedi' ),
            new Account( Id = idHan, Name = 'Han', Description = 'Pilot' ),
            new Account( Id = idLeia, Name = 'Leia', Description = 'Also a Jedi' )
        };

        Map<Id, SObject> accountMap = new Map<Id, SObject>( accountList );

        // Validate before executing
        System.Assert.areEqual( 'Jedi', accountList[ 0 ].Description );
        System.Assert.areEqual( 'Pilot', accountList[ 1 ].Description );
        System.Assert.areEqual( 'Also a Jedi', accountList[ 2 ].Description );

        String sErrorMessage = '';
        // When - perform test
        try{
            new TestAccountsDomain( accountList ).runHandler(
                TestUnsupportedBaseHandlerImpl.class,
                dfflib_SObjectDomain.TriggerEvent.BEFORE_INSERT,
                accountMap,
                dfflib.unitOfWork.newInstance()
            );
        } catch( Exception e ){
            sErrorMessage = e.getMessage();
        }

        System.Assert.areEqual( 'Handler dfflib_SObjectDomainTest.TestUnsupportedBaseHandlerImpl does not support the trigger event BEFORE_INSERT', sErrorMessage );
    }

    @IsTest
    private static void getSObjectType_shouldReturnTypeSuccessfully(){
        // Given - create data
        TestAccountsDomain accountsDomain = new TestAccountsDomain( new List<Account>() );

        // When, Then
        System.Assert.areEqual( Account.SObjectType, accountsDomain.sObjectType() );
    }

    @IsTest
    private static void getRecords_shouldReturnRecordsSuccessfully(){
        // Given - create data
        Id idLuke = fflib_IDGenerator.generate( Account.SObjectType );
        Id idHan = fflib_IDGenerator.generate( Account.SObjectType );
        Id idLeia = fflib_IDGenerator.generate( Account.SObjectType );
        List<Account> accountList = new List<Account>{
            new Account( Id = idLuke, Name = 'Luke', Description = 'Jedi' ),
            new Account( Id = idHan, Name = 'Han', Description = 'Pilot' ),
            new Account( Id = idLeia, Name = 'Leia', Description = 'Also a Jedi' )
        };
        TestAccountsDomain accountsDomain = new TestAccountsDomain( accountList );

        // When, Then
        System.Assert.areEqual( accountList, accountsDomain.getRecords() );
        System.Assert.areEqual( accountsDomain.getRecords(), accountsDomain.getObjects(), 'Expect objects of same instance/record collection as domain' );
    }

    @IsTest
    private static void execute_shouldRunSuccessfullyOnBeforeInsert(){
        // Given - create data
        TestAccountsDomain accountsDomain = new TestAccountsDomain( new List<Account>{
            new Account( Name = 'Luke', Description = 'Jedi' )
        } );

        // When, Then
        try{
            accountsDomain.handleBeforeInsert();
        } catch( Exception ex ){
            System.Assert.fail( 'Exception is not expected. The following error occurred: ' + ex.getMessage() );
        }
    }

    @IsTest
    private static void execute_shouldRunSuccessfullyOnBeforeUpdate(){
        // Given - create data
        TestAccountsDomain accountsDomain = new TestAccountsDomain( new List<Account>{
            new Account( Id = fflib_IDGenerator.generate( Account.SObjectType ), Name = 'Luke', Description = 'Jedi' )
        } );

        // When, Then
        try{
            accountsDomain.handleBeforeUpdate( new Map<Id, SObject>( accountsDomain.getRecords() ) );
        } catch( Exception ex ){
            System.Assert.fail( 'Exception is not expected. The following error occurred: ' + ex.getMessage() );
        }
    }

    @IsTest
    private static void execute_shouldNotReinitializeHandlerOnBeforeUpdate(){
        // Given - create data
        TestAccountsDomain accountsDomain = new TestAccountsDomain( new List<Account>{
            new Account( Id = fflib_IDGenerator.generate( Account.SObjectType ), Name = 'Luke', Description = 'Jedi' )
        } );

        // When, Then
        try{
            accountsDomain.handleBeforeUpdate( new Map<Id, SObject>( accountsDomain.getRecords() ) );
            // Trigger handler a 2nd time, to ensure passthrough the performance saver for trigger handlers which implement FireOnce and
            // don't need to be initialized or finalized again
            accountsDomain.handleBeforeUpdate( new Map<Id, SObject>( accountsDomain.getRecords() ) );
        } catch( Exception ex ){
            System.Assert.fail( 'Exception is not expected. The following error occurred: ' + ex.getMessage() );
        }
    }

    @IsTest
    private static void execute_shouldRunHandlerRegisteredOnlyForAll(){
        // Given - create data. Domain with a handler registered only for TriggerEvent.ALL
        TestAllEventsDomain domain = new TestAllEventsDomain( new List<Account>{
            new Account( Name = 'Luke' )
        }, false );

        // When - perform test
        domain.handleBeforeInsert();

        // Then - validate
        System.Assert.areEqual( dummyAccountDescription, ( ( Account ) domain.getRecords()[ 0 ] ).Description,
            'Expected the handler registered for ALL to run for BEFORE_INSERT' );
    }

    @IsTest
    private static void execute_shouldNotDuplicateAllHandlersOnRepeat(){
        // Given - create data. Domain with a handler for BEFORE_INSERT and a counting handler for ALL
        TestAllEventsDomain domain = new TestAllEventsDomain( new List<Account>{
            new Account( Name = 'Luke' )
        }, true );
        countingProcessCount = 0;

        // When - perform test. The same domain instance executes the same event twice
        domain.handleBeforeInsert();
        domain.handleBeforeInsert();

        // Then - validate. The ALL handler ran once per execution, not once more each time
        System.Assert.areEqual( 2, countingProcessCount, 'Expected the ALL handler to run once per execution' );
    }

    @IsTest
    private static void Triggerhandler_EventMethods(){
        TestAccountBaseHandlerImpl beforeInsertHandler = new TestAccountBaseHandlerImpl();
        beforeInsertHandler.setTriggerEvent( dfflib_SObjectDomain.TriggerEvent.BEFORE_INSERT );

        System.Assert.areEqual( dfflib_SObjectDomain.TriggerEvent.BEFORE_INSERT, beforeInsertHandler.getTriggerEvent(), 'Expected TriggerEvent to match' );

        System.Assert.isTrue( beforeInsertHandler.isBefore(), 'Handler is Before Insert, so should be isBefore()' );
        System.Assert.isFalse( beforeInsertHandler.isAfter(), 'Handler is Before Insert, so should not be isAfter()' );
        System.Assert.isTrue( beforeInsertHandler.isInsert(), 'Handler is Before Insert, so should be isInsert()' );
        System.Assert.isFalse( beforeInsertHandler.isUpdate(), 'Handler is Before Insert, so should not be isUpdate()' );
        System.Assert.isFalse( beforeInsertHandler.isDelete(), 'Handler is Before Insert, so should not be isDelete()' );
        System.Assert.isFalse( beforeInsertHandler.isUndelete(), 'Handler is Before Insert, so should not be isUndelete()' );
    }

    @IsTest
    private static void Triggerhandler_disabling(){
        TestAccountBaseHandlerImpl beforeInsertHandler = new TestAccountBaseHandlerImpl();
        System.Assert.isTrue( beforeInsertHandler.isEnabled(), 'Expected Trigger to be enabled by default' );

        beforeInsertHandler.disable();
        System.Assert.isFalse( beforeInsertHandler.isEnabled(), 'Expected Trigger to be disabled() by function' );

        beforeInsertHandler.enable();
        System.Assert.isTrue( beforeInsertHandler.isEnabled(), 'Expected Trigger to be enabled() by function' );
    }

    @IsTest
    private static void Triggerhandler_errorHandlingToDomain(){
        TestAccountBaseHandlerImpl beforeInsertHandler = new TestAccountBaseHandlerImpl();
        dfflib_SObjectDomain fakeDomain = new TestAccountsDomain( new List<Account>() );
        beforeInsertHandler.useDomain( fakeDomain );
        beforeInsertHandler.error( 'Fake error', new Account() );
        beforeInsertHandler.error( 'Fake error on Name field', new Account(), Account.Name );

        System.Assert.areEqual( fakeDomain, beforeInsertHandler.getDomain(), 'Trigger set domain should be the input domain' );
        System.Assert.areEqual( 2, dfflib_SObjectDomain.Errors.getAll().size(), 'Expected two errors' );
    }

    /**
     * TEST AUXILIARY CLASSES/VARIABLES
     */
    private class TestAccountsDomain extends dfflib_SObjectDomain{
        public TestAccountsDomain( List<SObject> sObjectList ){
            super( sObjectList );

            registerHandler( TriggerEvent.BEFORE_INSERT, TestAccountBaseHandlerImpl.class );
            registerHandler( TriggerEvent.BEFORE_UPDATE, TestAccountBaseHandlerImpl.class );
        }

        public TestAccountsDomain( List<SObject> sObjectList, dfflib_ISObjectUnitOfWork uow ){
            super( sObjectList, uow );

            registerHandler( TriggerEvent.BEFORE_INSERT, TestAccountBaseHandlerImpl.class );
            registerHandler( TriggerEvent.BEFORE_UPDATE, TestAccountBaseHandlerImpl.class );
        }
    }

    /**
     * Domain whose handler is registered for TriggerEvent.ALL; optionally also with a BEFORE_INSERT handler.
     */
    private class TestAllEventsDomain extends dfflib_SObjectDomain{
        public TestAllEventsDomain( List<SObject> sObjectList, Boolean withEventSpecificHandler ){
            super( sObjectList );

            if( withEventSpecificHandler ){
                registerHandler( TriggerEvent.BEFORE_INSERT, TestAccountBaseHandlerImpl.class );
                registerHandler( TriggerEvent.ALL, TestCountingHandlerImpl.class );
            } else {
                registerHandler( TriggerEvent.ALL, TestAccountBaseHandlerImpl.class );
            }
        }
    }

    /**
     * Handler which counts how many records it processed.
     */
    private class TestCountingHandlerImpl extends dfflib_SObjectDomain.BaseHandler
        implements dfflib_SObjectDomain.BeforeInsert{

        public override Boolean process( SObject current, SObject original, dfflib_ISObjectUnitOfWork uow ){
            countingProcessCount++;

            return true;
        }
    }

    private static Integer countingProcessCount = 0;

    private static final String dummyAccountDescription = 'Just a dummy description, please ignore me!';

    /**
     * Base handler implementation for unit test purposes. Populates the description field on Account.
     */
    private class TestAccountBaseHandlerImpl extends dfflib_SObjectDomain.BaseHandler
        implements dfflib_SObjectDomain.FireOnce, dfflib_SObjectDomain.BeforeInsert, dfflib_SObjectDomain.BeforeUpdate{

        /**
         * This method will provide a dummy description to the account records in context
         *
         * @param   current     The account with the new trigger values assigned.
         * @param   original    The account with its previous trigger values.
         * @param   uow         Shared unit of work instance shared across all of the trigger handlers.
         * @return  Always true, the record has been processed, don't process it again.
         */
        public override Boolean process( SObject current, SObject original, dfflib_ISObjectUnitOfWork uow ){
            Account currentAccount = ( Account ) current;
            // Give the current account a dummy description
            currentAccount.Description = dummyAccountDescription;

            return true;
        }
    }

    /**
     * Base handler implementation for unit test purposes. Populates the description field on Account.
     */
    private class TestUnsupportedBaseHandlerImpl extends dfflib_SObjectDomain.BaseHandler
        implements dfflib_SObjectDomain.FireOnce{}
}