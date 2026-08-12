/**
 * Copyright (c), FinancialForce.com, inc
 * Copyright (c), Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
/**
 * Test class for Unit of Work
 * Completely rewritten to apply fflib_Database_DMLProxy and eliminate any DMLs previously applied, and allowing isParallel
 * All DML tests are performed in fflib_Database_TEST
 *
 * - Can't test PlatformEvents as this is project specific
 *
 * @author    Reinier van den Assum (rvandenassum@deloitte.nl)
 * @created   June 2023
 */
@IsTest( isParallel = true )
private with sharing class fflib_SObjectUnitOfWorkTest{
    private static final Id ID_ACCOUNT = fflib_IDGenerator.generate( Account.SObjectType );
    private static final Id ID_ACCOUNT2 = fflib_IDGenerator.generate( Account.SObjectType );
    private static final Id ID_CONTACT = fflib_IDGenerator.generate( Contact.SObjectType );
    private static final Id ID_LEAD = fflib_IDGenerator.generate( Lead.SObjectType );

    @IsTest
    private static void constructors_sharing_dmlProxy(){
        // --- Proxy type + AccessLevel contract per context (API v67.0 regression anchors) ---

        // INHERIT — SYSTEM_MODE + InheritSimpleDML (default context)
        fflib_SObjectUnitOfWork uowInherit = new fflib_SObjectUnitOfWork( fflib_Database.Context.INHERIT );
        System.Assert.isInstanceOfType( uowInherit.m_dml, fflib_Database_DMLProxy.InheritSimpleDML.class,
            'INHERIT context must use InheritSimpleDML proxy' );
        System.Assert.areEqual( fflib_Database.Context.INHERIT, uowInherit.m_securityContext,
            'Expected INHERIT security context to be set' );

        // FULL — USER_MODE + WithSimpleDML
        fflib_SObjectUnitOfWork uowFull = new fflib_SObjectUnitOfWork( fflib_Database.Context.FULL );
        System.Assert.isInstanceOfType( uowFull.m_dml, fflib_Database_DMLProxy.WithSimpleDML.class,
            'FULL context must use WithSimpleDML proxy' );
        System.Assert.areEqual( fflib_Database.Context.FULL, uowFull.m_securityContext,
            'Expected FULL security context to be set' );

        // NONE — SYSTEM_MODE + WithoutSimpleDML
        fflib_SObjectUnitOfWork uowNone = new fflib_SObjectUnitOfWork( fflib_Database.Context.NONE );
        System.Assert.isInstanceOfType( uowNone.m_dml, fflib_Database_DMLProxy.WithoutSimpleDML.class,
            'NONE context must use WithoutSimpleDML proxy' );
        System.Assert.areEqual( fflib_Database.Context.NONE, uowNone.m_securityContext,
            'Expected NONE security context to be set' );

        // SHARING_SKIP_PERMISSIONS — SYSTEM_MODE + WithSimpleDML
        fflib_SObjectUnitOfWork uowSkip = new fflib_SObjectUnitOfWork( fflib_Database.Context.SHARING_SKIP_PERMISSIONS );
        System.Assert.isInstanceOfType( uowSkip.m_dml, fflib_Database_DMLProxy.WithSimpleDML.class,
            'SHARING_SKIP_PERMISSIONS context must use WithSimpleDML proxy' );
        System.Assert.areEqual( fflib_Database.Context.SHARING_SKIP_PERMISSIONS, uowSkip.m_securityContext,
            'Expected SHARING_SKIP_PERMISSIONS security context to be set' );

        // --- Constructor equivalence — verifies that different constructor paths produce the same proxy instance.
        //     securityContext equality per context is already pinned in the proxy-contract section above.
        fflib_SObjectUnitOfWork uowBase_Inherit = new fflib_SObjectUnitOfWork();
        System.Assert.areEqual( uowBase_Inherit.m_dml, uowInherit.m_dml,
            'Expected UOW() to default to inherit sharing, matching the UOW( INHERIT ) constructor' );

        List<SObjectType> dummyList = new List<SObjectType>{ Account.SObjectType };
        fflib_SObjectUnitOfWork uowList_Inherit = new fflib_SObjectUnitOfWork( dummyList );
        fflib_SObjectUnitOfWork uowListProvided_Inherit = new fflib_SObjectUnitOfWork( dummyList, fflib_Database.Context.INHERIT );
        System.Assert.areEqual( uowList_Inherit.m_dml, uowListProvided_Inherit.m_dml,
            'Expected UOW( list ) to default to inherit sharing, matching the UOW( list, INHERIT ) constructor' );

        fflib_SObjectUnitOfWork uowBase_setContextFull = new fflib_SObjectUnitOfWork();
        uowBase_setContextFull.setContext( fflib_Database.Context.FULL );
        System.Assert.areEqual( uowBase_setContextFull.m_dml, uowFull.m_dml,
            'Expected UOW().setContext( FULL ) to match the UOW( FULL ) constructor' );

        fflib_SObjectUnitOfWork uowBase_setContextWithSkip = new fflib_SObjectUnitOfWork();
        uowBase_setContextWithSkip.setContext( fflib_Database.Context.SHARING_SKIP_PERMISSIONS );
        System.Assert.areEqual( uowBase_setContextWithSkip.m_dml, uowSkip.m_dml,
            'Expected UOW().setContext( SHARING_SKIP_PERMISSIONS ) to match the UOW( SHARING_SKIP_PERMISSIONS ) constructor' );

        fflib_SObjectUnitOfWork uowList_None = new fflib_SObjectUnitOfWork( dummyList, fflib_Database.Context.NONE );
        System.Assert.areEqual( uowNone.m_dml, uowList_None.m_dml,
            'Expected UOW( NONE ) to match UOW( list, NONE ) constructor' );
    }

    @IsTest
    private static void constructor_List_reset(){
        fflib_SObjectUnitOfWork uow_ListDuplicate = new fflib_SObjectUnitOfWork( new List<SObjectType>{ Contact.SObjectType, Account.SObjectType } );
        List<SObjectType> uowTypes = uow_ListDuplicate.m_sObjectTypes;
        System.Assert.areEqual( 2, uowTypes.size(), 'Expected two SObjectTypes to be set' );
        System.Assert.areEqual( Contact.SObjectType, uowTypes[ 0 ], 'Expected Contact as 1st SObjectType' );
        System.Assert.areEqual( Account.SObjectType, uowTypes[ 1 ], 'Expected Account as 2nd SObjectType' );

        uow_ListDuplicate.resetWork();
        System.Assert.areEqual( 2, uow_ListDuplicate.m_sObjectTypes?.size(), 'Expected still 2 SObjectTypes as provided via Constructor so should never be reset' );
    }

    @IsTest
    private static void constructor_List_duplicate(){
        try{
            new fflib_SObjectUnitOfWork( new List<SObjectType>{ Account.SObjectType, Account.SObjectType } );
            System.Assert.fail( 'Should never happen as duplicate SObjectType was provided to UOW' );
        } catch( fflib_SObjectUnitOfWork.UnitOfWorkException ex ){
            System.Assert.areEqual( ex.getMessage(), 'Duplicate SObjectType defined within provided List of SObjectTypes', 'Expected different Exception message' );
        }
    }

    @IsTest
    private static void fetchUnitOfWorkConfigs(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ApplicationConfig m_ApplicationConfig = ( fflib_ApplicationConfig ) mocks.mock( fflib_ApplicationConfig.class );

        // Given - create data
        List<FFLIB_UOW_Config__mdt> uowConfigsMocked = new List<FFLIB_UOW_Config__mdt>{
            new FFLIB_UOW_Config__mdt( SObjectType__c = 'Account', SortOrder__c = 0 ),
            new FFLIB_UOW_Config__mdt( SObjectType__c = 'Contact', SortOrder__c = 1 )
        };

        // Set mocks and inject into application config
        mocks.startStubbing();
        mocks.when( m_ApplicationConfig.getUnitOfWorkConfigs() ).thenReturn( uowConfigsMocked );
        mocks.stopStubbing();
        fflib_Application.appConfig = m_ApplicationConfig;

        // When - Construct a metadata-driven UOW via the factory — configs are now injected by the factory
        fflib_SObjectUnitOfWork uow = ( fflib_SObjectUnitOfWork ) fflib.unitOfWork.newInstance();

        // Then - Validate getUnitOfWorkConfigs() was called once (by the factory) and the configs are on the UOW instance
        ( ( fflib_ApplicationConfig ) mocks.verify( m_ApplicationConfig, 1 ) ).getUnitOfWorkConfigs();
        System.Assert.areEqual( uowConfigsMocked, uow.uowConfigs, 'Expected the injected configs to match the mocked configs' );
    }

    @IsTest
    private static void implementSObjectType_correctSequence(){
        // Given - inject UOW configs via the factory's appConfig mock (avoids real metadata query)
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ApplicationConfig m_ApplicationConfig = ( fflib_ApplicationConfig ) mocks.mock( fflib_ApplicationConfig.class );
        mocks.startStubbing();
        mocks.when( m_ApplicationConfig.getUnitOfWorkConfigs() ).thenReturn( new List<FFLIB_UOW_Config__mdt>{
            new FFLIB_UOW_Config__mdt( SObjectType__c = 'Account', SortOrder__c = 1 ),
            new FFLIB_UOW_Config__mdt( SObjectType__c = 'Contact', SortOrder__c = 2 ),
            new FFLIB_UOW_Config__mdt( SObjectType__c = 'Case', SortOrder__c = 3 )
        } );
        mocks.stopStubbing();
        fflib_Application.appConfig = m_ApplicationConfig;

        // Initiate UOW via fflib-newInstance initiator — factory resolves and injects configs
        fflib_SObjectUnitOfWork uow = ( fflib_SObjectUnitOfWork ) fflib.unitOfWork.newInstance();

        // When + Then: First adding second object, expecting it to be the one and only in m_sobjectTypes list
        uow.implementSObjectType( Case.SObjectType, fflib_SObjectUnitOfWork.DMLActions.dNEW );
        System.Assert.areEqual( 1, uow.m_sObjectTypes.size(), 'Expected one SObjectType registered' );
        System.Assert.areEqual( Case.SObjectType, uow.m_sObjectTypes[ 0 ], 'Expected Case on first index' );

        // When + Then: Second adding first object, expecting it to come first and Contact second
        uow.implementSObjectType( Account.SObjectType, fflib_SObjectUnitOfWork.DMLActions.dNEW );
        System.Assert.areEqual( 2, uow.m_sObjectTypes.size(), 'Expected two SObjectType registered' );
        System.Assert.areEqual( Account.SObjectType, uow.m_sObjectTypes[ 0 ], 'Expected Account to have become first index' );
        System.Assert.areEqual( Case.SObjectType, uow.m_sObjectTypes[ 1 ], 'Expected Case to have become second index' );

        // When + Then: Third adding second object, expecting it to come in between the other two
        uow.implementSObjectType( Contact.SObjectType, fflib_SObjectUnitOfWork.DMLActions.dNEW );
        System.Assert.areEqual( 3, uow.m_sObjectTypes.size(), 'Expected two SObjectType registered' );
        System.Assert.areEqual( Account.SObjectType, uow.m_sObjectTypes[ 0 ], 'Expected Account to have remained first index' );
        System.Assert.areEqual( Contact.SObjectType, uow.m_sObjectTypes[ 1 ], 'Expected Contact to have become second index' );
        System.Assert.areEqual( Case.SObjectType, uow.m_sObjectTypes[ 2 ], 'Expected Case to have become third index' );

        // When + Then: Lastly, adding invalid SObjectType, expecting Exception to be thrown
        try{
            uow.registerNew( new ApexClass() );
            System.Assert.fail( 'Since ApexClass is not specified in the UOW Configs, an Exception is expected' );
        } catch( fflib_SObjectUnitOfWork.UnitOfWorkException ex ){
            System.Assert.isTrue( ex.getMessage().contains( 'is not (yet) registered for this Unit of Work' ), 'Expected different message ' + ex.getMessage() );
        }
    }

    @IsTest
    private static void implementSObjectType_exception_invalidEventActionForSObject(){
        try{
            new fflib_SObjectUnitOfWork().implementSObjectType( Event.SObjectType, fflib_SObjectUnitOfWork.DMLActions.dPUB_AFTER_SUCCESS );
            System.Assert.fail( 'Since the standard object Event can\'t be published, only Events can, an Exception is expected' );
        } catch( fflib_SObjectUnitOfWork.UnitOfWorkException ex ){
            System.Assert.isTrue( ex.getMessage().contains( 'are not allowed to be registered for publish, but should use registerNew()' ), 'Expected different message ' + ex.getMessage() );
        }
    }

    @IsTest
    private static void implementSObjectType_exception_invalidDMLActionForEvent(){
        SObjectType eventSObjectType = BatchApexErrorEvent.SObjectType;
        try{
            // Try to Database.insert() an Event - which should cause an Exception
            new fflib_SObjectUnitOfWork().implementSObjectType( eventSObjectType, fflib_SObjectUnitOfWork.DMLActions.dNEW );
            System.Assert.fail( 'Since Account is \'faked\' to be an Event, and Events should be published instead of inserted, an Exception is expected' );
        } catch( fflib_SObjectUnitOfWork.UnitOfWorkException ex ){
            System.Assert.areEqual( 'PlatformEvents like ' + eventSObjectType.getDescribe().getName() + ' should be registered via a registerPublish...() method', ex.getMessage(), 'Expected different exception message' );
        }
    }

    @IsTest
    private static void implementSObjectType_exception_missingSObjectTypeInConstructorList(){
        try{
            new fflib_SObjectUnitOfWork( new List<SObjectType>{ Account.SObjectType } )
                .implementSObjectType( Contact.SObjectType, fflib_SObjectUnitOfWork.DMLActions.dUPDATE );
            System.Assert.fail( 'Since Contact isn\'t included in provided SObjectType list, an Exception is expected' );
        } catch( fflib_SObjectUnitOfWork.UnitOfWorkException ex ){
            System.Assert.isTrue( ex.getMessage().contains( 'was not specified in the Constructor-list' ), 'Expected different message ' + ex.getMessage() );
        }
    }

    @IsTest
    private static void validateRecordForDMLAction_exceptionExistingRecordInsert(){
        try{
            Account accWithId = new Account( Id = ID_ACCOUNT );
            new fflib_SObjectUnitOfWork().validateRecordForDMLAction( accWithId, fflib_SObjectUnitOfWork.DMLActions.dNEW_IMMEDIATE, null );
            System.Assert.fail( 'An Exception is expected as an existing record (with Id) was registered for insertions' );
        } catch( fflib_SObjectUnitOfWork.UnitOfWorkException ex ){
            System.Assert.areEqual( 'Only new records can be registered as new', ex.getMessage(), 'Expected different message' );
        }
    }

    @IsTest
    private static void validateRecordForDMLAction_exceptionNewRecords(){
        Account acc = new Account();
        try{
            new fflib_SObjectUnitOfWork().validateRecordForDMLAction( acc, fflib_SObjectUnitOfWork.DMLActions.dUPDATE, null );
            System.Assert.fail( 'An Exception is expected as a new record (without Id) was registered for update' );
        } catch( fflib_SObjectUnitOfWork.UnitOfWorkException ex ){
            System.Assert.areEqual( 'New records cannot be registered as dirty', ex.getMessage(), 'Expected different message' );
        }
        try{
            new fflib_SObjectUnitOfWork().validateRecordForDMLAction( acc, fflib_SObjectUnitOfWork.DMLActions.dDELETE, null );
            System.Assert.fail( 'An Exception is expected as a new record (without Id) was registered for deletion' );
        } catch( fflib_SObjectUnitOfWork.UnitOfWorkException ex ){
            System.Assert.areEqual( 'New records cannot be registered for dDELETE', ex.getMessage(), 'Expected different message' );
        }
        try{
            new fflib_SObjectUnitOfWork().validateRecordForDMLAction( acc, null, null );
            System.Assert.fail( 'An Exception is expected as a new record (without Id) was registered for a non-existing DMLActions' );
        } catch( fflib_SObjectUnitOfWork.UnitOfWorkException ex ){
            System.Assert.areEqual( 'No matching DMLAction', ex.getMessage(), 'Expected different message' );
        }
    }

    /**
     * Method to verify:
     * 1) Whether UOW executes in the correct sequence given an constructor-input-list
     * 2) Whether the objects are properly registered and resulting in correct DML Operations - first Priority, then normal
     * 3) Whether the relationships are properly processed
     */
    @IsTest
    private static void registerPriorityNew_Relation_Sequence(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_Database_IDML m_IDML = ( fflib_Database_IDML ) mocks.mock( fflib_Database_IDML.class );

        // Given - create data
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork( new List<SObjectType>{ Lead.SObjectType, Account.SObjectType, Contact.SObjectType } );
        Account acc = new Account( Name = 'test' );
        Contact con = new Contact();
        Lead l = new Lead();

        // Set mocks - no method stubbing as no SaveResults are needed
        uow.m_dml = m_IDML;

        // When - Register Account and Contact with a relationship to the Account
        uow.registerPriorityNew( new List<Account>{ acc } );
        uow.registerPriorityNew( con, Contact.AccountId, acc );
        uow.registerNew( l );

        // Then - validate whether the Relationship was properly stored - before commitWork() as otherwise UOW is already reset
        Map<SObjectType, List<fflib_SObjectUnitOfWork.IRelationship>> relationsList = uow.m_relationships;
        System.Assert.areEqual( 1, relationsList.size(), 'Expected one relation to be listed' );
        fflib_SObjectUnitOfWork.Relationship r = ( fflib_SObjectUnitOfWork.Relationship ) relationsList.get( Contact.SObjectType )[ 0 ];
        System.Assert.areEqual( con, r.getRecord(), 'Expected Relation to be defined on the provided Contact' );

        // When & Then - perform commitWork() to verify the sequence of SObjects being inserted and whether the right parameters were provided to IDML class
        uow.commitWork();

        // Validate performAction was called exactly 3x and validate the sequence of DMLActions and SObjectTypes afterwards, and default null DMLOptions
        fflib_ArgumentCaptor captorDMLActions = new fflib_ArgumentCaptor();
        fflib_ArgumentCaptor captorSObjectLists = new fflib_ArgumentCaptor();
        ( ( fflib_Database_IDML ) mocks.verify( m_IDML, 3 ) ).performDMLAction(
            ( fflib_SObjectUnitOfWork.DMLActions ) captorDMLActions.capture(),
            ( List<SObject> ) captorSObjectLists.capture(),
            ( Database.DMLOptions ) fflib_Match.isNull(),
            ( AccessLevel ) fflib_Match.eq( fflib_Database.getAccessLevel( uow.m_securityContext ) )
        );
        List<Object> enteredDMLActions = captorDMLActions.getAllValues();
        List<Object> enteredSObjects = captorSObjectLists.getAllValues();

        // Validate Account was registered with priority first
        System.Assert.areEqual( fflib_SObjectUnitOfWork.DMLActions.dNEW_PRIO, enteredDMLActions[ 0 ], 'Expected 1st performAction to be called with priority new' );
        System.Assert.areEqual( acc, ( ( List<SObject> ) enteredSObjects[ 0 ] )[ 0 ], 'Expected 1st SObject called for DML operation to be the Account' );

        // Validate Contact was registered with priority second
        System.Assert.areEqual( fflib_SObjectUnitOfWork.DMLActions.dNEW_PRIO, enteredDMLActions[ 1 ], 'Expected 2nd performAction to be called with priority new' );
        System.Assert.areEqual( con, ( ( List<SObject> ) enteredSObjects[ 1 ] )[ 0 ], 'Expected 2nd SObject called for DML operation to be the Contact' );

        // Validate Lead was registered last without, despite being the first SObjectType in list to be performed
        System.Assert.areEqual( fflib_SObjectUnitOfWork.DMLActions.dNEW, enteredDMLActions[ 2 ], 'Expected new DMLAction to be called after all priority news' );
        System.Assert.areEqual( l, ( ( List<SObject> ) enteredSObjects[ 2 ] )[ 0 ], 'Expected 3rd SObject called for DML operation to be the Lead, despite first in SObjectType list' );
        System.Assert.areEqual( Lead.SObjectType, uow.m_sObjectTypes[ 0 ], 'Expected Lead to be set as first SObjectType' );
    }

    /**
     * Method to verify:
     * 1) Whether UOW executes in the correct sequence given an constructor-input-list
     * 2) Whether the objects are properly registered and resulting in correct DML Operations
     * 3) Whether the relationships are properly processed
     */
    @IsTest
    private static void registerNew_Relation_Sequence(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_Database_IDML m_IDML = ( fflib_Database_IDML ) mocks.mock( fflib_Database_IDML.class );

        // Given - create data
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork( new List<SObjectType>{ Account.SObjectType, Contact.SObjectType } );
        Account acc = new Account( Name = 'test' );
        Contact con = new Contact();
        Database.DMLOptions accDMLOptions = new Database.DMLOptions();
        accDMLOptions.optAllOrNone = false;

        // Set mocks - no method stubbing as no SaveResults are needed
        uow.m_dml = m_IDML;

        // When - Register Account and Contact with a relationship to the Account
        uow.registerNew( new List<Account>{ acc } );
        uow.registerNew( con, Contact.AccountId, acc );
        // Register DMLOptions, full for Account and AllOrNone for Contact
        uow.registerNewDmlOptions( Account.SObjectType, accDMLOptions );
        uow.registerNewAllOrNone( Contact.SObjectType, true );

        // Then - validate whether the Relationship was properly stored - before commitWork() as otherwise UOW is already reset
        Map<SObjectType, List<fflib_SObjectUnitOfWork.IRelationship>> relationsList = uow.m_relationships;
        System.Assert.areEqual( 1, relationsList.size(), 'Expected one relation to be listed' );
        fflib_SObjectUnitOfWork.Relationship r = ( fflib_SObjectUnitOfWork.Relationship ) relationsList.get( Contact.SObjectType )[ 0 ];
        System.Assert.areEqual( con, r.getRecord(), 'Expected Relation to be defined on the provided Contact' );

        // When & Then - perform commitWork() to verify the sequence of SObjects being inserted and whether the right parameters were provided to IDML class
        uow.commitWork();

        // Validate performAction was called exactly 2x and validate the sequence of DMLActions and SObjectTypes afterwards
        fflib_ArgumentCaptor captorSObjectLists = new fflib_ArgumentCaptor();
        fflib_ArgumentCaptor captorDmlOptions = new fflib_ArgumentCaptor();
        ( ( fflib_Database_IDML ) mocks.verify( m_IDML, 2 ) ).performDMLAction(
            ( fflib_SObjectUnitOfWork.DMLActions ) fflib_Match.eq( fflib_SObjectUnitOfWork.DMLActions.dNEW ),
            ( List<SObject> ) captorSObjectLists.capture(),
            ( Database.DMLOptions ) captorDmlOptions.capture(),
            ( AccessLevel ) fflib_Match.eq( fflib_Database.getAccessLevel( uow.m_securityContext ) )
        );
        List<Object> enteredSObjects = captorSObjectLists.getAllValues();
        System.Assert.areEqual( 2, enteredSObjects?.size(), 'Expected 2 Lists of SObjects to be captured' );
        System.Assert.areEqual( acc, ( ( List<SObject> ) enteredSObjects[ 0 ] )[ 0 ], 'Expected first SObject called for DML operation to be the Account' );
        System.Assert.areEqual( con, ( ( List<SObject> ) enteredSObjects[ 1 ] )[ 0 ], 'Expected second SObject called for DML operation to be the Contact' );

        List<Object> dmlOptionsList = captorDmlOptions.getAllValues();
        System.Assert.areEqual( 2, dmlOptionsList?.size(), 'Expected 2 DMLOptions to be captured' );
        System.Assert.areEqual( accDMLOptions, dmlOptionsList[ 0 ], 'Expected first DMLOptions to be the full DMLOptions from Accounts' );
        System.Assert.isFalse( ( ( Database.DMLOptions ) dmlOptionsList[ 0 ] ).optAllOrNone, 'Expected Account to have AllOrNone false based on definition in accDMLOptions' );
        System.Assert.isTrue( ( ( Database.DMLOptions ) dmlOptionsList[ 1 ] ).optAllOrNone, 'Expected Contact to have AllOrNone true' );

        System.Assert.isFalse( uow.saveResultsRequired, 'Expected saveResultsRequired to not be changed from default false, given AllOrNone set to true' );
        // Can't validate Relationship resolve, since Database.insert() is mocked and hence, no Id is set on Account to be populated on Contact
    }

    @IsTest
    private static void registerNewImmediate(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_Database_IDML m_IDML = ( fflib_Database_IDML ) mocks.mock( fflib_Database_IDML.class );

        // Given - create data
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork( new List<SObjectType>{ Account.SObjectType } );
        List<Account> accList = new List<Account>{ new Account( Name = 'test' ) };

        // Set mocks - no method stubbing as no SaveResults are needed
        uow.m_dml = m_IDML;

        // When - Register Account Immediately & perform commitWork()
        uow.registerNewImmediate( accList );
        uow.commitWork();

        // Validate performAction was called exactly 1x with correct DMLActions and input list - note, no DMLOptions available for Immediate DML operations
        ( ( fflib_Database_IDML ) mocks.verify( m_IDML, 1 ) ).performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dNEW_IMMEDIATE, accList, fflib_Database.getAccessLevel( uow.m_securityContext ) );
    }

    /**
     * Method to verify:
     * 1) Whether UOW executes in the correct sequence given an constructor-input-list
     * 2) Whether the objects are properly registered and resulting in correct DML Operations
     * 3) Whether the relationships are properly processed
     */
    @IsTest
    private static void registerPriorityDirty_Relation_Sequence(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_Database_IDML m_IDML = ( fflib_Database_IDML ) mocks.mock( fflib_Database_IDML.class );

        // Given - create data
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork( new List<SObjectType>{ Account.SObjectType, Contact.SObjectType } );
        Account acc = new Account( Id = ID_ACCOUNT, Name = 'Test' );
        Contact con = new Contact( Id = ID_CONTACT );

        // Set mocks - no method stubbing as no SaveResults are needed
        uow.m_dml = m_IDML;

        // When - Register Priority on Account and Contact to update records with Name and relationship
        uow.registerPriorityDirty( new List<Account>{ acc } );
        uow.registerPriorityDirty( con, Contact.AccountId, acc );

        // Then - validate whether the Relationship was properly stored - before commitWork() as otherwise UOW is already reset
        Map<SObjectType, List<fflib_SObjectUnitOfWork.IRelationship>> relationsList = uow.m_relationships;
        System.Assert.areEqual( 1, relationsList.size(), 'Expected one relation to be listed' );
        fflib_SObjectUnitOfWork.Relationship r = ( fflib_SObjectUnitOfWork.Relationship ) relationsList.get( Contact.SObjectType )[ 0 ];
        System.Assert.areEqual( con, r.getRecord(), 'Expected Relation to be defined on the provided Contact' );
        System.Assert.isNull( con.AccountId, 'Expected AccountId to not be set on Contact yet, before commitWork()' );

        // When & Then - perform commitWork() to verify the sequence of SObjects being inserted and whether the right parameters were provided to IDML class
        uow.commitWork();
        fflib_ArgumentCaptor captorSObjectLists = new fflib_ArgumentCaptor();
        ( ( fflib_Database_IDML ) mocks.verify( m_IDML, 2 ) ).performDMLAction(
            ( fflib_SObjectUnitOfWork.DMLActions ) fflib_Match.eq( fflib_SObjectUnitOfWork.DMLActions.dUPDATE_PRIO ),
            ( List<SObject> ) captorSObjectLists.capture(),
            ( Database.DMLOptions ) fflib_Match.isNull(),
            ( AccessLevel ) fflib_Match.eq( fflib_Database.getAccessLevel( uow.m_securityContext ) )
        );
        List<Object> enteredSObjects = captorSObjectLists.getAllValues();
        System.Assert.areEqual( acc, ( ( List<SObject> ) enteredSObjects[ 0 ] )[ 0 ], 'Expected 1st SObject called for DML operation to be the Account' );
        System.Assert.areEqual( con, ( ( List<SObject> ) enteredSObjects[ 1 ] )[ 0 ], 'Expected 2nd SObject called for DML operation to be the Contact' );

        // Validate the resolve Relationship was called, and Contact-Account were properly matched
        System.Assert.areEqual( acc.Id, con.AccountId, 'Expected resolve to have set the AccountId on the Contact' );
    }

    @IsTest
    private static void registerDirty_Relation_Sequence(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_Database_IDML m_IDML = ( fflib_Database_IDML ) mocks.mock( fflib_Database_IDML.class );

        // Given - create data
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork( new List<SObjectType>{ Account.SObjectType, Contact.SObjectType } );
        Account acc = new Account( Name = 'test', Id = ID_ACCOUNT );
        Contact con = new Contact( Id = ID_CONTACT );
        Database.DMLOptions accDMLOptions = new Database.DMLOptions();
        accDMLOptions.optAllOrNone = false;

        // Set mocks - no method stubbing as no SaveResults are needed
        uow.m_dml = m_IDML;

        // When - Register Account and Contact with a relationship to the Account
        uow.registerDirty( new List<Account>{ acc } );
        uow.registerDirty( con, Contact.AccountId, acc );
        // Register DMLOptions, full for Account and AllOrNone for Contact
        uow.registerDirtyDmlOptions( Account.SObjectType, accDMLOptions );
        uow.registerDirtyAllOrNone( Contact.SObjectType, true );

        // Then - validate whether the Relationship was properly stored - before commitWork() as otherwise UOW is already reset
        Map<SObjectType, List<fflib_SObjectUnitOfWork.IRelationship>> relationsList = uow.m_relationships;
        System.Assert.areEqual( 1, relationsList.size(), 'Expected one relation to be listed' );
        fflib_SObjectUnitOfWork.Relationship r = ( fflib_SObjectUnitOfWork.Relationship ) relationsList.get( Contact.SObjectType )[ 0 ];
        System.Assert.areEqual( con, r.getRecord(), 'Expected Relation to be defined on the provided Contact' );

        // When & Then - perform commitWork() to verify the sequence of SObjects being inserted and whether the right parameters were provided to IDML class
        uow.commitWork();

        // Validate performAction was called exactly 2x and validate the sequence of DMLActions and SObjectTypes afterwards
        fflib_ArgumentCaptor captorSObjectLists = new fflib_ArgumentCaptor();
        fflib_ArgumentCaptor captorDmlOptions = new fflib_ArgumentCaptor();
        ( ( fflib_Database_IDML ) mocks.verify( m_IDML, 2 ) ).performDMLAction(
            ( fflib_SObjectUnitOfWork.DMLActions ) fflib_Match.eq( fflib_SObjectUnitOfWork.DMLActions.dUPDATE ),
            ( List<SObject> ) captorSObjectLists.capture(),
            ( Database.DMLOptions ) captorDmlOptions.capture(),
            ( AccessLevel ) fflib_Match.eq( fflib_Database.getAccessLevel( uow.m_securityContext ) )
        );
        List<Object> enteredSObjects = captorSObjectLists.getAllValues();
        System.Assert.areEqual( acc, ( ( List<SObject> ) enteredSObjects[ 0 ] )[ 0 ], 'Expected first SObject called for DML operation to be the Account' );
        System.Assert.areEqual( con, ( ( List<SObject> ) enteredSObjects[ 1 ] )[ 0 ], 'Expected second SObject called for DML operation to be the Contact' );

        List<Object> dmlOptionsList = captorDmlOptions.getAllValues();
        System.Assert.areEqual( 2, dmlOptionsList?.size(), 'Expected 2 DMLOptions to be captured' );
        System.Assert.areEqual( accDMLOptions, dmlOptionsList[ 0 ], 'Expected first DMLOptions to be the full DMLOptions from Accounts' );
        System.Assert.isFalse( ( ( Database.DMLOptions ) dmlOptionsList[ 0 ] ).optAllOrNone, 'Expected Account to have AllOrNone false based on definition in accDMLOptions' );
        System.Assert.isTrue( ( ( Database.DMLOptions ) dmlOptionsList[ 1 ] ).optAllOrNone, 'Expected Contact to have AllOrNone true' );

        // Validate the resolve Relationship was called, and Contact-Account were properly matched
        System.Assert.areEqual( acc.Id, con.AccountId, 'Expected resolve to have set the AccountId on the Contact' );

        System.Assert.isFalse( uow.saveResultsRequired, 'Expected saveResultsRequired to not be changed from default false, given AllOrNone set to true' );
    }

    @IsTest
    private static void registerDirty_Fields_Full_Scenarios(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_Database_IDML m_IDML = ( fflib_Database_IDML ) mocks.mock( fflib_Database_IDML.class );

        // Given - create data
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork( new List<SObjectType>{ Account.SObjectType } );
        Account accFull = new Account(
            Id = ID_ACCOUNT,
            Name = 'Test',
            BillingCity = 'Amsterdam',
            BillingStreet = 'Gustav Mahlerlaan'
        );

        // Set mocks - no method stubbing as no SaveResults are needed
        uow.m_dml = m_IDML;

        // When & Then - first register with DirtyFields SObjectFields list - only those fields should be registered
        uow.registerDirty( new List<Account>{ accFull }, new List<SObjectField>{ Account.Name, Account.BillingCity } );
        Account acc = ( Account ) uow.m_dirtyMapByType?.get( Account.SObjectType )?.get( accFull.Id );
        System.Assert.isNotNull( acc, 'Expects accFull to be registered in the map based on Id and SObjectType' );
        System.Assert.areEqual( accFull.BillingCity, acc.BillingCity, 'Expected clone of provided accFull to contain BillingCity as part of DirtyFieldsList' );
        System.Assert.isNull( acc.BillingStreet, 'Expected clone of provided accFull to not contain BillingStreet as not in DirtyFieldsList' );
        System.Assert.areNotEqual( acc, accFull, 'Expected a clone to be created given the DirtyFieldsList provided as parameter' );

        // When & Then - attempt to register full SObject after dirtyFields for same recordId were registered should throw Exception
        try{
            uow.registerDirty( accFull );
            System.Assert.fail( 'This should never happen, given the system isn\'t able to determine what record to update or not' );
        } catch( fflib_SObjectUnitOfWork.UnitOfWorkException ex ){
            System.Assert.areEqual( 'Cannot determine what fields to update on record ' + accFull, ex.getMessage(), 'Expected different exception message' );
        }

        // When & Then - enrich previously dirtyFields registered record with additional fields
        uow.registerDirty( accFull, new List<SObjectField>{ Account.BillingStreet } );
        System.Assert.areEqual( accFull.BillingStreet, acc.BillingStreet, 'Expected DirtyMap record (reference) to be enriched with additional field' );
    }

    @IsTest
    private static void registerDirty_InsertedSameTransaction(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_Database_IDML m_IDML = ( fflib_Database_IDML ) mocks.mock( fflib_Database_IDML.class );

        // Given - create data
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork( new List<SObjectType>{ Contact.SObjectType, Opportunity.SObjectType } );
        Contact c = new Contact();

        // Set mocks - no method stubbing as no SaveResults are needed
        uow.m_dml = m_IDML;

        // When - Insert Contact and directly after update Contact to trigger callout/legacy system/third party app
        // Note, can't make changes to fields in between, as reference is stored so would be included on insert already
        // Additionally, can't make a clone, given the dirty-contact wouldn't match the new-contact which causes a lack of record.Id in allowance
        // see fflib_SObjectUnitOfWork.validateRecordForDMLAction() for more details and scenario explanation
        uow.registerNew( c );
        uow.registerDirty( c );

        // Then - validate whether Contact was registered for update, despite not having record.Id populated at moment of registration
        // Validate a random record identifier was generated to prevent overrides in Map when having 'null' identifier
        // Note, prefix of Contact is 003 which can never match with Math.random() * 100, as this would result in 3 without leading zeros
        Map<String, SObject> conDirtyMap = uow.m_dirtyMapByType.get( Contact.SObjectType );
        System.Assert.areEqual( 1, conDirtyMap?.size(), 'Expected one Contact record to be registered for a DML Update' );
        String conIdentifier = new List<String>( conDirtyMap.keySet() )[ 0 ];
        System.Assert.isFalse(
            ( ( conIdentifier.length() == 15 || conIdentifier.length() == 18 ) && conIdentifier.startsWith( c.getSObjectType().getDescribe().getKeyPrefix() ) ),
            'Expected Opportunity record Identifier to not match the Contact Id format ' + conIdentifier
        );
    }

    @IsTest
    private static void registerDirty_InvalidSequence(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_Database_IDML m_IDML = ( fflib_Database_IDML ) mocks.mock( fflib_Database_IDML.class );

        // Given - create data
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork( new List<SObjectType>{ Contact.SObjectType, Opportunity.SObjectType } );
        Contact c = new Contact();
        Opportunity opp = new Opportunity( Name = 'Parent' );

        // Set mocks - no method stubbing as no SaveResults are needed
        uow.m_dml = m_IDML;

        // When & Then - Opportunity is inserted in normal sequence, while update is in Priority; causing on update no Id to be known
        try{
            uow.registerDirty( opp, Opportunity.ContactId, c );
            System.Assert.fail( 'Opportunity should not be able to be registered Dirty without an ID and same record not registered for new' );
        } catch( fflib_SObjectUnitOfWork.UnitOfWorkException ex ){
            System.Assert.areEqual(
                'New records cannot be registered as dirty, or should be registeredNew() before calling registerDirty()',
                ex.getMessage(),
                'Expected different Exception message when Oppty not registeredNew'
            );
        }

        try{
            uow.registerNew( opp );
            uow.registerPriorityDirty( opp );
            System.Assert.fail( 'Opportunity should not be able to be registered without an ID and New registration doesn\'t happen before update' );
        } catch( fflib_SObjectUnitOfWork.UnitOfWorkException ex ){
            System.Assert.areEqual(
                'New records cannot be registered as dirty, or should be registeredNew() before calling registerDirty()',
                ex.getMessage(),
                'Expected different Exception message when Oppty is registeredNew but too late'
            );
        }
    }

    @IsTest
    private static void registerDirtyImmediate(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_Database_IDML m_IDML = ( fflib_Database_IDML ) mocks.mock( fflib_Database_IDML.class );

        // Given - create data
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork( new List<SObjectType>{ Account.SObjectType } );
        List<Account> accList = new List<Account>{ new Account( Name = 'test', Id = ID_ACCOUNT ) };

        // Set mocks - no method stubbing as no SaveResults are needed
        uow.m_dml = m_IDML;

        // When - Register Account and Contact with a relationship to the Account & perform commitWork()
        uow.registerDirtyImmediate( accList );
        uow.commitWork();

        // Then -Validate performAction was called exactly 1x with correct DMLActions and input list - note, no DMLOptions available for Immediate DML operations
        ( ( fflib_Database_IDML ) mocks.verify( m_IDML, 1 ) ).performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dUPDATE_IMMEDIATE, accList, fflib_Database.getAccessLevel( uow.m_securityContext ) );
    }

    @IsTest
    private static void registerUpsert(){
        // Given - create data
        List<Account> accList = new List<Account>{
            new Account( Id = ID_ACCOUNT, Name = 'Existing Account for update' ),
            new Account( Name = 'New Account for insert' )
        };

        // When - perform test
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork( new List<SObjectType>{ Account.SObjectType } );
        uow.registerUpsert( accList );

        // Then - Validate 1st Account registeredDirty and 2nd Account registeredNew
        Map<String, SObject> dirtyAccounts = uow.m_dirtyMapByType.get( Account.SObjectType );
        System.Assert.areEqual( 1, dirtyAccounts?.size(), 'Expected one Account registered as dirty' );
        System.Assert.areEqual( accList[ 0 ], dirtyAccounts.values()[ 0 ], 'Expected 1st Account to be registered as dirty' );

        List<SObject> newAccounts = uow.m_newListByType.get( Account.SObjectType );
        System.Assert.areEqual( 1, newAccounts?.size(), 'Expected one Account registered as new' );
        System.Assert.areEqual( accList[ 1 ], newAccounts[ 0 ], 'Expected 2nd Account to be registered as new' );
    }

    /**
     * Method to verify:
     * 1) Whether UOW executes in the correct sequence given an constructor-input-list
     * 2) Whether the objects are properly registered and resulting in correct DML Operations - first Priority, then normal
     */
    @IsTest
    private static void registerPriorityDeleted_Sequence(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_Database_IDML m_IDML = ( fflib_Database_IDML ) mocks.mock( fflib_Database_IDML.class );

        // Given - create data
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork( new List<SObjectType>{ Account.SObjectType, Contact.SObjectType, Lead.SObjectType } );
        Account acc = new Account( Name = 'test', Id = ID_ACCOUNT );
        Contact con = new Contact( Id = ID_CONTACT );
        Lead l = new Lead( Id = ID_LEAD );

        // Set mocks - no method stubbing as no SaveResults are needed
        uow.m_dml = m_IDML;

        // When - Register Account, Contact and Lead to be deleted
        // Perform commitWork() to verify the sequence of SObjects being deleted and whether the right parameters were provided to IDML class
        uow.registerPriorityDeleted( new List<Account>{ acc } );
        uow.registerPriorityDeleted( con );
        uow.registerDeleted( new List<Lead>{ l } );
        uow.registerDeletedAllOrNone( Lead.SObjectType, false );
        uow.commitWork();

        // Validate performAction was called exactly 3x and validate the sequence of DMLActions and SObjectTypes afterwards
        // Also being called with a Boolean allOrNone attribute
        fflib_ArgumentCaptor captorDMLActions = new fflib_ArgumentCaptor();
        fflib_ArgumentCaptor captorSObjectLists = new fflib_ArgumentCaptor();
        fflib_ArgumentCaptor captorAllOrNones = new fflib_ArgumentCaptor();
        ( ( fflib_Database_IDML ) mocks.verify( m_IDML, 3 ) ).performDMLAction(
            ( fflib_SObjectUnitOfWork.DMLActions ) captorDMLActions.capture(),
            ( List<SObject> ) captorSObjectLists.capture(),
            ( Boolean ) captorAllOrNones.capture(),
            ( AccessLevel ) fflib_Match.eq( fflib_Database.getAccessLevel( uow.m_securityContext ) )
        );
        List<Object> enteredDMLActions = captorDMLActions.getAllValues();
        List<Object> enteredSObjects = captorSObjectLists.getAllValues();
        List<Object> enteredAllOrNones = captorAllOrNones.getAllValues();

        // Validate Account was registered with priority first
        System.Assert.areEqual( fflib_SObjectUnitOfWork.DMLActions.dDELETE_PRIO, enteredDMLActions[ 0 ], 'Expected 1st performAction to be called with priority deleted' );
        System.Assert.areEqual( con, ( ( List<SObject> ) enteredSObjects[ 0 ] )[ 0 ], 'Expected 1st SObject called for DML operation to be the Contact (as delete is in reverse order)' );
        System.Assert.isTrue( ( ( Boolean ) enteredAllOrNones[ 0 ] ), 'Expected 1st AllOrNone to be for Account, not set, thus default, thus true' );

        // Validate Contact was registered with priority second
        System.Assert.areEqual( fflib_SObjectUnitOfWork.DMLActions.dDELETE_PRIO, enteredDMLActions[ 1 ], 'Expected 2nd performAction to be called with priority deleted' );
        System.Assert.areEqual( acc, ( ( List<SObject> ) enteredSObjects[ 1 ] )[ 0 ], 'Expected 2nd SObject called for DML operation to be the Account (as delete is in reverse order)' );
        System.Assert.isTrue( ( ( Boolean ) enteredAllOrNones[ 1 ] ), 'Expected 2st AllOrNone to be for Contact, not set, thus default, thus true' );

        // Validate Lead was registered last without, despite being the first SObjectType in list to be performed
        System.Assert.areEqual( fflib_SObjectUnitOfWork.DMLActions.dDELETE, enteredDMLActions[ 2 ], 'Expected delete DMLAction to be called after all priority deletes' );
        System.Assert.areEqual( l, ( ( List<SObject> ) enteredSObjects[ 2 ] )[ 0 ], 'Expected 3rd SObject called for DML operation to be the Lead, despite first in reverse SObjectType list' );
        System.Assert.areEqual( Lead.SObjectType, uow.m_sObjectTypes[ 2 ], 'Expected Lead to be set as last SObjectType' );
        System.Assert.isFalse( ( ( Boolean ) enteredAllOrNones[ 2 ] ), 'Expected 3rd AllOrNone to be for Lead, set to false' );

        System.Assert.isTrue( uow.saveResultsRequired, 'Expected SaveResults to be default requested given AllOrNone set to false' );
    }

    @IsTest
    private static void registerDeletedImmediate(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_Database_IDML m_IDML = ( fflib_Database_IDML ) mocks.mock( fflib_Database_IDML.class );

        // Given - create data
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork( new List<SObjectType>{ Account.SObjectType } );
        List<Account> accList = new List<Account>{ new Account( Name = 'test', Id = ID_ACCOUNT ) };

        // Set mocks - no method stubbing as no SaveResults are needed
        uow.m_dml = m_IDML;

        // When - Register Account and Contact with a relationship to the Account & perform commitWork()
        uow.registerDeletedImmediate( accList );
        uow.commitWork();

        // Then - Validate performAction was called exactly 1x with correct DMLActions and input list - note, no DMLOptions available for Immediate DML operations
        ( ( fflib_Database_IDML ) mocks.verify( m_IDML, 1 ) ).performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dDELETE_IMMEDIATE, accList, fflib_Database.getAccessLevel( uow.m_securityContext ) );
    }

    @IsTest
    private static void registerPermanentlyDeleted_registerEmptyRecycleBin(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_Database_IDML m_IDML = ( fflib_Database_IDML ) mocks.mock( fflib_Database_IDML.class );

        // Given - create data
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork( new List<SObjectType>{ Account.SObjectType, Contact.SObjectType } );
        List<Account> accList = new List<Account>{ new Account( Name = 'First Account', Id = ID_ACCOUNT ), new Account( Name = 'Second Account', Id = ID_ACCOUNT2 ) };
        List<Contact> conList = new List<Contact>{ new Contact( Id = ID_CONTACT ) };

        // Set mocks - no method stubbing as no SaveResults are needed
        uow.m_dml = m_IDML;

        // When - Register Accounts for deletion and Emptying Recycle bin; and Contact for Emptying Recycle bin
        uow.registerPermanentlyDeleted( accList );
        uow.registerEmptyRecycleBin( conList );
        uow.commitWork();

        // Then - Validate performAction was called exactly 3x with correct DMLActions and input list - note, no DMLOptions available for Immediate DML operations
        AccessLevel accessLevel = fflib_Database.getAccessLevel( uow.m_securityContext );
        ( ( fflib_Database_IDML ) mocks.verify( m_IDML, 1 ) ).performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dDELETE, accList, true, accessLevel );
        ( ( fflib_Database_IDML ) mocks.verify( m_IDML, 1 ) ).performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dEMPTY_RECBIN, accList, accessLevel );
        ( ( fflib_Database_IDML ) mocks.verify( m_IDML, 1 ) ).performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dEMPTY_RECBIN, conList, accessLevel );
    }

    @IsTest
    private static void registerUndeleted_allOrNone(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_Database_IDML m_IDML = ( fflib_Database_IDML ) mocks.mock( fflib_Database_IDML.class );

        // Given - create data
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork( new List<SObjectType>{ Account.SObjectType, Contact.SObjectType } );
        List<Account> accList = new List<Account>{ new Account( Name = 'First Account', Id = ID_ACCOUNT ) };
        Contact c = new Contact( LastName = 'John', Id = ID_CONTACT );

        // Set mocks - no method stubbing as no SaveResults are needed
        uow.m_dml = m_IDML;

        // When - Register Accounts and Contact for undeletion and specify Contacts to be undeleted singularly (not all or none)
        uow.registerUndeleted( accList );
        uow.registerUndeleted( c );
        uow.registerUndeletedAllOrNone( Contact.SObjectType, false );
        uow.commitWork();

        // Then - Validate performAction was called exactly 2x with correct DMLActions and capture both input list and AllOrNone to validate sequence and input
        fflib_ArgumentCaptor recordListCaptor = new fflib_ArgumentCaptor();
        fflib_ArgumentCaptor allOrNoneCaptor = new fflib_ArgumentCaptor();
        ( ( fflib_Database_IDML ) mocks.verify( m_IDML, 2 ) ).performDMLAction(
            ( fflib_SObjectUnitOfWork.DMLActions ) fflib_Match.eq( fflib_SObjectUnitOfWork.DMLActions.dUNDELETE ),
            ( List<SObject> ) recordListCaptor.capture(),
            ( Boolean ) allOrNoneCaptor.capture(),
            ( AccessLevel ) fflib_Match.eq( fflib_Database.getAccessLevel( uow.m_securityContext ) )
        );

        List<Object> capturedRecordLists = recordListCaptor.getAllValues();
        List<Object> capturedAllOrNoneBooleans = allOrNoneCaptor.getAllValues();
        System.Assert.areEqual( 2, capturedRecordLists.size(), 'Expected 2 record lists to be captured' );
        System.Assert.areEqual( 2, capturedAllOrNoneBooleans.size(), 'Expected 2 AllOrNone Booleans to be captured' );

        System.Assert.areEqual( Account.SObjectType, ( ( List<SObject> ) capturedRecordLists[ 0 ] )[ 0 ].getSObjectType(), 'Expected Accounts to be registered first due to constructor list' );
        System.Assert.isTrue( ( Boolean ) capturedAllOrNoneBooleans[ 0 ], 'Given Account is first, expecting TRUE for allOrNone parameter which is default, as nothing was set' );
        System.Assert.areEqual( Contact.SObjectType, ( ( List<SObject> ) capturedRecordLists[ 1 ] )[ 0 ].getSObjectType(), 'Expected Contact to be registered second due to constructor list' );
        System.Assert.isTrue( ( Boolean ) capturedAllOrNoneBooleans[ 0 ], 'Given Contact is second, expecting FALSE for allOrNone parameter as explicitly specified' );

        System.Assert.isTrue( uow.saveResultsRequired, 'Expected SaveResults to be default requested given AllOrNone set to false' );
    }

    @IsTest
    private static void registerPublish_successTransaction(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_Database_IDML m_IDML = ( fflib_Database_IDML ) mocks.mock( fflib_Database_IDML.class );

        // Given - create data
        SObjectType eventSObjectType = BatchApexErrorEvent.SObjectType;
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork( new List<SObjectType>{ eventSObjectType } );
        List<SObject> evtList = new List<SObject>{ eventSObjectType.newSObject() };

        // Set mocks - no method stubbing as no SaveResults are needed
        uow.m_dml = m_IDML;

        // When - Register Event before transaction, and after success/failure
        uow.registerPublishBeforeTransaction( evtList );
        uow.registerPublishAfterSuccessTransaction( evtList );
        uow.registerPublishAfterFailureTransaction( evtList );
        uow.commitWork();

        // Then - Validate only 2 events are truly performed for DML and 1 is not called, since there was no Failed transaction
        AccessLevel accessLevel = fflib_Database.getAccessLevel( uow.m_securityContext );
        ( ( fflib_Database_IDML ) mocks.verify( m_IDML, 1 ) ).performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dPUB_BEFORE, evtList, accessLevel );
        ( ( fflib_Database_IDML ) mocks.verify( m_IDML, 1 ) ).performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dPUB_AFTER_SUCCESS, evtList, accessLevel );
        ( ( fflib_Database_IDML ) mocks.verify( m_IDML, 0 ) ).performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dPUB_AFTER_FAILURE, evtList, accessLevel );
    }

    @IsTest
    private static void registerPublish_failedTransaction(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_Database_IDML m_IDML = ( fflib_Database_IDML ) mocks.mock( fflib_Database_IDML.class );

        // Given - create data
        SObjectType eventSObjectType = BatchApexErrorEvent.SObjectType;
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork( new List<SObjectType>{ eventSObjectType } );
        List<SObject> evtList = new List<SObject>{ eventSObjectType.newSObject() };
        String exceptionMessage = 'Fake failure during publishing of before transaction event';
        AccessLevel accessLevel = fflib_Database.getAccessLevel( uow.m_securityContext );

        // Set mocks
        mocks.startStubbing();
        ( ( fflib_Database_IDML ) mocks.doThrowWhen( new fflib.MissingDataException( exceptionMessage ), m_IDML ) ).performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dPUB_BEFORE, evtList, accessLevel );
        mocks.stopStubbing();
        uow.m_dml = m_IDML;

        // When - Register Event before transaction, and after success/failure
        uow.registerPublishBeforeTransaction( evtList );
        uow.registerPublishAfterSuccessTransaction( evtList );
        uow.registerPublishAfterFailureTransaction( evtList );
        try{
            uow.commitWork();
            System.Assert.fail( 'Expected commitWork() to throw an Exception given the mocking of Publish Before' );
        } catch( fflib.MissingDataException ex ){
            System.Assert.areEqual( exceptionMessage, ex.getMessage(), 'Expected different Exception message' );
        }

        // Then - Validate Pub Before is called, which threw an Exception, but still the Failed Event is performed - and the success Event is thus not performed
        ( ( fflib_Database_IDML ) mocks.verify( m_IDML, 1 ) ).performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dPUB_BEFORE, evtList, accessLevel );
        ( ( fflib_Database_IDML ) mocks.verify( m_IDML, 0 ) ).performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dPUB_AFTER_SUCCESS, evtList, accessLevel );
        ( ( fflib_Database_IDML ) mocks.verify( m_IDML, 1 ) ).performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dPUB_AFTER_FAILURE, evtList, accessLevel );
    }

    private class DummyWork implements fflib_SObjectUnitOfWork.IDoWork{
        Boolean hasRan = false;
        public void doWork(){
            this.hasRan = true;
        }
    }

    @IsTest
    private static void registerWork(){
        // Given - Create data
        fflib_ISObjectUnitOfWork uow = fflib.unitOfWork.newInstance();
        DummyWork workInstance = new DummyWork();
        System.Assert.isFalse( workInstance.hasRan, 'Expected hasRan to be false by default before being performed' );

        // When - Register workInstance to work and commitWork()
        uow.registerWork( workInstance );
        uow.commitWork();

        // Then - Validate the WorkInstance.doWork() method was called, implying hasWork returned true and the IDoWork implementation was triggered
        System.Assert.isTrue( workInstance.hasRan, 'Expected hasRan to be set to true after doWork() being called' );
    }

    @IsTest
    private static void registerEmail_relationship(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_Database_IDML m_IDML = ( fflib_Database_IDML ) mocks.mock( fflib_Database_IDML.class );

        // Given - create data
        String textualBody = 'Amazing message to send';
        Messaging.SingleEmailMessage emailForContact = new Messaging.SingleEmailMessage();
        Messaging.SingleEmailMessage emailForAccount = new Messaging.SingleEmailMessage();
        Messaging.SingleEmailMessage emailNoRelation = new Messaging.SingleEmailMessage();
        Account a = new Account( Id = ID_ACCOUNT );
        Contact c = new Contact( Id = ID_CONTACT );
        System.Assert.areEqual( null, emailForContact.whatId, 'Expected Email for Contact WhatId to be empty at start of test method' );
        System.Assert.areEqual( null, emailForAccount.whatId, 'Expected Email for Account WhatId to be empty at start of test method' );
        System.Assert.areEqual( null, emailNoRelation.whatId, 'Expected Email NR WhatId to be empty at start of test method' );

        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork();

        // Set mocks
        uow.m_dml = m_IDML;

        // When - Register Email and request a link to resolve relation to Contact & Account (covering 2 items in m_relationshipsOperations) and commitWork()
        uow.registerEmail( emailForContact, c );
        uow.registerEmail( emailForAccount, a );
        uow.registerEmail( emailNoRelation );
        uow.commitWork();

        // Then - Validate the relation to be resolved and the both Emails to be registered in once to IDML
        System.Assert.areEqual( c.Id, emailForContact.whatId, 'Expected Email for Contact WhatId to be populated by relationship resolve method' );
        System.Assert.areEqual( a.Id, emailForAccount.whatId, 'Expected Email for Account WhatId to be populated by relationship resolve method' );
        System.Assert.areEqual( null, emailNoRelation.whatId, 'Expected Email NR WhatId to remain null as no relationship to be resolved' );
        ( ( fflib_Database_IDML ) mocks.verify( m_IDML, 1 ) ).performOperation( fflib_SObjectUnitOfWork.Operations.SEND_EMAIL, new List<Messaging.SingleEmailMessage>{ emailForContact, emailForAccount, emailNoRelation } );
    }

    @IsTest
    private static void registerRelationship_Unresolved_ObjectRelation_Exception(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_Database_IDML m_IDML = ( fflib_Database_IDML ) mocks.mock( fflib_Database_IDML.class );

        // Given - create data
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork( new List<SObjectType>{ Account.SObjectType, Contact.SObjectType } );
        Contact contactNew = new Contact();
        Contact contactUpdate = new Contact( Id = ID_CONTACT );

        // Set mocks - no method stubbing as no SaveResults are needed
        uow.m_dml = m_IDML;

        // When - Register Contact to have SObjectType included (and hasWork()), then register Relationship, but forgetting to register contactUpdate
        uow.registerNew( contactNew );
        uow.registerRelationship( contactUpdate, Contact.AccountId, new Account() );

        // Then - validate whether the Relationship was properly stored - before commitWork() as otherwise UOW is already reset
        Map<SObjectType, List<fflib_SObjectUnitOfWork.IRelationship>> relationsList = uow.m_relationships;
        System.Assert.areEqual( 1, relationsList.size(), 'Expected one relation to be listed' );
        fflib_SObjectUnitOfWork.Relationship r = ( fflib_SObjectUnitOfWork.Relationship ) relationsList.get( Contact.SObjectType )[ 0 ];
        System.Assert.areEqual( contactUpdate, r?.getRecord(), 'Expected Relation to be defined on the provided Contact' );

        try{
            uow.commitWork();
            System.Assert.fail( 'Should never happen as the relationship was not resolved because contactUpdate was never registered/processed for a DML action' );
        } catch( fflib_SObjectUnitOfWork.UnitOfWorkException ex ){
            System.Assert.isTrue( ex.getMessage().startsWith( 'The relationship was not resolved' ), 'Expected a different message ' + ex.getMessage() );
        }

        // Validate the resolve Relationship was not called and no Id was populated
        System.Assert.isNull( contactUpdate.AccountId, 'Expected no resolving of logic due to mismatch' );
    }

    @IsTest
    private static void registerRelationship_EmailWrapper(){
        Messaging.SingleEmailMessage emailMsg = new Messaging.SingleEmailMessage();
        Account a = new Account( Id = ID_ACCOUNT );
        fflib_SObjectUnitOfWork.EmailRelationship wrapper = new fflib_SObjectUnitOfWork.EmailRelationship( emailMsg, a );

        // When/Then - Validate the provided record is set as record
        System.Assert.areEqual( emailMsg, wrapper.getRecord(), 'Expected provided SingleEmailMessage record to be returned from private variable' );
        System.Assert.isFalse( wrapper.wasResolved(), 'Expected default to be NOT resolved (yet)' );

        // When/Then - Resolve relation and verify the whatId is properly set
        wrapper.resolve();
        System.Assert.areEqual( a.Id, emailMsg.getWhatId(), 'Expected whatId to be set by AccountId after resolving' );
        System.Assert.isTrue( wrapper.wasResolved(), 'Expected resolved-flag to be set' );

        // When/Then - Try to resolve for DMLAction, which is irrelevant for EmailRelationship
        try{
            wrapper.resolve( fflib_SObjectUnitOfWork.DMLActions.dNEW );
            System.Assert.fail( 'This should never happen as the EmailRelations are performed outside of DMLActions scope' );
        } catch( fflib_SObjectUnitOfWork.UnitOfWorkException ex ){
            System.Assert.areEqual(
                'EmailRelationships are performed outside DMLActions scope and should therefore not be resolved for a specific DMLAction',
                ex.getMessage(),
                'Expected different message'
            );
        }
    }

    @IsTest
    private static void registerApprovalProcess_relationship(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_Database_IDML m_IDML = ( fflib_Database_IDML ) mocks.mock( fflib_Database_IDML.class );

        // Given - create data
        Approval.ProcessSubmitRequest appProcessWithRelation = new Approval.ProcessSubmitRequest();
        Approval.ProcessSubmitRequest appProcessNoRelation = new Approval.ProcessSubmitRequest();
        Approval.ProcessWorkitemRequest approveRequestWithRelation = new Approval.ProcessWorkitemRequest();
        Contact c = new Contact( Id = ID_CONTACT );
        System.Assert.isNull( appProcessWithRelation.objectId, 'Expected ApprovalProcess WR ObjectId to be empty at start of test method' );
        System.Assert.isNull( appProcessNoRelation.objectId, 'Expected ApprovalProcess NR ObjectId to be empty at start of test method' );
        System.Assert.isNull( approveRequestWithRelation.workitemId, 'Expected ApprovalProcess WR WorkItemId to be empty at start of test method' );

        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork();

        // Set mocks
        uow.m_dml = m_IDML;

        // When - Register Email and request a link to resolve relation to Contact and commitWork()
        uow.registerApprovalProcess( appProcessWithRelation, c );
        uow.registerApprovalProcess( appProcessNoRelation );
        uow.registerApprovalProcess( approveRequestWithRelation, c );

        // Then - validate whether the Relationship was properly stored - before commitWork() as otherwise UOW is already reset
        System.Assert.areEqual( 1, uow.m_relationshipsOperations.size(), 'Expected one Operation to be listed' );
        List<fflib_SObjectUnitOfWork.IRelationship> approvalRelations = uow.m_relationshipsOperations.get( fflib_SObjectUnitOfWork.Operations.PROCESS_APPROVAL_PROCESS );
        System.Assert.areEqual( 2, approvalRelations.size(), 'Expected two relations to be required to be resolved' );
        System.Assert.isFalse( approvalRelations[ 0 ].wasResolved(), 'Expected relation to not be resolved yet, since commitWork() hasnt been called yet' );

        // When - Perform CommitWork to have the relations resolved
        uow.commitWork();

        // Then - Validate the relation to be resolved and both ApprovalProcesses to be registered in once to IDML
        System.Assert.areEqual( c.Id, appProcessWithRelation.objectId, 'Expected ApprovalProcess ObjectId to be populated by relationship resolve method' );
        System.Assert.isNull( appProcessNoRelation.objectId, 'Expected ApprovalProcess ObjectId to remain null as no relationship to be resolved' );
        System.Assert.areEqual( c.Id, approveRequestWithRelation.workitemId, 'Expected Approval Request WR WorkItemId to be populated by relationship resolve method' );
        ( ( fflib_Database_IDML ) mocks.verify( m_IDML, 1 ) ).performOperation( fflib_SObjectUnitOfWork.Operations.PROCESS_APPROVAL_PROCESS, new List<Approval.ProcessRequest>{ appProcessWithRelation, appProcessNoRelation, approveRequestWithRelation } );
    }

    @IsTest
    private static void registerRelationship_ApprovalWrapper(){
        Approval.ProcessSubmitRequest appProcess = new Approval.ProcessSubmitRequest();
        Account a = new Account( Id = ID_ACCOUNT );
        fflib_SObjectUnitOfWork.ApprovalRelationship wrapper = new fflib_SObjectUnitOfWork.ApprovalRelationship( appProcess, a );

        // When/Then - Validate the provided record is set as record
        System.Assert.areEqual( appProcess, wrapper.getRecord(), 'Expected provided ProcessSubmitRequest record to be returned from private variable' );

        // When/Then - Resolve relation and verify the objectId is properly set
        wrapper.resolve();
        System.Assert.areEqual( a.Id, appProcess.getObjectId(), 'Expected objectId to be set by AccountId after resolving' );

        // When/Then - Try to resolve for DMLAction, which is irrelevant for ApprovalRelationship
        try{
            wrapper.resolve( fflib_SObjectUnitOfWork.DMLActions.dNEW );
            System.Assert.fail( 'This should never happen as the ApprovalRelationship are performed outside of DMLActions scope' );
        } catch( fflib_SObjectUnitOfWork.UnitOfWorkException ex ){
            System.Assert.areEqual(
                'ApprovalRelationships are performed outside DMLActions scope and should therefore not be resolved for a specific DMLAction',
                ex.getMessage(),
                'Expected different message'
            );
        }
    }

    @IsTest
    private static void registerRelationship_RelationshipWrapper(){
        // Given - set data
        Contact c = new Contact();
        Account a1 = new Account( Id = ID_ACCOUNT );
        Account a2 = new Account( Id = ID_ACCOUNT2 );

        // When/Then - Initiating wrapper and resolving it first to a1
        fflib_SObjectUnitOfWork.Relationship wrapper = new fflib_SObjectUnitOfWork.Relationship( c, Contact.AccountId, a1, fflib_SObjectUnitOfWork.DMLActions.dNEW );
        System.Assert.areEqual( null, c.AccountId, 'Expected AccountId to be empty after initiation' );
        wrapper.resolve();
        System.Assert.areEqual( a1.Id, c.AccountId, 'Expected Contact to have a reference to the 1st Account which was set as parentRecord' );

        // When/Then - Changing the ParentRecord and resolving again, don't expect a change, as already resolved and should skip rest of logic
        wrapper.parentRecord = a2;
        wrapper.resolve();
        System.Assert.areEqual( a1.Id, c.AccountId, 'Expected Contact to still have a reference to the 1st Account as was already resolved and logic should be skipped' );
    }

    @IsTest
    private static void registerRelationship_unregisteredSObjectType(){
        // Given - create data
        Account a = new Account();
        Contact c = new Contact();
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork();

        // When - Call method without the object being registered yet
        try{
            uow.registerRelationship( c, Contact.AccountId, a );
            System.Assert.fail( 'This should never happen as the Contact SObjectType isn\'t registered as new/dirty in UOW and therefore no relation can be set' );
        } catch( fflib_SObjectUnitOfWork.UnitOfWorkException ex ){
            System.Assert.areEqual(
                'You can\'t register a Relationship to a sObjectType which is not implemented for this unit of work: Contact',
                ex.getMessage(),
                'Expected different message'
            );
        }
    }

    @IsTest
    private static void registerRelationship_multiplePerSObjectType(){
        // Given - create data
        Account a = new Account();
        Contact c = new Contact();
        Opportunity opp = new Opportunity();
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork( new List<SObjectType>{ Opportunity.SObjectType } );

        // When - Opportunity is registered with two relations for the same SObjectType (Opportunity)
        uow.registerNew( opp, Opportunity.AccountId, a );
        uow.registerRelationship( opp, Opportunity.ContactId, c );

        // Then - Validate both relationships are registered on the Opportunity SObjectType
        Map<Schema.SObjectType, List<fflib_SObjectUnitOfWork.IRelationship>> uowRelationships = uow.m_relationships;
        System.Assert.areEqual( 1, uowRelationships?.size(), 'Expected 1 SObjectType with relations' );
        System.Assert.areEqual( 2, uowRelationships.get( Opportunity.SObjectType )?.size(), 'Expected 2 Relations registered for the Opportunity SObjectType');
    }

    @IsTest
    private static void registerRelationship_ExternalId_unregisteredSObjectType(){
        // Given - create data
        Account a = new Account();
        Contact c = new Contact();
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork();

        // When - Call method without the object being registered yet
        try{
            uow.registerRelationship( c, Contact.AccountId, Account.Id, a );
            System.Assert.fail( 'This should never happen as the Contact SObjectType isn\'t registered as new/dirty in UOW and therefore no relation can be set' );
        } catch( fflib_SObjectUnitOfWork.UnitOfWorkException ex ){
            System.Assert.areEqual(
                'You can\'t register a Relationship to a sObjectType which is not implemented for this unit of work: Contact',
                ex.getMessage(),
                'Expected different message'
            );
        }
    }

    @IsTest
    private static void registerRelationship_ExternalId_InvalidInputs(){
        // Given - create data
        Account a = new Account( Id = ID_ACCOUNT );
        Contact c = new Contact();
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork( new List<SObjectType>{ Contact.SObjectType } );
        uow.registerNew( c );

        // When/Then - ExternalIdField is not an ExternalId
        try{
            uow.registerRelationship( c, Contact.AccountId, Account.Id, a );
            System.Assert.fail( 'This should never happen as Account.Id is not an ExternalId' );
        } catch( fflib_SObjectUnitOfWork.UnitOfWorkException ex ){
            System.Assert.areEqual( 'Invalid argument: externalIdField. Field supplied is not a marked as an External Identifier.', ex.getMessage(), 'Expected different message' );
        }

        // When/Then - ExternalIdField is not a valid field on the parent object
        try{
            uow.registerRelationship( c, Contact.AccountId, Opportunity.StageName, a );
            System.Assert.fail( 'This should never happen as Opportunity.StageName is not a valid field on Account' );
        } catch( fflib_SObjectUnitOfWork.UnitOfWorkException ex ){
            System.Assert.areEqual( 'Invalid argument: externalIdField. Field supplied is not a known field on the target sObject.', ex.getMessage(), 'Expected different message' );
        }

        // When/Then - RelationalField is not a relational field
        try{
            uow.registerRelationship( c, Contact.Id, Account.Id, a );
            System.Assert.fail( 'This should never happen as Contact.Id is not a relational field' );
        } catch( fflib_SObjectUnitOfWork.UnitOfWorkException ex ){
            System.Assert.areEqual( 'Invalid argument: relatedToField. Field supplied is not a relationship field.', ex.getMessage(), 'Expected different message' );
        }

        // When/Then - RelationalField is not provided
        try{
            uow.registerRelationship( c, null, null, a );
            System.Assert.fail( 'This should never happen as RelationalField is not provided' );
        } catch( fflib_SObjectUnitOfWork.UnitOfWorkException ex ){
            System.Assert.areEqual( 'Invalid argument: relatedToField or externalIdField is not provided.', ex.getMessage(), 'Expected different message' );
        }
    }

    @IsTest
    private static void registerRelationship_ExternalIdWrapper(){
        // Given - create data
        Account a = new Account( Id = ID_ACCOUNT );
        Contact c = new Contact();
        System.Assert.areEqual( null, c.Account, 'Expected Account parent reference to be null/not initiated' );
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork( new List<SObjectType>{ Contact.SObjectType } );
        uow.registerNew( c );

        fflib_SObjectUnitOfWork.RelationshipByExternalId wrapper = new fflib_SObjectUnitOfWork.RelationshipByExternalId();
        wrapper.record = c;
        wrapper.parentSObjectType = Account.SObjectType;
        wrapper.parentExternalIdField = Account.Id;
        wrapper.externalIdValue = a.Id;
        wrapper.relationshipName = 'Account';
        wrapper.restrictedTo = fflib_SObjectUnitOfWork.DMLActions.dNEW;

        System.Assert.isFalse( wrapper.wasResolved(), 'Expected default resolve-flag to be set to false' );

        // When - Attempt to resolve() for a different DMLAction on wrapper
        wrapper.resolve( fflib_SObjectUnitOfWork.DMLActions.dUPDATE );
        Contact cResolved = ( Contact ) wrapper.getRecord();

        // Then - Validate Contact has not been changed/cResolved.Account still null
        System.Assert.isNull( cResolved.Account, 'Expected Account parent reference to still be null given mismatch on restrictedTo DMLAction' );

        // When - Perform resolve() method on wrapper for the similarly set DMLAction
        wrapper.resolve( wrapper.restrictedTo );
        cResolved = ( Contact ) wrapper.getRecord();

        // Then - Validate whether the Account value was set via an Object (with ExternalId field populated)
        System.Assert.isNotNull( cResolved.Account, 'Expected the relation to Account to be populated with an object' );
        System.Assert.isNull( cResolved.AccountId, 'Expected the direct lookup field to have no Id set, as is per object' );
        System.Assert.areEqual( a.Id, cResolved.Account.Id, 'Expected the AccountId (relation ExternalId) to be resolved on the object' );
        System.Assert.isTrue( wrapper.wasResolved(), 'Expected resolve-flag to be set to true after successful resolve-action' );

        // When - changing wrapper externalIdValue and trying to resolve() again, should skip as Relation is already resolved
        wrapper.externalIdValue = 'Something else';
        wrapper.resolve();
        System.Assert.areNotEqual( wrapper.externalIdValue, c.Account.Id, 'Expected value to NOT be set to "new" external value as previously resolved' );
        System.Assert.areEqual( a.Id, c.Account.Id, 'Expected the AccountId (relation ExternalId) to still be set to original value' );
    }

    @IsTest
    private static void performAction_Operation_EmptyInput_Exception(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_Database_IDML m_IDML = ( fflib_Database_IDML ) mocks.mock( fflib_Database_IDML.class );

        // Given - create data
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork( new List<SObjectType>() );
        List<Messaging.SingleEmailMessage> msgList = new List<Messaging.SingleEmailMessage>{ new Messaging.SingleEmailMessage() };
        String exceptionMessage = 'Fake failure during publishing of before transaction event';

        // Set mocks
        mocks.startStubbing();
        ( ( fflib_Database_IDML ) mocks.doThrowWhen( new fflib.MissingDataException( exceptionMessage ), m_IDML ) ).performOperation( fflib_SObjectUnitOfWork.Operations.SEND_EMAIL, msgList );
        mocks.stopStubbing();
        uow.m_dml = m_IDML;

        // When/Then - Providing no records results in early exist and thus no relations resolved or performOperation called
        uow.performAction( fflib_SObjectUnitOfWork.Operations.SEND_EMAIL, null );
        ( ( fflib_Database_IDML ) mocks.verify( m_IDML, 0 ) ).performOperation( ( fflib_SObjectUnitOfWork.Operations ) fflib_Match.anyObject(), ( List<Object> ) fflib_Match.isNull() );
        ( ( fflib_Database_IDML ) mocks.verify( m_IDML, 0 ) ).performOperation( ( fflib_SObjectUnitOfWork.Operations ) fflib_Match.anyObject(), ( List<Object> ) fflib_Match.isNotNull() );

        try{
            uow.performAction( fflib_SObjectUnitOfWork.Operations.SEND_EMAIL, msgList );
            System.Assert.fail( 'Expected performOperation() to throw an Exception' );
        } catch( fflib.MissingDataException ex ){
            System.Assert.areEqual( exceptionMessage, ex.getMessage(), 'Expected different Exception message' );
        }
    }

    @IsTest
    private static void saveResults_basics_newResults(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_Database_IDML m_IDML = ( fflib_Database_IDML ) mocks.mock( fflib_Database_IDML.class );

        // Given - create data
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork( new List<SObjectType>{ Account.SObjectType, Contact.SObjectType } );
        List<Account> accList = new List<Account>{ new Account( Name = 'Test' ) };
        Database.SaveResult sr = ( Database.SaveResult ) JSON.deserialize( '{"success":true}', Database.SaveResult.class );

        // Set mocks
        mocks.startStubbing();
        mocks.when( m_IDML.performDMLAction(
            fflib_SObjectUnitOfWork.DMLActions.dNEW,
            accList,
            ( Database.DMLOptions ) null,
            fflib_Database.getAccessLevel( uow.m_securityContext ) )
        ).thenReturn( new List<Database.SaveResult>{ sr } );
        mocks.stopStubbing();
        ( ( fflib_SObjectUnitOfWork ) uow ).m_dml = m_IDML;

        // When - Records registered and SaveResults requested, validate whether DML response is returned
        uow.registerNew( accList );
        uow.setSaveResultsRequired( true );
        uow.commitWork();
        List<Database.SaveResult> respSR_Account = uow.getNewResults( Account.SObjectType );
        List<Database.SaveResult> respSR_Contact = uow.getNewResults( Contact.SObjectType );
        List<Database.SaveResult> respSR_Lead = uow.getNewResults( Lead.SObjectType );
        List<Database.SaveResult> respSR_AccountDirty = uow.getDirtyResults( Account.SObjectType );

        // Then - Validate
        System.Assert.areEqual( 1, respSR_Account?.size(), 'Expected one SaveResult returned for Account SObject' );
        System.Assert.areEqual( sr, respSR_Account[ 0 ], 'Expected the SR to be the response of DMLProxy' );
        System.Assert.areEqual( null, respSR_Contact, 'Expected no List to be initiated for an SObjectType not registered in this UOW' );
        System.Assert.areEqual( null, respSR_Lead, 'Expected no List to be initiated for an SObjectType not setup in this UOW' );
        System.Assert.areEqual( null, respSR_AccountDirty, 'Expected no List to be initiated for a DMLAction which wasn\'t registered in this UOW' );
    }

    /**
     * Method to validate (to prevent massive duplicate initiations)
     * 1) SaveResults are properly initiated and returned when requested and all DMLActions and Operations performed
     * 2) Functionality of hasWork()
     * 3) At end of each commitWork() by default resetWork() to be called
     * 4) commitWork() logic to be skipped when there is no work registered
     * 5) SaveResults are fully reset by resetSaveResults()
     */
    @IsTest
    private static void saveResults_all_hasWork_resets(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_Database_IDML m_IDML = ( fflib_Database_IDML ) mocks.mock( fflib_Database_IDML.class );

        // Given - create data
        SObjectType eventSObjectType = BatchApexErrorEvent.SObjectType;
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork( new List<SObjectType>{ Account.SObjectType, eventSObjectType } );
        List<Account> accList_New = new List<Account>{ new Account( Name = 'Test' ) };
        List<Account> accList_WithId = new List<Account>{ new Account( Name = 'Test 2', Id = ID_ACCOUNT ) };
        List<Messaging.SingleEmailMessage> emailMsgList = new List<Messaging.SingleEmailMessage>{ new Messaging.SingleEmailMessage() };
        List<Approval.ProcessSubmitRequest> apprProcessList = new List<Approval.ProcessSubmitRequest>{ new Approval.ProcessSubmitRequest() };
        List<SObject> evtList = new List<SObject>{ eventSObjectType.newSObject() };
        Database.SaveResult srNew = ( Database.SaveResult ) JSON.deserialize( '{"success":true}', Database.SaveResult.class );
        Database.SaveResult srDirty = ( Database.SaveResult ) JSON.deserialize( '{"success":true}', Database.SaveResult.class );
        Database.DeleteResult srDeleted = ( Database.DeleteResult ) JSON.deserialize( '{"success":true}', Database.DeleteResult.class );
        Database.EmptyRecycleBinResult srEmptyRecycle = ( Database.EmptyRecycleBinResult ) JSON.deserialize( '{"success":true}', Database.EmptyRecycleBinResult.class );
        Database.UndeleteResult srUndeleted = ( Database.UndeleteResult ) JSON.deserialize( '{"success":true}', Database.UndeleteResult.class );
        Database.SaveResult srPublish = ( Database.SaveResult ) JSON.deserialize( '{"success":true}', Database.SaveResult.class );
        Messaging.SendEmailResult srEmail = ( Messaging.SendEmailResult ) JSON.deserialize( '{"success":true}', Messaging.SendEmailResult.class );
        Approval.ProcessResult srApprovals = ( Approval.ProcessResult ) JSON.deserialize( '{"success":true}', Approval.ProcessResult.class );
        AccessLevel accessLevel = fflib_Database.getAccessLevel( uow.m_securityContext );

        // Set mocks
        mocks.startStubbing();
        mocks.when( m_IDML.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dNEW, accList_New, ( Database.DMLOptions ) null, accessLevel ) ).thenReturn( new List<Database.SaveResult>{ srNew } );
        mocks.when( m_IDML.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dUPDATE, accList_New, ( Database.DMLOptions ) null, accessLevel ) ).thenReturn( new List<Database.SaveResult>{ srDirty } );
        mocks.when( m_IDML.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dDELETE, accList_WithId, true, accessLevel ) ).thenReturn( new List<Database.DeleteResult>{ srDeleted } );
        mocks.when( m_IDML.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dEMPTY_RECBIN, accList_WithId, accessLevel ) ).thenReturn( new List<Database.EmptyRecycleBinResult>{ srEmptyRecycle } );
        mocks.when( m_IDML.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dUNDELETE, accList_WithId, true, accessLevel ) ).thenReturn( new List<Database.UndeleteResult>{ srUndeleted } );
        mocks.when( m_IDML.performDMLAction( fflib_SObjectUnitOfWork.DMLActions.dPUB_AFTER_SUCCESS, evtList, accessLevel ) ).thenReturn( new List<Database.SaveResult>{ srPublish } );
        mocks.when( m_IDML.performOperation( fflib_SObjectUnitOfWork.Operations.SEND_EMAIL, emailMsgList ) ).thenReturn( new List<Messaging.SendEmailResult>{ srEmail } );
        mocks.when( m_IDML.performOperation( fflib_SObjectUnitOfWork.Operations.PROCESS_APPROVAL_PROCESS, apprProcessList ) ).thenReturn( new List<Approval.ProcessResult>{ srApprovals } );
        mocks.stopStubbing();
        ( ( fflib_SObjectUnitOfWork ) uow ).m_dml = m_IDML;

        // When - Records registered and SaveResults requested, validate whether DML response is returned
        uow.registerNew( accList_New );
        uow.registerDirty( accList_New );
        uow.registerPermanentlyDeleted( accList_WithId ); // Delete & EmptyRecycleBin
        uow.registerUndeleted( accList_WithId );
        uow.registerPublishAfterSuccessTransaction( evtList );
        uow.registerEmail( emailMsgList[ 0 ] );
        uow.registerApprovalProcess( apprProcessList[ 0 ] );
        uow.setSaveResultsRequired( true );

        // Validate - Has Work
        System.Assert.isTrue( uow.hasWork(), 'Expected work to be registered' );
        uow.commitWork();
        System.Assert.isFalse( uow.hasWork(), 'Expected work to be reset at the end of commitWork() to prevent duplicate work' );

        // Then - Validate whether DMLProxy responses were correctly returned (and get-methods work as designed)
        List<Database.SaveResult> respSR_New_Account = uow.getNewResults( Account.SObjectType );
        List<Database.SaveResult> respSR_Dirty_Account = uow.getDirtyResults( Account.SObjectType );
        List<Database.DeleteResult> respSR_Delete_Account = uow.getDeletedResults( Account.SObjectType );
        List<Database.UndeleteResult> respSR_Undelete_Account = uow.getUndeletedResults( Account.SObjectType );
        List<Database.EmptyRecycleBinResult> respSR_EmptyBin_Account = uow.getEmptyRecycleBinResults( Account.SObjectType );
        List<Database.SaveResult> respSR_Publish_Evt = uow.getPublishResults( eventSObjectType );
        List<Messaging.SendEmailResult> respSR_Email = uow.getEmailResults();
        List<Approval.ProcessResult> respSR_Approvals = uow.getApprovalProcessResults();

        System.Assert.areEqual( 1, respSR_New_Account?.size(), 'Expected 1 SaveResult for New Accounts' );
        System.Assert.areEqual( srNew, respSR_New_Account[ 0 ], 'Expected SR to match DML Proxy response for New Account' );
        System.Assert.areEqual( 1, respSR_Dirty_Account?.size(), 'Expected 1 SaveResult for Dirty Accounts' );
        System.Assert.areEqual( srDirty, respSR_Dirty_Account[ 0 ], 'Expected SR to match DML Proxy response for Dirty Account' );
        System.Assert.areEqual( 1, respSR_Delete_Account?.size(), 'Expected 1 SaveResult for Deleted Accounts' );
        System.Assert.areEqual( srDeleted, respSR_Delete_Account[ 0 ], 'Expected SR to match DML Proxy response for Deleted Account' );
        System.Assert.areEqual( 1, respSR_Undelete_Account?.size(), 'Expected 1 SaveResult for Undeleted Accounts' );
        System.Assert.areEqual( srUndeleted, respSR_Undelete_Account[ 0 ], 'Expected SR to match DML Proxy response for Undeleted Account' );
        System.Assert.areEqual( 1, respSR_EmptyBin_Account?.size(), 'Expected 1 SaveResult for EmptyRecycleBin Accounts' );
        System.Assert.areEqual( srEmptyRecycle, respSR_EmptyBin_Account[ 0 ], 'Expected SR to match DML Proxy response for EmptyRecycleBin Account' );
        System.Assert.areEqual( 1, respSR_Publish_Evt?.size(), 'Expected 1 SaveResult for PlatformEvent' );
        System.Assert.areEqual( srPublish, respSR_Publish_Evt[ 0 ], 'Expected SR to match DML Proxy response for PlatformEvents' );
        System.Assert.areEqual( 1, respSR_Email?.size(), 'Expected 1 SaveResult for Emails' );
        System.Assert.areEqual( srEmail, respSR_Email[ 0 ], 'Expected SR to match DML Proxy response for Emails' );
        System.Assert.areEqual( 1, respSR_Approvals?.size(), 'Expected 1 SaveResult for ApprovalProcesses' );
        System.Assert.areEqual( srApprovals, respSR_Approvals[ 0 ], 'Expected SR to match DML Proxy response for ApprovalProcesses' );

        // When/Then - another commitWork() without registration would result in a early-quite (not even calling resetSaveResults())
        uow.commitWork();
        System.Assert.areEqual( 1, uow.getNewResults( Account.SObjectType )?.size(), 'Expected New Account Results not yet to be reset as there was no work' );

        // When/Then - calling resetSaveResults() to ensure all Maps are reset
        uow.resetSaveResults();
        System.Assert.areEqual( null, uow.getNewResults( Account.SObjectType ), 'Expected reset New Account Results' );
        System.Assert.areEqual( null, uow.getDirtyResults( Account.SObjectType ), 'Expected reset Dirty Account Results' );
        System.Assert.areEqual( null, uow.getDeletedResults( Account.SObjectType ), 'Expected reset Deleted Account Results' );
        System.Assert.areEqual( null, uow.getUndeletedResults( Account.SObjectType ), 'Expected reset Undeleted Account Results' );
        System.Assert.areEqual( null, uow.getEmptyRecycleBinResults( Account.SObjectType ), 'Expected reset EmptyRecyclebin Account Results' );
        System.Assert.areEqual( null, uow.getPublishResults( eventSObjectType ), 'Expected reset PlatformEvent Results' );
        System.Assert.areEqual( null, uow.getPublishResults( eventSObjectType ), 'Expected reset PlatformEvent Results' );
        System.Assert.areEqual( null, uow.getEmailResults(), 'Expected reset Email Results' );
        System.Assert.areEqual( null, uow.getApprovalProcessResults(), 'Expected reset Email Results' );
    }
}