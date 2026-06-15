/**
 * Copyright (c), FinancialForce.com, inc
 * Copyright (c) 2026, Deloitte Consultative Services B.V.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 *   are permitted provided that the following conditions are met:
 *
 * - Redistributions of source code must retain the above copyright notice,
 *      this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright notice,
 *      this list of conditions and the following disclaimer in the documentation
 *      and/or other materials provided with the distribution.
 * - Neither the name of the FinancialForce.com inc, nor Deloitte Consultative Services B.V., nor the names of its contributors
 *      may be used to endorse or promote products derived from this software without
 *      specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 *  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 *  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
 *  THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 *  OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
@IsTest( isParallel = false )
private with sharing class fflib_SObjectDomainTest{
    @IsTest
    private static void testValidationWithoutDML(){
        // Given - create data
        fflib_SObjectDomain.TestSObjectDomain opps = new fflib_SObjectDomain.TestSObjectDomain(
            new List<Opportunity>{
                new Opportunity ( Name = 'Test', Type = 'Existing Account' )
            }
        );

        // When - perform test
        opps.onValidate();

        // Then - validate
        System.Assert.areEqual( 1, fflib_SObjectDomain.errorFactory.getAll().size() );
        System.Assert.areEqual( 'You must provide an Account for Opportunities for existing Customers.', fflib_SObjectDomain.errorFactory.getAll()[ 0 ].message );
        System.Assert.areEqual( Opportunity.AccountId, ( ( fflib_SObjectDomain.FieldError ) fflib_SObjectDomain.errorFactory.getAll()[ 0 ] ).field );

        // Given - create data
        opps = new fflib_SObjectDomain.TestSObjectDomain(
            new List<SObject>{
                new Opportunity( Name = 'Test', Type = 'Existing Account' )
            },
            Opportunity.SObjectType
        );

        // Then - validate
        System.Assert.areEqual( 1, fflib_SObjectDomain.errorFactory.getAll().size() );
        System.Assert.areEqual( 'You must provide an Account for Opportunities for existing Customers.', fflib_SObjectDomain.errorFactory.getAll()[ 0 ].message );
        System.Assert.areEqual( Opportunity.AccountId, ( ( fflib_SObjectDomain.FieldError ) fflib_SObjectDomain.errorFactory.getAll()[ 0 ] ).field );
    }

    @IsTest
    private static void testInsertValidationFailedWithoutDML(){
        // Given - create data
        Opportunity opp = new Opportunity ( Name = 'Test', Type = 'Existing Account' );
        System.Assert.isFalse( fflib_SObjectDomain.testFactory.database.hasRecords() );

        // When - perform test
        fflib_SObjectDomain.testFactory.database.onInsert( new List<Opportunity>{ opp } );
        System.Assert.isTrue( fflib_SObjectDomain.testFactory.database.hasRecords() );
        fflib_SObjectDomain.triggerHandler( fflib_SObjectDomain.TestSObjectDomainConstructor.class );

        // Then - validate
        System.Assert.areEqual( 1, fflib_SObjectDomain.errorFactory.getAll().size() );
        System.Assert.areEqual( 'You must provide an Account for Opportunities for existing Customers.', fflib_SObjectDomain.errorFactory.getAll()[ 0 ].message );
        System.Assert.areEqual( Opportunity.AccountId, ( ( fflib_SObjectDomain.FieldError ) fflib_SObjectDomain.errorFactory.getAll()[ 0 ] ).field );
    }

    @IsTest
    private static void testUpdateValidationFailedWithoutDML(){
        // Given - create data
        Opportunity oldOpp = new Opportunity( Name = 'Test', Type = 'Existing Account' );
        Opportunity newOpp = new Opportunity( Name = 'Test', Type = 'New Account' );
        System.Assert.isFalse( fflib_SObjectDomain.testFactory.database.hasRecords() );

        // When - perform test
        fflib_SObjectDomain.testFactory.database.onUpdate( new List<Opportunity>{ newOpp }, new Map<Id, SObject>{ newOpp.Id => oldOpp } );
        System.Assert.isTrue( fflib_SObjectDomain.testFactory.database.hasRecords() );
        fflib_SObjectDomain.triggerHandler( fflib_SObjectDomain.TestSObjectDomainConstructor.class );

        // Then - validate
        System.Assert.areEqual( 1, fflib_SObjectDomain.errorFactory.getAll().size() );
        System.Assert.areEqual( 'You cannot change the Opportunity type once it has been created.', fflib_SObjectDomain.errorFactory.getAll()[ 0 ].message );
        System.Assert.areEqual( Opportunity.Type, ( ( fflib_SObjectDomain.FieldError ) fflib_SObjectDomain.errorFactory.getAll()[ 0 ] ).field );
    }

    @IsTest
    private static void testOnBeforeDeleteWithoutDML(){
        // Given - create data
        Opportunity opp = new Opportunity( Name = 'Test', Type = 'Existing Account' );
        System.Assert.isFalse( fflib_SObjectDomain.testFactory.database.hasRecords() );

        // When - perform test
        fflib_SObjectDomain.testFactory.database.onDelete( new Map<Id, Opportunity>{ opp.Id => opp } );
        System.Assert.isTrue( fflib_SObjectDomain.testFactory.database.hasRecords() );
        fflib_SObjectDomain.triggerHandler( fflib_SObjectDomain.TestSObjectDomainConstructor.class );

        // Then - validate
        System.Assert.areEqual( 1, fflib_SObjectDomain.errorFactory.getAll().size() );
        System.Assert.areEqual( 'You cannot delete this Opportunity.', fflib_SObjectDomain.errorFactory.getAll()[ 0 ].message );
    }

    @IsTest
    private static void testOnAfterUndeleteWithoutDML(){
        // Given - create data
        Opportunity opp = new Opportunity( Name = 'Test', Type = 'Existing Account' );
        System.Assert.isFalse( fflib_SObjectDomain.testFactory.database.hasRecords() );

        // When - perform test
        fflib_SObjectDomain.testFactory.database.onUndelete( new List<Opportunity>{ opp } );

        // Then - validate
        System.Assert.isTrue( fflib_SObjectDomain.testFactory.database.hasRecords() );
        fflib_SObjectDomain.triggerHandler( fflib_SObjectDomain.TestSObjectDomainConstructor.class );
    }

    @IsTest
    private static void testObjectSecurity(){
        // Given - create data
        // Create a user which will not have access to the test object type
        User testUser = createChatterExternalUser();
        if( testUser == null ){
            return;
        } // Abort the test if unable to create a user with low enough access

        // When - perform test
        System.runAs( testUser ){
            // Test Create object security
            Opportunity opp = new Opportunity( Name = 'Test', Type = 'New Account' );
            fflib_SObjectDomain.testFactory.database.onInsert( new List<Opportunity>{ opp } );
            try{
                fflib_SObjectDomain.triggerHandler( fflib_SObjectDomain.TestSObjectDomainConstructor.class );
                System.Assert.fail( 'Expected access denied exception. This assertion should never be triggered' );
            } catch( Exception e ){
                System.Assert.areEqual( 'Permission to create an Opportunity denied.', e.getMessage() );
            }

            // Test Update object security
            fflib_SObjectDomain.testFactory.database.onUpdate( new List<Opportunity>{ opp }, new Map<Id, Opportunity>{ opp.Id => opp } );
            try{
                fflib_SObjectDomain.triggerHandler( fflib_SObjectDomain.TestSObjectDomainConstructor.class );
                System.Assert.fail( 'Expected access denied exception. This assertion should never be triggered' );
            } catch( Exception e ){
                System.Assert.areEqual( 'Permission to update an Opportunity denied.', e.getMessage() );
            }

            // Then - validate
            // Test Delete object security
            fflib_SObjectDomain.testFactory.database.onDelete( new Map<Id, Opportunity>{ opp.Id => opp } );
            try{
                fflib_SObjectDomain.triggerHandler( fflib_SObjectDomain.TestSObjectDomainConstructor.class );
                System.Assert.fail( 'Expected access denied exception. This assertion should never be triggered' );
            } catch( Exception e ){
                System.Assert.areEqual( 'Permission to delete an Opportunity denied.', e.getMessage() );
            }

            // Then - validate
            // Test Undelete object security
            fflib_SObjectDomain.testFactory.database.onUndelete( new List<Opportunity>{ opp } );
            try{
                fflib_SObjectDomain.triggerHandler( fflib_SObjectDomain.TestSObjectDomainConstructor.class );
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
        fflib_SObjectDomain.errorFactory.error( 'Error', opp );
        fflib_SObjectDomain.errorFactory.error( 'Error', opp, Opportunity.Type );
        System.Assert.areEqual( 2, fflib_SObjectDomain.errorFactory.getAll().size() );
        System.Assert.areEqual( 'Error', fflib_SObjectDomain.errorFactory.getAll()[ 0 ].message );
        System.Assert.areEqual( 'Error', fflib_SObjectDomain.errorFactory.getAll()[ 1 ].message );

        // When - perform test
        System.Assert.areEqual( Opportunity.Type, ( ( fflib_SObjectDomain.FieldError ) fflib_SObjectDomain.errorFactory.getAll()[ 1 ] ).field );
        fflib_SObjectDomain.errorFactory.clearAll();

        // Then - validate
        System.Assert.areEqual( 0, fflib_SObjectDomain.errorFactory.getAll().size() );
    }

    @IsTest
    private static void testTriggerState(){
        // Given - create data
        Opportunity opp = new Opportunity ( Name = 'Test', Type = 'Existing Account' );

        // When - perform test
        fflib_SObjectDomain.testFactory.database.onInsert( new List<Opportunity>{ opp } );
        fflib_SObjectDomain.triggerHandler( fflib_SObjectDomain.TestSObjectStatefulDomainConstructor.class );

        // Then - validate
        System.Assert.areEqual( 1, fflib_SObjectDomain.errorFactory.getAll().size() );
        System.Assert.areEqual( 'Error on Record Test', fflib_SObjectDomain.errorFactory.getAll()[ 0 ].message );
    }

    @IsTest
    private static void testRecursiveTriggerState(){
        // Given - create data
        Opportunity opp = new Opportunity ( Name = 'Test Recursive 1', Type = 'Existing Account' );

        // When - perform test
        fflib_SObjectDomain.testFactory.database.onInsert( new List<Opportunity>{ opp } );
        fflib_SObjectDomain.triggerHandler( fflib_SObjectDomain.TestSObjectStatefulDomainConstructor.class );

        // Then - validate
        System.Assert.areEqual( 2, fflib_SObjectDomain.errorFactory.getAll().size() );
        System.Assert.areEqual( 'Error on Record Test Recursive 2', fflib_SObjectDomain.errorFactory.getAll()[ 0 ].message );
        System.Assert.areEqual( 'Error on Record Test Recursive 1', fflib_SObjectDomain.errorFactory.getAll()[ 1 ].message );
    }

    @IsTest
    private static void testOnValidateBehaviorDefault(){
        // Given - create data
        Opportunity oldOpp = new Opportunity( Name = 'Test Default Behaviour', Type = 'Existing Account' );
        Opportunity newOpp = new Opportunity( Name = 'Test Default Behaviour', Type = 'New Account' );

        // When - perform test
        fflib_SObjectDomain.testFactory.database.onUpdate( new List<Opportunity>{ newOpp }, new Map<Id, SObject>{ newOpp.Id => oldOpp } );
        fflib_SObjectDomain.triggerHandler( fflib_SObjectDomain.TestSObjectOnValidateBehaviourConstructor.class );
    }

    @IsTest
    private static void testOnValidateBehaviorOld(){
        // Given - create data
        Opportunity oldOpp = new Opportunity( Name = 'Test Enable Old Behaviour', Type = 'Existing Account' );
        Opportunity newOpp = new Opportunity( Name = 'Test Enable Old Behaviour', Type = 'New Account' );

        // When - perform test
        fflib_SObjectDomain.testFactory.database.onUpdate( new List<Opportunity>{ newOpp }, new Map<Id, SObject>{ newOpp.Id => oldOpp } );
        try{
            fflib_SObjectDomain.triggerHandler( fflib_SObjectDomain.TestSObjectOnValidateBehaviourConstructor.class );
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
        System.Assert.isFalse( fflib_SObjectDomain.testFactory.database.hasRecords() );
        fflib_SObjectDomain.testFactory.database.onInsert( new List<Account>{ acct1, acct2 } );
        System.Assert.isTrue( fflib_SObjectDomain.testFactory.database.hasRecords() );
        fflib_SObjectDomain.triggerHandler( fflib_SObjectDomain.TestSObjectChangedRecordsConstructor.class );
        Account acct1changed = acct1.clone(),
            acct2changed = acct2.clone();
        acct1changed.Name = 'Test1changed';
        // When, Then
        fflib_SObjectDomain.testFactory.database.onUpdate(
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
        TestAccountsDomain accounts = new TestAccountsDomain( newRecords, fflib.unitOfWork.newInstance() );
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
        TestAccountsDomain accounts = new TestAccountsDomain( newRecords, fflib.unitOfWork.newInstance() );
        fflib_SObjectDomain.testFactory.database.onUpdate( newRecords, new Map<Id, SObject>( oldRecords ) );

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

        fflib_ISObjectUnitOfWork uow = fflib.unitOfWork.newInstance( new List<SObjectType>{ User.SObjectType } );
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
            fflib_SObjectDomain.getTriggerEvent( fflib_SObjectDomain.TestSObjectDisableBehaviourConstructor.class ).disableAll();
            fflib_SObjectDomain.testFactory.database.onInsert( new List<Opportunity>{ newOpp } );
            fflib_SObjectDomain.triggerHandler( fflib_SObjectDomain.TestSObjectDisableBehaviourConstructor.class );
        } catch( Exception e ){
            bError = true;
        }

        // Then - validate
        System.Assert.isFalse( bError, 'Error - Trigger events have been fired when they are disabled' );

        ////////////////////////////
        // Insert!
        try{
            // now lets go after insert and then before
            fflib_SObjectDomain.getTriggerEvent( fflib_SObjectDomain.TestSObjectDisableBehaviourConstructor.class ).enableAfterInsert();
            fflib_SObjectDomain.testFactory.database.onInsert( new List<Opportunity>{ newOpp } );
            fflib_SObjectDomain.triggerHandler( fflib_SObjectDomain.TestSObjectDisableBehaviourConstructor.class );
        } catch( Exception e ){
            sErrorMessage = e.getMessage();
        }

        System.Assert.areEqual( 'onAfterInsert called', sErrorMessage, 'Error - After Insert Event is enabled but did not run' );

        try{
            // now lets go after insert and then before
            fflib_SObjectDomain.getTriggerEvent( fflib_SObjectDomain.TestSObjectDisableBehaviourConstructor.class ).enableBeforeInsert();
            fflib_SObjectDomain.testFactory.database.onInsert( new List<Opportunity>{ newOpp } );
            fflib_SObjectDomain.triggerHandler( fflib_SObjectDomain.TestSObjectDisableBehaviourConstructor.class );
        } catch( Exception e ){
            sErrorMessage = e.getMessage();
        }

        System.Assert.areEqual( 'onBeforeInsert called', sErrorMessage, 'Error - Before Insert Event is enabled but did not run' );

        ////////////////////////////
        // Update!
        try{
            // now lets go after insert and then before
            fflib_SObjectDomain.getTriggerEvent( fflib_SObjectDomain.TestSObjectDisableBehaviourConstructor.class ).enableAfterUpdate();
            fflib_SObjectDomain.testFactory.database.onUpdate( new List<Opportunity>{ newOpp }, new Map<Id, SObject>{ newOpp.Id => oldOpp } );
            fflib_SObjectDomain.triggerHandler( fflib_SObjectDomain.TestSObjectDisableBehaviourConstructor.class );
        } catch( Exception e ){
            sErrorMessage = e.getMessage();
        }

        System.Assert.areEqual( 'onAfterUpdate called', sErrorMessage, 'Error - After Update Event is enabled but did not run' );

        try{
            // now lets go after insert and then before
            fflib_SObjectDomain.getTriggerEvent( fflib_SObjectDomain.TestSObjectDisableBehaviourConstructor.class ).enableBeforeUpdate();
            fflib_SObjectDomain.testFactory.database.onUpdate( new List<Opportunity>{ newOpp }, new Map<Id, SObject>{ newOpp.Id => oldOpp } );
            fflib_SObjectDomain.triggerHandler( fflib_SObjectDomain.TestSObjectDisableBehaviourConstructor.class );
        } catch( Exception e ){
            sErrorMessage = e.getMessage();
        }

        System.Assert.areEqual( 'onBeforeUpdate called', sErrorMessage, 'Error - Before Update Event is enabled but did not run' );

        ////////////////////////////
        // Delete!
        try{
            // now lets go after insert and then before
            fflib_SObjectDomain.getTriggerEvent( fflib_SObjectDomain.TestSObjectDisableBehaviourConstructor.class ).enableAfterDelete();
            fflib_SObjectDomain.testFactory.database.onDelete( new Map<Id, Opportunity>{ newOpp.Id => newOpp } );
            fflib_SObjectDomain.triggerHandler( fflib_SObjectDomain.TestSObjectDisableBehaviourConstructor.class );
        } catch( Exception e ){
            sErrorMessage = e.getMessage();
        }

        System.Assert.areEqual( 'onAfterDelete called', sErrorMessage, 'Error - After Delete Event is enabled but did not run' );

        try{
            // now lets go after insert and then before
            fflib_SObjectDomain.getTriggerEvent( fflib_SObjectDomain.TestSObjectDisableBehaviourConstructor.class ).enableBeforeDelete();
            fflib_SObjectDomain.testFactory.database.onDelete( new Map<Id, Opportunity>{ newOpp.Id => newOpp } );
            fflib_SObjectDomain.triggerHandler( fflib_SObjectDomain.TestSObjectDisableBehaviourConstructor.class );
        } catch( Exception e ){
            sErrorMessage = e.getMessage();
        }

        System.Assert.areEqual( 'onBeforeDelete called', sErrorMessage, 'Error - Before Delete Event is enabled but did not run' );

        ////////////////////////////
        // Undelete!
        try{
            // now lets go after insert and then before
            fflib_SObjectDomain.getTriggerEvent( fflib_SObjectDomain.TestSObjectDisableBehaviourConstructor.class ).enableAfterUndelete();
            fflib_SObjectDomain.testFactory.database.onUndelete( new List<Opportunity>{ newOpp } );
            fflib_SObjectDomain.triggerHandler( fflib_SObjectDomain.TestSObjectDisableBehaviourConstructor.class );
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
            fflib_SObjectDomain.TriggerEvent.BEFORE_INSERT,
            accountMap,
            fflib.unitOfWork.newInstance()
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
                fflib_SObjectDomain.TriggerEvent.BEFORE_INSERT,
                accountMap,
                fflib.unitOfWork.newInstance()
            );
        } catch( Exception e ){
            sErrorMessage = e.getMessage();
        }

        System.Assert.areEqual( 'Handler fflib_SObjectDomainTest.TestUnsupportedBaseHandlerImpl does not support the trigger event BEFORE_INSERT', sErrorMessage );
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
    private static void Triggerhandler_EventMethods(){
        TestAccountBaseHandlerImpl beforeInsertHandler = new TestAccountBaseHandlerImpl();
        beforeInsertHandler.setTriggerEvent( fflib_SObjectDomain.TriggerEvent.BEFORE_INSERT );

        System.Assert.areEqual( fflib_SObjectDomain.TriggerEvent.BEFORE_INSERT, beforeInsertHandler.getTriggerEvent(), 'Expected TriggerEvent to match' );

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
        fflib_SObjectDomain fakeDomain = new TestAccountsDomain( new List<Account>() );
        beforeInsertHandler.useDomain( fakeDomain );
        beforeInsertHandler.error( 'Fake error', new Account() );
        beforeInsertHandler.error( 'Fake error on Name field', new Account(), Account.Name );

        System.Assert.areEqual( fakeDomain, beforeInsertHandler.getDomain(), 'Trigger set domain should be the input domain' );
        System.Assert.areEqual( 2, fflib_SObjectDomain.errorFactory.getAll().size(), 'Expected two errors' );
    }

    /**
     * TEST AUXILIARY CLASSES/VARIABLES
     */
    private class TestAccountsDomain extends fflib_SObjectDomain{
        public TestAccountsDomain( List<SObject> sObjectList ){
            super( sObjectList );

            registerHandler( TriggerEvent.BEFORE_INSERT, TestAccountBaseHandlerImpl.class );
            registerHandler( TriggerEvent.BEFORE_UPDATE, TestAccountBaseHandlerImpl.class );
        }

        public TestAccountsDomain( List<SObject> sObjectList, fflib_ISObjectUnitOfWork uow ){
            super( sObjectList, uow );

            registerHandler( TriggerEvent.BEFORE_INSERT, TestAccountBaseHandlerImpl.class );
            registerHandler( TriggerEvent.BEFORE_UPDATE, TestAccountBaseHandlerImpl.class );
        }
    }

    private static final String dummyAccountDescription = 'Just a dummy description, please ignore me!';

    /**
     * Base handler implementation for unit test purposes. Populates the description field on Account.
     */
    private class TestAccountBaseHandlerImpl extends fflib_SObjectDomain.BaseHandler
        implements fflib_SObjectDomain.FireOnce, fflib_SObjectDomain.BeforeInsert, fflib_SObjectDomain.BeforeUpdate{

        /**
         * This method will provide a dummy description to the account records in context
         *
         * @param   current     The account with the new trigger values assigned.
         * @param   original    The account with its previous trigger values.
         * @param   uow         Shared unit of work instance shared across all of the trigger handlers.
         * @return  Always true, the record has been processed, don't process it again.
         */
        public override Boolean process( SObject current, SObject original, fflib_ISObjectUnitOfWork uow ){
            Account currentAccount = ( Account ) current;
            // Give the current account a dummy description
            currentAccount.Description = dummyAccountDescription;

            return true;
        }
    }

    /**
     * Base handler implementation for unit test purposes. Populates the description field on Account.
     */
    private class TestUnsupportedBaseHandlerImpl extends fflib_SObjectDomain.BaseHandler
        implements fflib_SObjectDomain.FireOnce{}
}