/**
 * Copyright (c), FinancialForce.com, inc
 * Copyright (c), Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
/**
 * Unit test class for fflib_Application class.
 *  Intentionally set both the class access & inner factory, service/selector/domain class's access modifiers to public, due to how System.Type resolves references to inner class types.
 *  (https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_methods_system_type.htm#apex_System_Type_forName_2)
 *  The usage of Type.forName methods to retrieve the type of an Apex class, which can be a built-in or a user-defined class can only be used to retrieve the type of public and global classes, and not private classes
 *  (even if the context user has access)
 *
 *  @author     Rafael Fernandes dos Santos (rfernandesdossantos@deloitte.nl)
 *  @created    February 2022
 */
@IsTest( isParallel = true )
private with sharing class fflib_ApplicationTest{

    // Configure and create factories for test-mode; normally these are already constructed/prepared in fflib-class
    private static final fflib_Application.SelectorFactory selectorTestFactory = new fflib_Application.SelectorFactory();
    private static final fflib_Application.DomainFactory domainTestFactory = new fflib_Application.DomainFactory( fflib_ApplicationTest.selectorTestFactory );
    private static final fflib_Application.ServiceFactory serviceTestFactory = new fflib_Application.ServiceFactory();
    private static final fflib_Application.UnitOfWorkFactory unitOfWorkTestFactory = new fflib_Application.UnitOfWorkFactory();

    private static final String accountSObjTypeText = String.valueOf( Account.SObjectType );
    private static final String oppSObjTypeText = String.valueOf( Opportunity.SObjectType );
    private static final String contactSObjTypeText = String.valueOf( Contact.SObjectType );
    private static final String accountSrvImplTypeText = String.valueOf( IAccountService.class );
    private static final String oppSrvImplTypeText = String.valueOf( IOpportunitiesService.class );

    private static final List<FFLIB_Domain_Config__mdt> accountDomainImpls = new List<FFLIB_Domain_Config__mdt>{
        new FFLIB_Domain_Config__mdt( Implementation_Type__c = 'fflib_ApplicationTest.AccountsConstructor', SObjectType__c = accountSObjTypeText )
    };

    private static final List<FFLIB_Domain_Config__mdt> contactDomainImpls = new List<FFLIB_Domain_Config__mdt>{
        new FFLIB_Domain_Config__mdt( Implementation_Type__c = 'fflib_ApplicationTest.ContactsConstructor', SObjectType__c = contactSObjTypeText )
    };

    private static final List<FFLIB_Domain_Config__mdt> oppDomainImpls = new List<FFLIB_Domain_Config__mdt>{
        new FFLIB_Domain_Config__mdt( Implementation_Type__c = 'fflib_ApplicationTest.OpportunitiesConstructor', SObjectType__c = oppSObjTypeText )
    };

    private static final List<FFLIB_Selector_Config__mdt> accountSelImpls = new List<FFLIB_Selector_Config__mdt>{
        new FFLIB_Selector_Config__mdt( Implementation_Type__c = 'fflib_ApplicationTest.AccountsSelector', SObjectType__c = accountSObjTypeText )
    };

    private static final List<FFLIB_Selector_Config__mdt> oppSelImpls = new List<FFLIB_Selector_Config__mdt>{
        new FFLIB_Selector_Config__mdt( Implementation_Type__c = 'fflib_ApplicationTest.OpportunitiesSelector', SObjectType__c = oppSObjTypeText )
    };

    private static final List<FFLIB_Service_Config__mdt> accountSrvImpls = new List<FFLIB_Service_Config__mdt>{
        new FFLIB_Service_Config__mdt( Implementation_Type__c = 'fflib_ApplicationTest.AccountsServiceImpl', Interface_Type__c = accountSrvImplTypeText )
    };

    private static final List<FFLIB_Service_Config__mdt> oppSrvImpls = new List<FFLIB_Service_Config__mdt>{
        new FFLIB_Service_Config__mdt( Implementation_Type__c = 'fflib_ApplicationTest.OpportunitiesServiceImpl', Interface_Type__c = oppSrvImplTypeText )
    };

    /**
     * UnitOfWorkFactory test methods
     */
    @IsTest
    private static void unitOfWorkFactory_shouldGiveStandardImplsAndMockImpl(){
        // Standard behaviour
        System.Assert.isInstanceOfType( unitOfWorkTestFactory.newInstance(), fflib_SObjectUnitOfWork.class );

        // Mocking behaviour
        fflib_ISObjectUnitOfWork uowMock = ( fflib_ISObjectUnitOfWork ) new fflib_ApexMocks().mock( fflib_ISObjectUnitOfWork.class );
        unitOfWorkTestFactory.setMock( uowMock );
        System.Assert.areEqual( uowMock, unitOfWorkTestFactory.newInstance() );
    }

    @IsTest
    private static void unitOfWorkFactory_shouldGiveStandardImplsAndMockImplWithCustomTypes(){
        // Standard behaviour
        System.Assert.isInstanceOfType( unitOfWorkTestFactory.newInstance( new List<SObjectType>{ Account.SObjectType } ), fflib_SObjectUnitOfWork.class );

        // Mocking behaviour
        fflib_ISObjectUnitOfWork uowMock = ( fflib_ISObjectUnitOfWork ) new fflib_ApexMocks().mock( fflib_ISObjectUnitOfWork.class );
        unitOfWorkTestFactory.setMock( uowMock );
        System.Assert.areEqual( uowMock, unitOfWorkTestFactory.newInstance( new List<SObjectType>{ Account.SObjectType } ) );
    }

    @IsTest
    private static void unitOfWorkFactory_newInstance_DatabaseContext(){
        // Given - inject UOW configs via the factory's appConfig mock (avoids real metadata query)
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ApplicationConfig m_ApplicationConfig = ( fflib_ApplicationConfig ) mocks.mock( fflib_ApplicationConfig.class );
        mocks.startStubbing();
        mocks.when( m_ApplicationConfig.getUnitOfWorkConfigs() ).thenReturn(
            new List<FFLIB_UOW_Config__mdt>{ new FFLIB_UOW_Config__mdt( SObjectType__c = accountSObjTypeText, SortOrder__c = 1 ) }
        );
        mocks.stopStubbing();
        fflib_Application.appConfig = m_ApplicationConfig;

        // When - perform test the unit of work is instantiated from the Application Class and the record is registered and committed
        fflib_ISObjectUnitOfWork unitOfWork = unitOfWorkTestFactory.newInstance( fflib_Database.Context.FULL );

        // Then - validate correct security context
        System.Assert.areEqual( fflib_Database.Context.FULL, ( ( fflib_SObjectUnitOfWork ) unitOfWork ).m_securityContext );
    }

    @IsTest
    private static void unitOfWorkFactory_newInstance_CustomObjectTypesAndDatabaseContext(){
        // No config injection needed — List<SObjectType> constructor bypasses uowConfigs entirely
        // When - perform test the unit of work is instantiated from the Application Class and the record is registered and committed
        fflib_ISObjectUnitOfWork unitOfWork = unitOfWorkTestFactory.newInstance(
            new List<SObjectType>{ Account.SObjectType },
            fflib_Database.Context.FULL
        );

        // Then - validate correct security context
        System.Assert.areEqual( fflib_Database.Context.FULL, ( ( fflib_SObjectUnitOfWork ) unitOfWork ).m_securityContext );
    }

    @IsTest
    private static void unitOfWorkFactory_defineMock(){
        fflib_ApexMocks mocks = new fflib_ApexMocks();

        // When - perform test
        fflib_ISObjectUnitOfWork uowMock = unitOfWorkTestFactory.defineMock( mocks );

        // Then - validate returned uowMock is a mocked instance, and was set to ensure any sequential newInstance() returns that mock
        System.Assert.isNotNull( uowMock, 'Expecting an initiated mocked UOW to be returned; allowing to stub/redefine methods' );
        System.Assert.areEqual( uowMock, unitOfWorkTestFactory.newInstance(), 'Expected the mocked UOW to be returned for new instances, given the setting of mock' );
    }

    /**
     * ServiceFactory test methods
     */
    @IsTest
    private static void serviceFactory_shouldGiveRegisteredImplsAndMockImpls(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ApplicationConfig appConfigMock = ( fflib_ApplicationConfig ) mocks.mock( fflib_ApplicationConfig.class );

        // Given - create data
        String contactSrvImplText = String.valueOf( IContactService.class );

        // Set mocks
        mocks.startStubbing();
        mocks.when( appConfigMock.getServiceConfig( accountSrvImplTypeText ) ).thenReturn( accountSrvImpls );
        mocks.when( appConfigMock.getServiceConfig( oppSrvImplTypeText ) ).thenReturn( oppSrvImpls );
        mocks.when( appConfigMock.getServiceConfig( contactSrvImplText ) ).thenReturn( new List<FFLIB_Service_Config__mdt>() );
        mocks.stopStubbing();
        // Injecting the application config mock
        fflib_Application.appConfig = appConfigMock;

        // Standard behaviour
        System.Assert.isInstanceOfType( serviceTestFactory.newInstance( IAccountService.class ), AccountsServiceImpl.class );
        System.Assert.isInstanceOfType( serviceTestFactory.newInstance( IOpportunitiesService.class ), OpportunitiesServiceImpl.class );
        try{
            serviceTestFactory.newInstance( IContactService.class );
            System.Assert.fail( 'Expected an exception to be thrown. This assertion should never be triggered' );
        } catch( fflib_Application.DeveloperException e ){
            System.Assert.areEqual( 'No implementation registered for service interface ' + IContactService.class.getName(), e.getMessage() );
        }

        // Mocking behaviour
        serviceTestFactory.setMock( IAccountService.class, new AccountsServiceMock() );
        System.Assert.isInstanceOfType( serviceTestFactory.newInstance( IOpportunitiesService.class ), OpportunitiesServiceImpl.class );
        System.Assert.isInstanceOfType( serviceTestFactory.newInstance( IAccountService.class ), AccountsServiceMock.class );
        ( ( fflib_ApplicationConfig ) mocks.verify( appConfigMock, 1 ) ).getServiceConfig( accountSrvImplTypeText );
        ( ( fflib_ApplicationConfig ) mocks.verify( appConfigMock, 1 ) ).getServiceConfig( oppSrvImplTypeText );
        ( ( fflib_ApplicationConfig ) mocks.verify( appConfigMock, 1 ) ).getServiceConfig( contactSrvImplText );
    }

    @IsTest
    private static void serviceFactory_noGivenRegisteredImpls(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ApplicationConfig appConfigMock = ( fflib_ApplicationConfig ) mocks.mock( fflib_ApplicationConfig.class );

        // Given - create data
        String contactSrvImplText = String.valueOf( IContactService.class );

        // Then - validate
        try{
            serviceTestFactory.newInstance( IContactService.class );
            System.Assert.fail( 'Expected fflib_Application.DeveloperException to be thrown. This assertion should never be triggered' );
        } catch( fflib_Application.DeveloperException e ){
            System.Assert.areEqual( 'No implementation registered for service interface ' + IContactService.class.getName(), e.getMessage() );
        }
        ( ( fflib_ApplicationConfig ) mocks.verify( appConfigMock, 0 ) ).getServiceConfig( contactSrvImplText );

        // Set mocks
        mocks.startStubbing();
        mocks.when( appConfigMock.getServiceConfig( contactSrvImplText ) ).thenReturn(
            new List<FFLIB_Service_Config__mdt>{ new FFLIB_Service_Config__mdt( Implementation_Type__c = 'ContactService', Interface_Type__c = contactSrvImplText ) }
        );
        mocks.stopStubbing();
        // Injecting the application config mock
        fflib_Application.appConfig = appConfigMock;

        // Then - validate
        try{
            serviceTestFactory.newInstance( IContactService.class );
            System.Assert.fail( 'Expected fflib_Application.DeveloperException to be thrown. This assertion should never be triggered' );
        } catch( fflib_Application.DeveloperException e ){
            System.Assert.areEqual( 'No implementation registered for service interface ' + IContactService.class.getName(), e.getMessage() );
        }
        ( ( fflib_ApplicationConfig ) mocks.verify( appConfigMock, 1 ) ).getServiceConfig( contactSrvImplText );
    }

    /**
     * Test method for defineMock on ServiceFactory to verify the application of mocks.mock (calling Test.createStub()) and assignment to mock-map
     * Note: Test.createStub( classToMock, this ); requires top-level classes, so inner-classes can't be applied
     *       Additionally, two classes are called, to verify the Map-assignment, including and excluding Interface-input-parameter
     */
    @IsTest
    private static void serviceFactory_defineMock(){
        fflib_ApexMocks mocks = new fflib_ApexMocks();

        // When - perform test - without Interface
        Object serviceMock1 = serviceTestFactory.defineMock( mocks, fflib_ApplicationConfig.class );

        // Then - validate returned serviceMock to be a stubbed instance of requested Class Type and whether any next newInstance() returns that mock
        System.Assert.isNotNull( serviceMock1, 'SM1 - Expecting a stubbed instance to be returned; allowing to stub/redefine specific methods' );
        System.Assert.isInstanceOfType( serviceMock1, fflib_ApplicationConfig.class, 'SM1 - Expected the stubbed object to be an instance of the requested Type' );
        System.Assert.isNull( ( ( fflib_ApplicationConfig ) serviceMock1 ).getDomainConfig( 'dummy' ), 'SM1 - Expected any non-void method to default return null since stubbed' );
        System.Assert.areEqual( serviceMock1, serviceTestFactory.newInstance( fflib_ApplicationConfig.class ), 'SM1 - Expected the mocked Service class to be returned for new instances, given the setting of mock' );

        // When - perform test - specifying any Interface to be set on mock-map
        Object serviceMock2 = serviceTestFactory.defineMock( mocks, fflib_AggregateResult.class, IAccountService.class );

        // Then - validate returned serviceMock to be a stubbed instance of requested Class Type and whether any next newInstance() returns that mock
        System.Assert.isNotNull( serviceMock2, 'SM2 - Expecting a stubbed instance to be returned; allowing to stub/redefine methods' );
        System.Assert.isInstanceOfType( serviceMock2, fflib_AggregateResult.class, 'SM2 - Expected the stubbed object to be an instance of the requested Type' );
        System.Assert.isNull( ( ( fflib_AggregateResult ) serviceMock2 ).get( 'fakefield' ), 'SM2 - Expected any non-void method to default return null since stubbed. When not stubbed, a null-pointer exception is expected' );
        System.Assert.areEqual( serviceMock2, serviceTestFactory.newInstance( IAccountService.class ), 'SM2 - Expected the mocked Service class to be returned for Interface, given the setting of mock' );
        try{
            serviceTestFactory.newInstance( fflib_AggregateResult.class );
            System.Assert.fail( 'An Exception should have thrown, given no mock to be set, as mock was set on Interface and not on class, nor an fflib_Service_Config__mdt to exist' );
        } catch( fflib_Application.DeveloperException ex ){
            System.Assert.areEqual(
                'No implementation registered for service interface fflib_AggregateResult',
                ex.getMessage(),
                'Expected different exception message'
            );
        }
    }

    /**
     * SelectorFactory test methods
     */
    @IsTest // To be deprecated
    private static void selectorFactory_shouldGiveRegisteredImplsWithDefaultContext(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ApplicationConfig appConfigMock = ( fflib_ApplicationConfig ) mocks.mock( fflib_ApplicationConfig.class );

        // Given - create data
        String apexSObjTypeText = String.valueOf( ApexClass.SObjectType );
        // Set mocks
        mocks.startStubbing();
        mocks.when( appConfigMock.getSelectorConfig( accountSObjTypeText ) ).thenReturn( accountSelImpls );
        mocks.when( appConfigMock.getSelectorConfig( oppSObjTypeText ) ).thenReturn( oppSelImpls );
        mocks.when( appConfigMock.getSelectorConfig( apexSObjTypeText ) ).thenReturn( new List<FFLIB_Selector_Config__mdt>() );
        mocks.stopStubbing();
        // Injecting the application config mock
        fflib_Application.appConfig = appConfigMock;

        // Then - validate
        System.Assert.isInstanceOfType( selectorTestFactory.newInstance( Account.SObjectType ), AccountsSelector.class );
        System.Assert.isInstanceOfType( selectorTestFactory.newInstance( Opportunity.SObjectType ), OpportunitiesSelector.class );
        try{
            selectorTestFactory.newInstance( ApexClass.SObjectType );
            System.Assert.fail( 'Expected fflib_Application.DeveloperException to be thrown. This assertion should never be triggered' );
        } catch( fflib_Application.DeveloperException e ){
            System.Assert.areEqual( 'Selector class not found for SObjectType ApexClass', e.getMessage() );
        }
        ( ( fflib_ApplicationConfig ) mocks.verify( appConfigMock, 1 ) ).getSelectorConfig( accountSObjTypeText );
        ( ( fflib_ApplicationConfig ) mocks.verify( appConfigMock, 1 ) ).getSelectorConfig( oppSObjTypeText );
        ( ( fflib_ApplicationConfig ) mocks.verify( appConfigMock, 1 ) ).getSelectorConfig( apexSObjTypeText );
    }

    @IsTest
    private static void selectorFactory_noGivenRegisteredImpls(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ApplicationConfig appConfigMock = ( fflib_ApplicationConfig ) mocks.mock( fflib_ApplicationConfig.class );

        // Given - create data
        String apexSObjTypeText = String.valueOf( ApexClass.SObjectType );

        // Then - validate
        try{
            selectorTestFactory.newInstance( ApexClass.SObjectType );
            System.Assert.fail( 'Expected fflib_Application.DeveloperException to be thrown. This assertion should never be triggered' );
        } catch( fflib_Application.DeveloperException e ){
            System.Assert.areEqual( 'Selector class not found for SObjectType ApexClass', e.getMessage() );
        }
        ( ( fflib_ApplicationConfig ) mocks.verify( appConfigMock, 0 ) ).getSelectorConfig( apexSObjTypeText );

        // Set mocks
        mocks.startStubbing();
        mocks.when( appConfigMock.getSelectorConfig( apexSObjTypeText ) ).thenReturn(
            new List<FFLIB_Selector_Config__mdt>{ new FFLIB_Selector_Config__mdt( Implementation_Type__c = 'ApexClassSelector', SObjectType__c = accountSObjTypeText ) }
        );
        mocks.stopStubbing();
        // Injecting the application config mock
        fflib_Application.appConfig = appConfigMock;

        // Then - validate
        try{
            selectorTestFactory.newInstance( ApexClass.SObjectType );
            System.Assert.fail( 'Expected fflib_Application.DeveloperException to be thrown. This assertion should never be triggered' );
        } catch( fflib_Application.DeveloperException e ){
            System.Assert.areEqual( 'Selector class not found for SObjectType ApexClass', e.getMessage() );
        }
        ( ( fflib_ApplicationConfig ) mocks.verify( appConfigMock, 1 ) ).getSelectorConfig( apexSObjTypeText );
    }

    @IsTest
    private static void selectorFactory_selectByIdWithEmptyListShouldGiveException(){
        try{
            selectorTestFactory.selectById( null );
            System.Assert.fail( 'Expected fflib_Application.DeveloperException to be thrown. This assertion should never be triggered' );
        } catch( fflib_Application.DeveloperException e ){
            System.Assert.areEqual( 'Invalid record Id\'s set', e.getMessage() );
        }
        try{
            selectorTestFactory.selectById( new Set<Id>() );
            System.Assert.fail( 'Expected fflib_Application.DeveloperException to be thrown. This assertion should never be triggered' );
        } catch( fflib_Application.DeveloperException e ){
            System.Assert.areEqual( 'Invalid record Id\'s set', e.getMessage() );
        }
    }

    @IsTest
    private static void selectorFactory_selectByIdWithMixedIdTypeListShouldGiveException(){
        try{
            selectorTestFactory.selectById(
                new Set<Id>{
                    fflib_IDGenerator.generate( Opportunity.SObjectType ),
                    fflib_IDGenerator.generate( Account.SObjectType )
                } );
            System.Assert.fail( 'Expected fflib_Application.DeveloperException to be thrown. This assertion should never be triggered' );
        } catch( fflib_Application.DeveloperException e ){
            System.Assert.areEqual( 'Unable to determine SObjectType, Set contains Id\'s from different SObject types', e.getMessage() );
        }
    }

    @IsTest
    private static void selectorFactory_selectByIdShouldReturnResults(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ApplicationConfig appConfigMock = ( fflib_ApplicationConfig ) mocks.mock( fflib_ApplicationConfig.class );
        fflib_ISObjectSelector selectorMock = ( fflib_ISObjectSelector ) mocks.mock( fflib_ISObjectSelector.class );

        // Given - create data
        Id testAccountId = fflib_IDGenerator.generate( Account.SObjectType );
        List<Account> accountsList =
            new List<Account>{
                new Account(
                    Id = testAccountId,
                    Name = 'Test Account' )
            };
        Set<Id> accountIds = new Map<Id, Account>( accountsList ).keySet();

        // Set mocks
        mocks.startStubbing();
        mocks.when( selectorMock.sObjectType() ).thenReturn( Account.SObjectType );
        mocks.when( selectorMock.selectSObjectsById( accountIds ) ).thenReturn( accountsList );
        mocks.when( appConfigMock.getSelectorConfig( oppSObjTypeText ) ).thenReturn( oppSelImpls );
        mocks.stopStubbing();
        selectorTestFactory.setMock( selectorMock );
        // Injecting the application config mock
        fflib_Application.appConfig = appConfigMock;

        // When - perform test
        List<Account> assertAccounts = selectorTestFactory.selectById( accountIds );

        // Then - validate
        System.Assert.areEqual( selectorMock, selectorTestFactory.newInstance( Account.SObjectType ) );
        System.Assert.areEqual( 1, assertAccounts.size() );
        System.Assert.areEqual( testAccountId, assertAccounts[ 0 ].Id );
        System.Assert.areEqual( 'Test Account', assertAccounts[ 0 ].Name );
        System.Assert.isInstanceOfType( selectorTestFactory.newInstance( Opportunity.SObjectType ), OpportunitiesSelector.class );
        ( ( fflib_ApplicationConfig ) mocks.verify( appConfigMock, 0 ) ).getSelectorConfig( accountSObjTypeText );
        ( ( fflib_ApplicationConfig ) mocks.verify( appConfigMock, 1 ) ).getSelectorConfig( oppSObjTypeText );
    }

    @IsTest
    private static void selectorFactory_selectByRelationshipPassRelatedIds(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ApplicationConfig appConfigMock = ( fflib_ApplicationConfig ) mocks.mock( fflib_ApplicationConfig.class );
        fflib_ISObjectSelector selectorMock = ( fflib_ISObjectSelector ) mocks.mock( fflib_ISObjectSelector.class );

        // Given - create data
        Id testAccountId = fflib_IDGenerator.generate( Account.SObjectType );
        Id testOpportunityId = fflib_IDGenerator.generate( Opportunity.SObjectType );
        List<Account> accountsList =
            new List<Account>{
                new Account(
                    Id = testAccountId,
                    Name = 'Test Account' )
            };
        Set<Id> accountIds = new Map<Id, Account>( accountsList ).keySet();

        // Set mocks
        mocks.startStubbing();
        mocks.when( selectorMock.sObjectType() ).thenReturn( Account.SObjectType );
        mocks.when( selectorMock.selectSObjectsById( accountIds ) ).thenReturn( accountsList );
        mocks.when( appConfigMock.getSelectorConfig( oppSObjTypeText ) ).thenReturn( oppSelImpls );
        mocks.stopStubbing();
        selectorTestFactory.setMock( selectorMock );
        // Injecting the application config mock
        fflib_Application.appConfig = appConfigMock;

        // When - perform test
        List<Opportunity> opportunitiesList =
            new List<Opportunity>{
                new Opportunity(
                    Id = testOpportunityId,
                    Account = accountsList[ 0 ],
                    AccountId = testAccountId,
                    Name = 'Test Opportunity 1' ),
                new Opportunity(
                    Id = testOpportunityId,
                    Name = 'Test Opportunity 2' )
            };
        List<Account> assertAccounts = selectorTestFactory.selectByRelationship( opportunitiesList, Opportunity.AccountId );

        // Then - validate
        System.Assert.areEqual( selectorMock, selectorTestFactory.newInstance( Account.SObjectType ) );
        System.Assert.areEqual( 1, assertAccounts.size() );
        System.Assert.areEqual( testAccountId, assertAccounts[ 0 ].Id );
        System.Assert.areEqual( 'Test Account', assertAccounts[ 0 ].Name );
        System.Assert.isInstanceOfType( selectorTestFactory.newInstance( Opportunity.SObjectType ), OpportunitiesSelector.class );
        ( ( fflib_ApplicationConfig ) mocks.verify( appConfigMock, 0 ) ).getSelectorConfig( accountSObjTypeText );
        ( ( fflib_ApplicationConfig ) mocks.verify( appConfigMock, 1 ) ).getSelectorConfig( oppSObjTypeText );
    }

    @IsTest
    private static void selectorFactory_defineMock(){
        fflib_ApexMocks mocks = new fflib_ApexMocks();

        // When - perform test
        fflib_ISObjectSelector selectorMock = selectorTestFactory.defineMock( mocks, fflib_ISObjectSelector.class, Account.SObjectType );

        // Then - validate returned selectorMock to be a stubbed instance, and was set to ensure any sequential newInstance() returns that mock
        System.Assert.isNotNull( selectorMock, 'Expected a stubbed instance to be returned; confirming mocks.mock() being called' );
        System.Assert.areEqual( selectorMock, selectorTestFactory.newInstance( Account.SObjectType ), 'Expected the mocked Selector class to be returned for new instances on Account. Thus, confirming selectorMock was set for Account SObjectType' );
    }

    /**
     * DomainFactory test methods
     */
    @IsTest
    private static void domainFactory_shouldGiveRegisteredImpl(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ApplicationConfig appConfigMock = ( fflib_ApplicationConfig ) mocks.mock( fflib_ApplicationConfig.class );

        // Given - create data
        String testAccountName = 'Test Account';
        String testOppName = 'Test Opportunity';

        // Set mocks
        mocks.startStubbing();
        mocks.when( appConfigMock.getDomainConfig( accountSObjTypeText ) ).thenReturn( accountDomainImpls );
        mocks.when( appConfigMock.getDomainConfig( oppSObjTypeText ) ).thenReturn( oppDomainImpls );
        mocks.stopStubbing();
        // Injecting the application config mock
        fflib_Application.appConfig = appConfigMock;


        // Registered Accounts domain class by SObject List
        Id testAccountId = fflib_IDGenerator.generate( Account.SObjectType );
        fflib_ISObjectDomain domainObjectAcct =
            domainTestFactory.newInstance(
                new List<Account>{
                    new Account(
                        Id = testAccountId,
                        Name = testAccountName )
                } );
        System.Assert.isInstanceOfType( domainObjectAcct, AccountsDomain.class );
        System.Assert.areEqual( testAccountId, domainObjectAcct.getRecords()[ 0 ].Id );

        // Registered Accounts domain class by SObject List - should pick-up the implementation from the mapped config
        testAccountId = fflib_IDGenerator.generate( Account.SObjectType );
        domainObjectAcct =
            domainTestFactory.newInstance(
                new List<SObject>{
                    new Account(
                        Id = testAccountId,
                        Name = testAccountName )
                }
                , Account.SObjectType );
        System.Assert.isInstanceOfType( domainObjectAcct, AccountsDomain.class );
        System.Assert.areEqual( testAccountId, domainObjectAcct.getRecords()[ 0 ].Id );

        // Registered Opportunities domain class by SObject List
        Id testOpportunityId = fflib_IDGenerator.generate( Opportunity.SObjectType );
        fflib_ISObjectDomain domainObjectOpp =
            domainTestFactory.newInstance(
                new List<Opportunity>{
                    new Opportunity(
                        Id = testOpportunityId,
                        Name = testOppName )
                } );
        System.Assert.areEqual( testOpportunityId, domainObjectOpp.getRecords()[ 0 ].Id );
        System.Assert.isInstanceOfType( domainObjectOpp, OpportunitiesDomain.class );

        // Registered Opportunities domain class by SObject List - should pick-up the implementation from the mapped config
        testOpportunityId = fflib_IDGenerator.generate( Opportunity.SObjectType );
        domainObjectOpp =
            domainTestFactory.newInstance(
                new List<SObject>{
                    new Opportunity(
                        Id = testOpportunityId,
                        Name = testOppName )
                }
                , Opportunity.SObjectType );
        System.Assert.areEqual( testOpportunityId, domainObjectOpp.getRecords()[ 0 ].Id );
        System.Assert.isInstanceOfType( domainObjectOpp, OpportunitiesDomain.class );

        // Then - validate
        ( ( fflib_ApplicationConfig ) mocks.verify( appConfigMock, 1 ) ).getDomainConfig( accountSObjTypeText );
        ( ( fflib_ApplicationConfig ) mocks.verify( appConfigMock, 1 ) ).getDomainConfig( oppSObjTypeText );
    }

    @IsTest
    private static void domainFactory_noGivenRegisteredImpls(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ApplicationConfig appConfigMock = ( fflib_ApplicationConfig ) mocks.mock( fflib_ApplicationConfig.class );

        // Given - create data
        String apexSObjTypeText = String.valueOf( ApexClass.SObjectType );

        // Set mocks
        mocks.startStubbing();
        mocks.when( appConfigMock.getDomainConfig( apexSObjTypeText ) ).thenReturn(
            new List<FFLIB_Domain_Config__mdt>{ new FFLIB_Domain_Config__mdt( Implementation_Type__c = 'ApexClassDomain', SObjectType__c = apexSObjTypeText ) }
        );
        mocks.stopStubbing();
        // Injecting the application config mock
        fflib_Application.appConfig = appConfigMock;

        // Then - validate
        try{
            // Registered ApexClass domain class by SObject List
            domainTestFactory.newInstance( new List<ApexClass>{ new ApexClass() } );
            System.Assert.fail( 'Expected fflib_Application.DeveloperException to be thrown. This assertion should never be triggered' );
        } catch( fflib_Application.DeveloperException e ){
            System.Assert.areEqual( 'Domain constructor class not found for SObjectType ApexClass', e.getMessage() );
        }
        ( ( fflib_ApplicationConfig ) mocks.verify( appConfigMock, 1 ) ).getDomainConfig( apexSObjTypeText );
    }

    @IsTest
    private static void domainFactory_shouldGiveRegisteredMocks(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ApplicationConfig appConfigMock = ( fflib_ApplicationConfig ) mocks.mock( fflib_ApplicationConfig.class );
        fflib_ISObjectDomain domainMock = ( fflib_ISObjectDomain ) mocks.mock( fflib_ISObjectDomain.class );

        // Given - create data
        String testAccountName = 'Test Account';
        Id testAccountId = fflib_IDGenerator.generate( Account.SObjectType );

        // Set mocks
        mocks.startStubbing();
        mocks.when( domainMock.sObjectType() ).thenReturn( Account.SObjectType );
        mocks.when( appConfigMock.getDomainConfig( accountSObjTypeText ) ).thenReturn( accountDomainImpls );
        mocks.stopStubbing();
        domainTestFactory.setMock( domainMock );
        // Injecting the application config mock
        fflib_Application.appConfig = appConfigMock;

        // When - perform test
        fflib_ISObjectDomain domainObjectAcct =
            domainTestFactory.newInstance(
                new List<Account>{
                    new Account(
                        Id = testAccountId,
                        Name = testAccountName )
                } );

        // Then - validate
        System.Assert.areEqual( domainMock, domainObjectAcct );

        // When - perform test - should pick-up mocked implementation from mock mapping config
        domainObjectAcct =
            domainTestFactory.newInstance(
                new List<SObject>{
                    new Account(
                        Id = testAccountId,
                        Name = testAccountName )
                }
                , Account.SObjectType );

        // Then - validate
        System.Assert.areEqual( domainMock, domainObjectAcct );
        ( ( fflib_ApplicationConfig ) mocks.verify( appConfigMock, 0 ) ).getDomainConfig( accountSObjTypeText );
    }

    @IsTest
    private static void domainFactory_shouldGiveRegisteredImplWithIds(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ApplicationConfig appConfigMock = ( fflib_ApplicationConfig ) mocks.mock( fflib_ApplicationConfig.class );
        fflib_ISObjectSelector selectorMock = ( fflib_ISObjectSelector ) mocks.mock( fflib_ISObjectSelector.class );

        // Given - create data
        String testAccountName = 'Test Account';
        Id testAccountId = fflib_IDGenerator.generate( Account.SObjectType );
        List<Account> accountsList =
            new List<Account>{
                new Account(
                    Id = testAccountId,
                    Name = testAccountName )
            };
        Set<Id> accountIds = new Map<Id, Account>( accountsList ).keySet();

        // Set mocks
        mocks.startStubbing();
        mocks.when( selectorMock.sObjectType() ).thenReturn( Account.SObjectType );
        mocks.when( selectorMock.selectSObjectsById( accountIds ) ).thenReturn( accountsList );
        mocks.when( appConfigMock.getDomainConfig( accountSObjTypeText ) ).thenReturn( accountDomainImpls );
        mocks.stopStubbing();
        // Injecting the application config mock
        fflib_Application.appConfig = appConfigMock;

        // When - perform test
        selectorTestFactory.setMock( selectorMock );
        fflib_ISObjectDomain domainObjectAcc = domainTestFactory.newInstance( new Set<Id>{ testAccountId } );

        // Then - validate
        List<Account> assertAccounts = ( List<Account> ) domainObjectAcc.getRecords();
        System.Assert.isInstanceOfType( domainObjectAcc, AccountsDomain.class );
        System.Assert.areEqual( testAccountId, domainObjectAcc.getRecords()[ 0 ].Id );
        System.Assert.areEqual( 1, assertAccounts.size() );
        System.Assert.areEqual( testAccountId, assertAccounts[ 0 ].Id );
        System.Assert.areEqual( testAccountName, assertAccounts[ 0 ].Name );
    }

    @IsTest
    private static void domainFactory_shouldGiveExceptionWithGenericList(){
        try{
            domainTestFactory.newInstance( new List<SObject>() );
            System.Assert.fail( 'Expected fflib_Application.DeveloperException to be thrown. This assertion should never be triggered' );
        } catch( fflib_Application.DeveloperException e ){
            System.Assert.areEqual( 'Unable to determine SObjectType', e.getMessage() );
        }
    }

    @IsTest
    private static void domainFactory_shouldGiveExceptionWithNoSObjectType(){
        try{
            domainTestFactory.newInstance( new List<SObject>(), null );
            System.Assert.fail( 'Expected fflib_Application.DeveloperException to be thrown. This assertion should never be triggered' );
        } catch( fflib_Application.DeveloperException e ){
            System.Assert.areEqual( 'Must specify sObjectType', e.getMessage() );
        }
    }

    @IsTest
    private static void domainFactory_shouldGiveExceptionWithInAccessibleConstructor(){
        try{
            domainTestFactory.newInstance( new List<ApexClass>{ new ApexClass( Name = 'Test Class' ) } );
            System.Assert.fail( 'Expected fflib_Application.DeveloperException to be thrown. This assertion should never be triggered' );
        } catch( fflib_Application.DeveloperException e ){
            System.Assert.areEqual( 'Domain constructor class not found for SObjectType ApexClass', e.getMessage() );
        }

        try{
            domainTestFactory.newInstance( new List<SObject>{ new ApexClass( Name = 'Test Class' ) }, ApexClass.SObjectType );
            System.Assert.fail( 'Expected fflib_Application.DeveloperException to be thrown. This assertion should never be triggered' );
        } catch( fflib_Application.DeveloperException e ){
            System.Assert.areEqual( 'Domain constructor class not found for SObjectType ApexClass', e.getMessage() );
        }
    }

    @IsTest
    private static void domainFactory_shouldGiveExceptionWithConstructorClassThatDoesNotSupportIConstructable(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ApplicationConfig appConfigMock = ( fflib_ApplicationConfig ) mocks.mock( fflib_ApplicationConfig.class );

        // Set mocks
        mocks.startStubbing();
        mocks.when( appConfigMock.getDomainConfig( contactSObjTypeText ) ).thenReturn( contactDomainImpls );
        mocks.stopStubbing();
        // Injecting the application config mock
        fflib_Application.appConfig = appConfigMock;

        // Then - validate
        try{
            domainTestFactory.newInstance( new List<Contact>{ new Contact( LastName = 'TestContactLName' ) } );
            System.Assert.fail( 'Expected System.TypeException to be thrown. This assertion should never be triggered' );
        } catch( System.TypeException e ){
            System.Assert.isTrue( Pattern.matches( 'Invalid conversion from runtime type \\w*\\.?fflib_ApplicationTest\\.ContactsConstructor to \\w*\\.?fflib_SObjectDomain\\.IConstructable',
                e.getMessage() ), 'Exception message did not match the expected pattern: ' + e.getMessage() );
        }

        try{
            domainTestFactory.newInstance( new List<SObject>{ new Contact( LastName = 'TestContactLName' ) }, Contact.SObjectType );
            System.Assert.fail( 'Expected System.TypeException to be thrown. This assertion should never be triggered' );
        } catch( System.TypeException e ){
            System.Assert.isTrue( Pattern.matches( 'Invalid conversion from runtime type \\w*\\.?fflib_ApplicationTest\\.ContactsConstructor to \\w*\\.?fflib_SObjectDomain\\.IConstructable2',
                e.getMessage() ), 'Exception message did not match the expected pattern: ' + e.getMessage() );
        }
        // Then - validate
        ( ( fflib_ApplicationConfig ) mocks.verify( appConfigMock, 1 ) ).getDomainConfig( contactSObjTypeText );
    }

    @IsTest
    private static void domainFactory_defineMock(){
        fflib_ApexMocks mocks = new fflib_ApexMocks();

        // When - perform test
        fflib_ISObjectDomain domainMock = domainTestFactory.defineMock( mocks, fflib_ISObjectDomain.class, Account.SObjectType );

        // Then - validate returned domainMock to be a stubbed instance, and was set to ensure any sequential newInstance() returns that mock
        System.Assert.isNotNull( domainMock, 'Expected a stubbed instance to be returned; confirming mocks.mock() being called' );
        System.Assert.areEqual( domainMock, domainTestFactory.newInstance( new List<Account>() ), 'Expected the mocked Domain class to be returned for new instances on Account. Thus, confirming domainMock was set for Account SObjectType' );
    }

    /**
     * Inner-classes representing the different service/selector/domain layers
     */

    public class AccountsDomain extends fflib_SObjectDomain{
        public AccountsDomain( List<Account> sObjectList ){
            super( sObjectList );
        }

        public AccountsDomain( List<SObject> sObjectList, SObjectType sObjectType ){
            super( sObjectList, sObjectType );
        }
    }

    public class AccountsConstructor implements fflib_SObjectDomain.IConstructable2{
        public fflib_SObjectDomain construct( List<SObject> sObjectList ){
            return new AccountsDomain( sObjectList );
        }

        public fflib_SObjectDomain construct( List<SObject> sObjectList, SObjectType sObjectType ){
            return new AccountsDomain( sObjectList, sObjectType );
        }
    }

    public class OpportunitiesDomain extends fflib_SObjectDomain{
        public OpportunitiesDomain( List<Opportunity> sObjectList ){
            super( sObjectList );
        }

        public OpportunitiesDomain( List<SObject> sObjectList, SObjectType sObjectType ){
            super( sObjectList, sObjectType );
        }
    }

    public class OpportunitiesConstructor implements fflib_SObjectDomain.IConstructable2{
        public fflib_SObjectDomain construct( List<SObject> sObjectList ){
            return new OpportunitiesDomain( sObjectList );
        }

        public fflib_SObjectDomain construct( List<SObject> sObjectList, SObjectType sObjectType ){
            return new OpportunitiesDomain( sObjectList, sObjectType );
        }
    }

    public class ContactsDomain extends fflib_SObjectDomain{
        public ContactsDomain( List<Opportunity> sObjectList ){
            super( sObjectList );
        }

        public ContactsDomain( List<SObject> sObjectList, SObjectType sObjectType ){
            super( sObjectList, sObjectType );
        }
    }

    // Intentionally does not support IConstructable or IConstructable2 interfaces in order to support testing
    public class ContactsConstructor{}

    public class OpportunitiesSelector extends fflib_SObjectSelector{
        public override List<Schema.SObjectField> getSObjectFieldList(){
            return new List<Schema.SObjectField>{
                Opportunity.Name,
                Opportunity.Id
            };
        }

        public override Schema.SObjectType getSObjectType(){
            return Opportunity.SObjectType;
        }
    }

    public class AccountsSelector extends fflib_SObjectSelector{
        public override List<Schema.SObjectField> getSObjectFieldList(){
            return new List<Schema.SObjectField>{
                Account.Name,
                Account.Id,
                Account.AccountNumber,
                Account.AnnualRevenue
            };
        }

        public override Schema.SObjectType getSObjectType(){
            return Account.SObjectType;
        }
    }

    public interface IContactService{}
    public interface IOpportunitiesService{}
    public interface IAccountService{}

    public class OpportunitiesServiceImpl implements IOpportunitiesService{}
    public class AccountsServiceImpl implements IAccountService{}
    public class AccountsServiceMock implements IAccountService{}
}