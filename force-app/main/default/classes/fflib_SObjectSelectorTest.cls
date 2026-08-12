/**
 * Copyright (c), FinancialForce.com, inc
 * Copyright (c), Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
@IsTest( IsParallel = true )
private with sharing class fflib_SObjectSelectorTest{
    private static final List<Account> testAccounts = new List<Account>{
        new Account( Name = 'TestAccount1', AccountNumber = 'A1', AnnualRevenue = 76543.21 ),
        new Account( Name = 'TestAccount2', AccountNumber = 'A2', AnnualRevenue = 12345.67 )
    };

    @IsTest
    private static void getSObjectName(){
        // When - perform test
        Testfflib_SObjectSelector selector = new Testfflib_SObjectSelector();

        // Then - validate
        System.Assert.isNull( selector.getSObjectFieldSetList() );
        System.Assert.areEqual( 'Account', selector.getSObjectName() );
    }

    @IsTest
    private static void selectSObjectsById(){
        // Create mocks
        Testfflib_SObjectSelector selector = new Testfflib_SObjectSelector();
        fflib_ApexMocks mocks = selector.mockExecuteQuery();

        // When - perform test
        Set<Id> idSet = new Set<Id>();
        selector.selectSObjectsById( idSet );

        // Then - validate
        selector.verifyQueryAndBindVariableKeys( mocks )
            .validateTable( Account.SObjectType )
            .validateFields( new Set<String>{ 'Name', 'AnnualRevenue' } )
            .validateBindVariableValue( 'idSet', idSet );
    }

    @IsTest
    private static void selectAllSObjectRecords(){
        // Create mocks
        Testfflib_SObjectSelector selector = new Testfflib_SObjectSelector();
        fflib_ApexMocks mocks = selector.mockExecuteQuery();

        // When - perform test
        selector.selectAllSObjectRecords();

        // Then - validate
        selector.verifyQuery( mocks )
            .validateTable( Account.SObjectType )
            .validateFields( new Set<SObjectField>{ Account.Id } )
            .validateCondition( null );
    }

    @IsTest
    private static void queryLocatorById(){
        // Create mocks
        Testfflib_SObjectSelector selector = new Testfflib_SObjectSelector();
        fflib_ApexMocks mocks = selector.mockExecuteQuery();

        // Given - create data
        Set<Id> idSet = new Set<Id>{ fflib_IDGenerator.generate( Account.SObjectType ) };

        // When - perform test
        selector.queryLocatorById( idSet );

        // Then - validate
        selector.verifyQueryLocatorAndBindVariableKeys( mocks )
            .validateCondition( 'Id in :id', true );
    }

    @IsTest
    private static void selectDeleteBatchRecords_shouldRetrieveRecordsForDeletionCorrectly(){
        // Create mocks
        Testfflib_SObjectSelector selector = new Testfflib_SObjectSelector();
        fflib_ApexMocks mocks = selector.mockExecuteQuery();

        // Given - create data
        String conditionExpression = 'AnnualRevenue >= 60000';

        // When - perform test
        selector.selectDeleteBatchRecords( conditionExpression.replace( '\\', '' ) );

        // Then - validate
        selector.verifyQueryLocator( mocks )
            .validateCondition( conditionExpression, false );
    }

    @IsTest
    private static void testAssertIsAccessible(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_Database_IQuery mockSelectorQueryProxy = ( fflib_Database_IQuery ) mocks.mock( fflib_Database_IQuery.class );
        Testfflib_SObjectSelector selector = new Testfflib_SObjectSelector( false, true, false );
        MockQueryFactory mockQueryFactory = new MockQueryFactory();

        // Given - create data
        Set<Id> idSet = new Set<Id>{ fflib_IDGenerator.generate( Account.SObjectType ) };
        String conditionExpression = 'id in :idSet';
        Map<String, Object> bindVariablesMap = new Map<String, Object>{ 'idSet' => idSet };
        AccessLevel accessLevel = fflib_Database.getAccessLevel( selector.getContext() );

        // Set mocks
        mocks.startStubbing();
        mocks.when( mockSelectorQueryProxy.query( conditionExpression, bindVariablesMap, accessLevel ) ).thenReturn( testAccounts );
        mocks.stopStubbing();
        // Injecting the query proxy mock
        selector.m_queryProxy = mockSelectorQueryProxy;

        // When, Then
        try{
            selector.configureQueryFactory( mockQueryFactory, true, false, false, false );
            System.Assert.fail( 'Expected access denied exception. This assertion should never be triggered' );
        } catch( fflib_SObjectDomain.DomainException e ){
            System.Assert.areEqual( 'Permission to access an Account denied.', e.getMessage() );
            ( ( fflib_Database_IQuery ) mocks.verify( mockSelectorQueryProxy, 0 ) ).query( conditionExpression, bindVariablesMap, accessLevel );
        }
    }

    @IsTest
    private static void testCRUDOff(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_Database_IQuery mockSelectorQueryProxy = ( fflib_Database_IQuery ) mocks.mock( fflib_Database_IQuery.class );
        Testfflib_SObjectSelector selector = new Testfflib_SObjectSelector( false, false, false, true );

        // Given - create data
        Set<Id> idSet = new Set<Id>{ fflib_IDGenerator.generate( Account.SObjectType ) };
        Map<String, Object> bindVariablesMap = new Map<String, Object>{ 'idSet' => idSet };
        fflib_QueryFactory queryFactory = selector.newQueryFactory();
        queryFactory.setCondition( 'Id in :idSet' );
        String formattedSOQLExpression = queryFactory.toSOQL();
        AccessLevel accessLevel = fflib_Database.getAccessLevel( selector.getContext() );

        // Set mocks
        mocks.startStubbing();
        mocks.when( mockSelectorQueryProxy.query( formattedSOQLExpression, bindVariablesMap, accessLevel ) ).thenReturn( testAccounts );
        mocks.stopStubbing();
        // Injecting the query proxy mock
        selector.m_queryProxy = mockSelectorQueryProxy;

        // When, Then
        selector.selectSObjectsById( idSet );
        ( ( fflib_Database_IQuery ) mocks.verify( mockSelectorQueryProxy, 1 ) ).query( formattedSOQLExpression, bindVariablesMap, accessLevel );
    }

    @IsTest
    private static void testSOQL(){
        // Given - create data
        Testfflib_SObjectSelector selector = new Testfflib_SObjectSelector();

        // When - perform test
        String soql = selector.newQueryFactory().toSOQL();
        Pattern p = Pattern.compile( 'SELECT (.*) FROM Account ORDER BY Name DESC NULLS FIRST , AnnualRevenue ASC NULLS FIRST ' );
        Matcher m = p.matcher( soql );

        // Then - validate
        System.Assert.isTrue( m.matches(), 'Generated SOQL does not match expected pattern. Here is the generated SOQL: ' + soql );
        System.Assert.areEqual( 1, m.groupCount(), 'Unexpected number of groups captured.' );
        String fieldListString = m.group( 1 );
        assertFieldListString( fieldListString, null );
    }

    @IsTest
    private static void testDefaultConfig(){
        // Given, When
        Testfflib_SObjectSelector selector = new Testfflib_SObjectSelector();

        // Then - validate
        System.Assert.isNull( selector.isEnforcingFLS() );
        System.Assert.isNull( selector.isEnforcingCRUD() );
        System.Assert.isFalse( selector.isIncludeFieldSetFields() );
        System.Assert.isFalse( selector.isIncludeRelatedFieldSetFields() );
        System.Assert.isFalse( selector.isSortingSelectedFields() );
        System.Assert.areEqual( fflib_Database.Context.FULL, selector.getContext() );

        System.Assert.areEqual( 'Account', selector.getSObjectName() );
        System.Assert.areEqual( Account.SObjectType, selector.getSObjectType2() );
        System.Assert.areEqual( Account.SObjectType, selector.sObjectType() );
    }

    @IsTest
    private static void testDefault_setDataAccess(){
        // Given, When - Selector with no Context set by default, does allow DataAccess (and thus Context) to be set
        Testfflib_SObjectSelector selector = new Testfflib_SObjectSelector( true );
        selector.setDataAccess( fflib_SObjectSelector.DataAccess.SYSTEM_MODE );

        // Then - validate
        System.Assert.isFalse( selector.isEnforcingFLS(), 'Expected enforceFLS to be set to false based on legacy open-source logic' );
        System.Assert.isFalse( selector.isEnforcingCRUD(), 'Expected enforceCRUD to be set to false based on legacy open-source logic' );
        System.Assert.isTrue( selector.isIncludeFieldSetFields(), 'Expected fields to be included as passed via constructor' );
        System.Assert.isFalse( selector.isIncludeRelatedFieldSetFields() );
        System.Assert.isFalse( selector.isSortingSelectedFields() );
        System.Assert.areEqual( fflib_Database.Context.NONE, selector.getContext() );
    }

    @IsTest
    private static void setters_shouldSetParametersCorrectly(){
        // Given - create data
        Testfflib_SObjectSelector selector = new Testfflib_SObjectSelector();

        // When - perform test
        selector.enforceFLS();
        selector.ignoreCRUD();
        selector.includeFieldSetFields();
        selector.includeRelatedFieldSetFields();
        selector.unsortedSelectFields();

        // Then - validate
        System.Assert.isTrue( selector.isEnforcingFLS() );
        System.Assert.isFalse( selector.isEnforcingCRUD() );
        System.Assert.isTrue( selector.isIncludeFieldSetFields() );
        System.Assert.isTrue( selector.isIncludeRelatedFieldSetFields() );
        System.Assert.isFalse( selector.isSortingSelectedFields() );

        System.Assert.areEqual( 'Account', selector.getSObjectName() );
        System.Assert.areEqual( Account.SObjectType, selector.getSObjectType2() );
        System.Assert.areEqual( Account.SObjectType, selector.sObjectType() );
    }

    @IsTest
    private static void constructor_shouldSetIncludeFieldSetFields(){
        // Given, When
        Testfflib_SObjectSelector selector = new Testfflib_SObjectSelector( true );

        // Then - validate
        System.Assert.isNull( selector.isEnforcingFLS() );
        System.Assert.isNull( selector.isEnforcingCRUD() );
        System.Assert.isTrue( selector.isIncludeFieldSetFields() );
        System.Assert.isFalse( selector.isIncludeRelatedFieldSetFields() );
        System.Assert.isFalse( selector.isSortingSelectedFields() );
        System.Assert.areEqual( fflib_Database.Context.INHERIT, selector.getContext() );
        System.Assert.isInstanceOfType( selector.m_queryProxy, fflib_Database_QueryProxy.QueryInheritedSharing.class );
    }

    @IsTest
    private static void constructor_shouldSetIncludeFieldSetFieldsAndDataAccess(){
        // Given, When
        Testfflib_SObjectSelector selector = new Testfflib_SObjectSelector( true, fflib_SObjectSelector.DataAccess.LEGACY );

        // Then - validate
        System.Assert.isNull( selector.isEnforcingFLS() );
        System.Assert.isNull( selector.isEnforcingCRUD() );
        System.Assert.isTrue( selector.isIncludeFieldSetFields() );
        System.Assert.isFalse( selector.isIncludeRelatedFieldSetFields() );
        System.Assert.isFalse( selector.isSortingSelectedFields() );
        System.Assert.areEqual( fflib_Database.Context.INHERIT, selector.getContext() );
        System.Assert.isInstanceOfType( selector.m_queryProxy, fflib_Database_QueryProxy.QueryInheritedSharing.class );
    }

    @IsTest
    private static void constructor_shouldSetIncludeFieldSetFieldsAndSecurityContext(){
        // Given, When
        Testfflib_SObjectSelector selector = new Testfflib_SObjectSelector( true, fflib_Database.Context.SHARING_SKIP_PERMISSIONS );

        // Then - validate
        System.Assert.isNull( selector.isEnforcingFLS() );
        System.Assert.isNull( selector.isEnforcingCRUD() );
        System.Assert.isTrue( selector.isIncludeFieldSetFields() );
        System.Assert.isFalse( selector.isIncludeRelatedFieldSetFields() );
        System.Assert.isFalse( selector.isSortingSelectedFields() );
        System.Assert.areEqual( fflib_Database.Context.SHARING_SKIP_PERMISSIONS, selector.getContext() );
        System.Assert.isInstanceOfType( selector.m_queryProxy, fflib_Database_QueryProxy.QueryWithSharing.class );
    }

    @IsTest
    private static void constructor_shouldSetIncludeFieldSetFieldsSortAndSecurityContext(){
        // Given, When
        Testfflib_SObjectSelector selector = new Testfflib_SObjectSelector( true, true, fflib_Database.Context.NONE );

        // Then - validate
        System.Assert.isNull( selector.isEnforcingFLS() );
        System.Assert.isNull( selector.isEnforcingCRUD() );
        System.Assert.isTrue( selector.isIncludeFieldSetFields() );
        System.Assert.isFalse( selector.isIncludeRelatedFieldSetFields() );
        System.Assert.isTrue( selector.isSortingSelectedFields() );
        System.Assert.areEqual( fflib_Database.Context.NONE, selector.getContext() );
        System.Assert.isInstanceOfType( selector.m_queryProxy, fflib_Database_QueryProxy.QueryWithoutSharing.class );
    }

    @IsTest
    private static void constructor_shouldSetIncludeFieldSetFieldsCrudAndFls(){
        // Given, When
        Testfflib_SObjectSelector selector = new Testfflib_SObjectSelector( true, false, true );

        // Then - validate
        System.Assert.isTrue( selector.isEnforcingFLS() );
        System.Assert.isFalse( selector.isEnforcingCRUD() );
        System.Assert.isTrue( selector.isIncludeFieldSetFields() );
        System.Assert.isFalse( selector.isIncludeRelatedFieldSetFields() );
        System.Assert.isFalse( selector.isSortingSelectedFields() );
        System.Assert.areEqual( fflib_Database.Context.INHERIT, selector.getContext() );
        System.Assert.isInstanceOfType( selector.m_queryProxy, fflib_Database_QueryProxy.QueryInheritedSharing.class );
    }

    @IsTest
    private static void constructor_shouldSetIncludeFieldSetFieldsRelatedAndSecurityContext(){
        // Given, When
        Testfflib_SObjectSelector selector = new Testfflib_SObjectSelector( true, false, true, fflib_Database.Context.NONE );

        // Then - validate
        System.Assert.isNull( selector.isEnforcingFLS() );
        System.Assert.isNull( selector.isEnforcingCRUD() );
        System.Assert.isTrue( selector.isIncludeFieldSetFields() );
        System.Assert.isTrue( selector.isIncludeRelatedFieldSetFields() );
        System.Assert.isFalse( selector.isSortingSelectedFields() );
        System.Assert.areEqual( fflib_Database.Context.NONE, selector.getContext() );
        System.Assert.isInstanceOfType( selector.m_queryProxy, fflib_Database_QueryProxy.QueryWithoutSharing.class );
    }

    private static void assertFieldListString( String fieldListString, String prefix ){
        String prefixString = ( !String.isBlank( prefix ) ) ? prefix + '.' : '';
        List<String> fieldList = fieldListString.split( ',{1}\\s?' );
        System.Assert.areEqual( UserInfo.isMultiCurrencyOrganization() ? 5 : 4, fieldList.size() );
        Set<String> fieldSet = new Set<String>();
        fieldSet.addAll( fieldList );
        String expected = prefixString + 'AccountNumber';
        System.Assert.isTrue( fieldSet.contains( expected.toLowerCase() ), expected + ' missing from field list string: ' + fieldListString );
        expected = prefixString + 'AnnualRevenue';
        System.Assert.isTrue( fieldSet.contains( expected.toLowerCase() ), expected + ' missing from field list string: ' + fieldListString );
        expected = prefixString + 'Id';
        System.Assert.isTrue( fieldSet.contains( expected.toLowerCase() ), expected + ' missing from field list string: ' + fieldListString );
        expected = prefixString + 'Name';
        System.Assert.isTrue( fieldSet.contains( expected.toLowerCase() ), expected + ' missing from field list string: ' + fieldListString );
        if( UserInfo.isMultiCurrencyOrganization() ){
            expected = prefixString + 'CurrencyIsoCode';
            System.Assert.isTrue( fieldSet.contains( expected.toLowerCase() ), expected + ' missing from field list string: ' + fieldListString );
        }
    }

    @IsTest
    private static void testWithoutSorting(){
        // Given - create data
        Testfflib_SObjectSelector selector = new Testfflib_SObjectSelector( false, false, false, false );
        fflib_QueryFactory qf = selector.newQueryFactory( true );

        Set<String> expectedSelectFields = new Set<String>{
            'Name',
            'Id',
            'AccountNumber',
            'AnnualRevenue'
        };
        if( UserInfo.isMultiCurrencyOrganization() ){
            expectedSelectFields.add( 'CurrencyIsoCode' );
        }

        // When - perform test
        String soql = qf.toSOQL();

        // Then - validate
        Pattern soqlPattern = Pattern.compile( 'SELECT (.*) FROM Account ORDER BY Name DESC NULLS FIRST , AnnualRevenue ASC NULLS FIRST ' );
        Matcher soqlMatcher = soqlPattern.matcher( soql );
        soqlMatcher.matches();

        List<String> actualSelectFields = soqlMatcher.group( 1 ).deleteWhitespace().split( ',' );
        System.Assert.areEqual( expectedSelectFields, new Set<String>( actualSelectFields ) );
    }

    @IsTest
    private static void getOrderBy(){
        // Given/When - Account has Name field thus should return Name
        TestAccountSObjectSelector_WithoutOrderBy selector = new TestAccountSObjectSelector_WithoutOrderBy();
        System.Assert.areEqual( 'Name', selector.getOrderBy(), 'Expected Name, since available on Account' );

        // Given/When - AccountHistory has no Name field, but a CreatedDate, thus should return CreatedDate
        TestSObjectSelector_AccountHistory selectorNoName = new TestSObjectSelector_AccountHistory();
        System.Assert.areEqual( 'CreatedDate', selectorNoName.getOrderBy(), 'Expected CreatedDate, since no Name available on AccountHistory' );

        // Given/When - Unfortunately no standard Object exists with no Name, nor CreatedDate but with Id
        TestSObjectSelector_GroupMember selectorNoNameNoCreatedDate = new TestSObjectSelector_GroupMember();
        System.Assert.areEqual( 'Id', selectorNoNameNoCreatedDate.getOrderBy(), 'Expected Id, since no Name nor CreatedDate is available on GroupMember' );
    }

    @IsTest
    private static void newQueryFactory_queryFactoryExcludesRelatedFieldSet(){
        // Given - create data
        Testfflib_SObjectSelector selector = new Testfflib_SObjectSelector( false, false, false, false, true );
        fflib_QueryFactory queryFactory = selector.newQueryFactory( true, false, true, false );

        Set<String> expectedSelectFields = new Set<String>{
            'Name',
            'Id',
            'AccountNumber',
            'AnnualRevenue'
        };
        if( UserInfo.isMultiCurrencyOrganization() ){
            expectedSelectFields.add( 'CurrencyIsoCode' );
        }

        // When - perform test
        String soql = queryFactory.toSOQL();

        // Then - validate
        Pattern soqlPattern = Pattern.compile( 'SELECT (.*) FROM Account ORDER BY Name DESC NULLS FIRST , AnnualRevenue ASC NULLS FIRST ' );
        Matcher soqlMatcher = soqlPattern.matcher( soql );
        soqlMatcher.matches();

        List<String> actualSelectFields = soqlMatcher.group( 1 ).deleteWhitespace().split( ',' );
        System.Assert.areEqual( expectedSelectFields, new Set<String>( actualSelectFields ) );
    }

    @IsTest
    private static void newQueryFactory_sObjectSelectorIncludesRelatedFieldSet(){
        // Given - create data
        Testfflib_SObjectSelector selector = new Testfflib_SObjectSelector( false, false, false, false, true );
        fflib_QueryFactory queryFactory = selector.newQueryFactory( true, false, false );

        Set<String> expectedSelectFields = new Set<String>{
            'Parent.BillingAddress',
            'Parent.ShippingAddress'
        };
        if( UserInfo.isMultiCurrencyOrganization() ){
            expectedSelectFields.add( 'CurrencyIsoCode' );
        }

        // When - perform test
        String soql = queryFactory.toSOQL();

        // Then - validate
        Pattern soqlPattern = Pattern.compile( 'SELECT (.*) FROM Account ORDER BY Name DESC NULLS FIRST , AnnualRevenue ASC NULLS FIRST ' );
        Matcher soqlMatcher = soqlPattern.matcher( soql );
        soqlMatcher.matches();

        List<String> actualSelectFields = soqlMatcher.group( 1 ).deleteWhitespace().split( ',' );
        System.Assert.areEqual( expectedSelectFields, new Set<String>( actualSelectFields ) );
    }

    @IsTest
    private static void shouldAddQueryFactorySubselect(){
        // Given - create data
        Testfflib_SObjectSelector selector = new Testfflib_SObjectSelector( false, false, false, false );
        fflib_QueryFactory query = selector.newQueryFactory( true );

        // When - perform test
        new Testfflib_SObjectSelector().addQueryFactorySubselect( query );

        // Then - validate
        String constructedQuery = query.toSOQL();
        System.Assert.areEqual( 2, constructedQuery.countMatches( 'SELECT' ), 'Expected 2x SELECT because of subselect ' + constructedQuery );
        System.Assert.areEqual( 2, constructedQuery.countMatches( 'FROM' ), 'Expected 2x FROM because of subselect ' + constructedQuery );
        System.Assert.areEqual( 1, constructedQuery.countMatches( 'ChildAccounts' ) + constructedQuery.countMatches( '__r' ), 'Expected std Account Parent Relation or custom Child Relation in query ' + constructedQuery );
    }

    @IsTest
    private static void shouldAddQueryFactorySubselectNoAccessChecks(){
        // Given - create data
        Testfflib_SObjectSelector selector = new Testfflib_SObjectSelector( false, false, false, false );
        fflib_QueryFactory query = selector.newQueryFactory( true );

        // When - perform test
        new Testfflib_SObjectSelector().addQueryFactorySubselectNoAccess( query );

        // Then - validate
        String constructedQuery = query.toSOQL();
        System.Assert.areEqual( 2, constructedQuery.countMatches( 'SELECT' ), 'Expected 2x SELECT because of subselect ' + constructedQuery );
        System.Assert.areEqual( 2, constructedQuery.countMatches( 'FROM' ), 'Expected 2x FROM because of subselect ' + constructedQuery );
        System.Assert.areEqual( 1, constructedQuery.countMatches( 'ChildAccounts' ) + constructedQuery.countMatches( '__r' ), 'Expected std Account Parent Relation or custom Child Relation in query ' + constructedQuery );
    }

    @IsTest
    private static void shouldAddQueryFactorySubselectByRelationshipName(){
        // Given - create data
        Testfflib_SObjectSelector selector = new Testfflib_SObjectSelector( false, false, false, false );
        fflib_QueryFactory query = selector.newQueryFactory( true );

        // When - perform test
        new Testfflib_SObjectSelector().addQueryFactorySubselect( query, 'ChildAccounts' );

        // Then - validate
        System.Assert.areEqual( 2, query.toSOQL().countMatches( 'SELECT' ) );
        System.Assert.areEqual( 2, query.toSOQL().countMatches( 'FROM' ) );
        System.Assert.areEqual( 1, query.toSOQL().countMatches( 'ChildAccounts' ) );
    }

    @IsTest
    private static void shouldAddQueryFactorySubselectByRelationshipNameNoAccessChecks(){
        // Given - create data
        Testfflib_SObjectSelector selector = new Testfflib_SObjectSelector( false, false, false, false );
        fflib_QueryFactory query = selector.newQueryFactory( true );

        // When - perform test
        new Testfflib_SObjectSelector().addQueryFactorySubselectNoAccessChecks( query, 'ChildAccounts', false );

        // Then - validate
        System.Assert.areEqual( 2, query.toSOQL().countMatches( 'SELECT' ) );
        System.Assert.areEqual( 2, query.toSOQL().countMatches( 'FROM' ) );
        System.Assert.areEqual( 1, query.toSOQL().countMatches( 'ChildAccounts' ) );
    }

    @IsTest
    private static void shouldConfigureQueryFactoryFieldsForRelatedObject(){
        // Given - create data
        Testfflib_SObjectSelector selector = new Testfflib_SObjectSelector( false, false, false, false );
        fflib_QueryFactory query = selector.newQueryFactory();

        // When - perform test
        selector.configureQueryFactoryFields( query, 'Parent' );

        // Then - validate
        System.Assert.isTrue( query.toSOQL().contains( 'Parent.Id' ) );
        System.Assert.isTrue( query.toSOQL().contains( 'Parent.Name' ) );
        System.Assert.isTrue( query.toSOQL().contains( 'Parent.AccountNumber' ) );
        System.Assert.isTrue( query.toSOQL().contains( 'Parent.Parent.ShippingAddress' ) );
        System.Assert.isTrue( query.toSOQL().contains( 'Parent.Parent.BillingAddress' ) );
    }

    @IsTest
    private static void shouldCorrectlyEnforceSecuritySettings(){
        // Given - create data
        Testfflib_SObjectSelector selector = new Testfflib_SObjectSelector( fflib_Database.Context.NONE );

        // When, Then
        System.Assert.isInstanceOfType( selector.m_queryProxy, fflib_Database_QueryProxy.QueryWithoutSharing.class );

        try{
            selector.setContext( fflib_Database.Context.FULL );
            System.Assert.fail( 'Expected InvalidContextAssignmentException to be thrown as Context can only be defined once' );
        } catch( fflib_SObjectSelector.InvalidContextAssignmentException ex ){
            String expectedMessage = 'Database security context can only be defined when constructing a new selector instance! Please provide a valid fflib_Database.Context when creating a new instance of a selector class.';
            // Then - validate
            System.Assert.areEqual( expectedMessage, ex.getMessage() );
        }

        try{
            selector.setDataAccess( fflib_SObjectSelector.DataAccess.USER_MODE );
            System.Assert.fail( 'Expected InvalidContextAssignmentException to be thrown as Context and DataAccess can only be defined once' );
        } catch( fflib_SObjectSelector.InvalidContextAssignmentException ex ){
            String expectedMessage = 'Database security context can only be defined when constructing a new selector instance! Please provide a valid fflib_Database.Context when creating a new instance of a selector class.';
            // Then - validate
            System.Assert.areEqual( expectedMessage, ex.getMessage() );
        }

        selector = new Testfflib_SObjectSelector( fflib_Database.Context.FULL );
        System.Assert.isInstanceOfType( selector.m_queryProxy, fflib_Database_QueryProxy.QueryWithSharing.class );

        selector = new Testfflib_SObjectSelector( fflib_Database.Context.SHARING_SKIP_PERMISSIONS );
        System.Assert.isInstanceOfType( selector.m_queryProxy, fflib_Database_QueryProxy.QueryWithSharing.class );

        selector = new Testfflib_SObjectSelector( fflib_Database.Context.INHERIT );
        System.Assert.isInstanceOfType( selector.m_queryProxy, fflib_Database_QueryProxy.QueryInheritedSharing.class );
    }

    @IsTest
    private static void executeQuery(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_Database_IQuery queryProxyMock = ( fflib_Database_IQuery ) mocks.mock( fflib_Database_IQuery.class );

        // Given - create data
        Testfflib_SObjectSelector selector = new Testfflib_SObjectSelector();
        List<Account> mockedAccounts = new List<Account>{ new Account( Name = 'TestAccount1' ) };
        fflib_QueryFactory testQueryFactory = selector.newQueryFactory();
        String testQueryFactoryExpression = testQueryFactory.toSOQL();
        AccessLevel accessLevel = fflib_Database.getAccessLevel( selector.getContext() );

        // Set mocks
        mocks.startStubbing();
        mocks.when( queryProxyMock.query( testQueryFactoryExpression, accessLevel ) ).thenReturn( mockedAccounts );
        mocks.stopStubbing();
        // Injecting the query proxy mock
        selector.m_queryProxy = queryProxyMock;

        // When - perform test
        List<Account> resultAccounts = selector.executeQuery( testQueryFactory );

        // Then - validate
        fflib_ArgumentCaptor argumentCaptor = fflib_ArgumentCaptor.forClass( fflib_QueryFactory.class );
        ( ( fflib_Database_IQuery ) mocks.verify( queryProxyMock, 1 ) ).query( ( String ) argumentCaptor.capture(), ( AccessLevel ) fflib_Match.eq( accessLevel ) );
        System.Assert.areEqual( mockedAccounts, resultAccounts );
        String capturedQueryFactory = ( String ) argumentCaptor.getValue();
        System.Assert.areEqual( testQueryFactoryExpression, capturedQueryFactory );
    }

    @IsTest
    private static void executeQueryWithBindVariables(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_Database_IQuery queryProxyMock = ( fflib_Database_IQuery ) mocks.mock( fflib_Database_IQuery.class );

        // Given - create data
        Testfflib_SObjectSelector selector = new Testfflib_SObjectSelector();
        List<Account> mockedAccounts = new List<Account>{ new Account( Name = 'TestAccount1' ) };
        fflib_QueryFactory testQueryFactory = selector.newQueryFactory();
        testQueryFactory.setCondition( 'Id in :mockedAccountIds' );
        String testQueryFactoryExpression = testQueryFactory.toSOQL();

        Set<Id> mockedAccountIds = new Set<Id>{ mockedAccounts[ 0 ].Id };
        Map<String, Object> bindVariablesMap = new Map<String, Object>{ 'mockedAccountIds' => mockedAccountIds };
        AccessLevel accessLevel = fflib_Database.getAccessLevel( selector.getContext() );

        // Set mocks
        mocks.startStubbing();
        mocks.when( queryProxyMock.query( testQueryFactoryExpression, bindVariablesMap, accessLevel ) ).thenReturn( mockedAccounts );
        mocks.stopStubbing();
        // Injecting the query proxy mock
        selector.m_queryProxy = queryProxyMock;

        // When - perform test
        List<Account> resultAccounts = selector.executeQuery( testQueryFactory, bindVariablesMap );

        // Then - validate
        fflib_ArgumentCaptor argumentCaptor = fflib_ArgumentCaptor.forClass( fflib_QueryFactory.class );
        ( ( fflib_Database_IQuery ) mocks.verify( queryProxyMock, 1 ) )
            .query( ( String ) argumentCaptor.capture(), ( Map<String, Object> ) argumentCaptor.capture(), ( AccessLevel ) fflib_Match.eq( accessLevel ) );
        List<Object> capturedArguments = argumentCaptor.getAllValues();
        String capturedQueryFactory = ( String ) capturedArguments[ 0 ];
        Map<String, Object> capturedBindingMap = ( Map<String, Object> ) capturedArguments[ 1 ];
        System.Assert.areEqual( mockedAccounts, resultAccounts );
        System.Assert.areEqual( testQueryFactoryExpression, capturedQueryFactory );
        System.Assert.areEqual( bindVariablesMap, capturedBindingMap );
    }

    @IsTest
    private static void executeAggregateQuery(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_Database_IQuery queryProxyMock = ( fflib_Database_IQuery ) mocks.mock( fflib_Database_IQuery.class );

        // Given - create data
        Testfflib_SObjectSelector selector = new Testfflib_SObjectSelector();
        fflib_QueryFactory testQueryFactory = selector.newQueryFactory().setGroupByFieldName( 'Industry' );
        String mockedSOQLString = testQueryFactory.toSOQL();
        AccessLevel mockedAccessLevel = fflib_Database.getAccessLevel( selector.getContext() );
        List<AggregateResult> mockedResults = new List<AggregateResult>();

        // Set mocks
        mocks.startStubbing();
        mocks.when( queryProxyMock.query( mockedSOQLString, mockedAccessLevel ) )
            .thenReturn( mockedResults );
        mocks.stopStubbing();
        // Injecting the query proxy mock
        selector.m_queryProxy = queryProxyMock;

        // When - perform test
        List<fflib_AggregateResult> aggrResults = selector.executeAggregateQuery( testQueryFactory );

        // Then - validate
        fflib_ArgumentCaptor argumentCaptor = fflib_ArgumentCaptor.forClass( fflib_QueryFactory.class );
        ( ( fflib_Database_IQuery ) mocks.verify( queryProxyMock, 1 ) ).query( ( String ) argumentCaptor.capture(), ( AccessLevel ) fflib_Match.eq( mockedAccessLevel ) );
        System.Assert.areEqual( fflib_AggregateResult.construct( mockedResults ), aggrResults, 'Expected the AggregateResult to be converted to fflib_AggregateResult' );
        String capturedQueryFactory = ( String ) argumentCaptor.getValue();
        System.Assert.areEqual( mockedSOQLString, capturedQueryFactory );
    }

    @IsTest
    private static void executeAggregateQueryWithBindVariables(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_Database_IQuery queryProxyMock = ( fflib_Database_IQuery ) mocks.mock( fflib_Database_IQuery.class );

        // Given - create data
        Testfflib_SObjectSelector selector = new Testfflib_SObjectSelector();
        fflib_QueryFactory testQueryFactory = selector.newQueryFactory()
            .setCondition( 'Id IN :accountIds' )
            .setGroupByFieldName( 'Industry' );
        String mockedSOQLString = testQueryFactory.toSOQL();
        AccessLevel mockedAccessLevel = fflib_Database.getAccessLevel( selector.getContext() );
        List<AggregateResult> mockedResults = new List<AggregateResult>();

        Map<String, Object> bindVariablesMap = new Map<String, Object>{ 'accountIds' => new Set<Id>() };
        AccessLevel accessLevel = fflib_Database.getAccessLevel( selector.getContext() );

        // Set mocks
        mocks.startStubbing();
        mocks.when( queryProxyMock.query( mockedSOQLString, bindVariablesMap, mockedAccessLevel ) ).thenReturn( mockedResults );
        mocks.stopStubbing();
        // Injecting the query proxy mock
        selector.m_queryProxy = queryProxyMock;

        // When - perform test
        List<fflib_AggregateResult> aggrResults = selector.executeAggregateQuery( testQueryFactory, bindVariablesMap );

        // Then - validate
        fflib_ArgumentCaptor argumentCaptor = fflib_ArgumentCaptor.forClass( fflib_QueryFactory.class );
        ( ( fflib_Database_IQuery ) mocks.verify( queryProxyMock, 1 ) )
            .query( ( String ) argumentCaptor.capture(), ( Map<String, Object> ) argumentCaptor.capture(), ( AccessLevel ) fflib_Match.eq( mockedAccessLevel ) );
        List<Object> capturedArguments = argumentCaptor.getAllValues();
        String capturedQueryFactory = ( String ) capturedArguments[ 0 ];
        Map<String, Object> capturedBindingMap = ( Map<String, Object> ) capturedArguments[ 1 ];
        System.Assert.areEqual( fflib_AggregateResult.construct( mockedResults ), aggrResults, 'Expected the AggregateResult to be converted to fflib_AggregateResult' );
        System.Assert.areEqual( mockedSOQLString, capturedQueryFactory );
        System.Assert.areEqual( bindVariablesMap, capturedBindingMap );
    }

    @IsTest
    private static void getQueryLocator(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_Database_IQuery queryProxyMock = ( fflib_Database_IQuery ) mocks.mock( fflib_Database_IQuery.class );

        // Given - create data
        Testfflib_SObjectSelector selector = new Testfflib_SObjectSelector();
        fflib_QueryFactory testQueryFactory = selector.newQueryFactory();
        String testQueryFactoryExpression = testQueryFactory.toSOQL();
        AccessLevel accessLevel = fflib_Database.getAccessLevel( selector.getContext() );

        // Set mocks
        mocks.startStubbing();
        mocks.when( queryProxyMock.getQueryLocator( testQueryFactoryExpression, accessLevel ) ).thenReturn( null );
        mocks.stopStubbing();
        // Injecting the query proxy mock
        selector.m_queryProxy = queryProxyMock;

        // When - perform test
        selector.getQueryLocator( testQueryFactory );

        // Then - validate
        fflib_ArgumentCaptor argumentCaptor = fflib_ArgumentCaptor.forClass( fflib_QueryFactory.class );
        ( ( fflib_Database_IQuery ) mocks.verify( queryProxyMock, 1 ) ).getQueryLocator( ( String ) argumentCaptor.capture(), ( AccessLevel ) fflib_Match.eq( accessLevel ) );
        String capturedQueryFactory = ( String ) argumentCaptor.getValue();
        System.Assert.areEqual( testQueryFactoryExpression, capturedQueryFactory );
    }

    @IsTest
    private static void getQueryLocatorWithBindVariables(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_Database_IQuery queryProxyMock = ( fflib_Database_IQuery ) mocks.mock( fflib_Database_IQuery.class );

        // Given - create data
        Testfflib_SObjectSelector selector = new Testfflib_SObjectSelector();
        fflib_QueryFactory testQueryFactory = selector.newQueryFactory();
        testQueryFactory.setCondition( 'Id in :mockedAccountIds' );
        String testQueryFactoryExpression = testQueryFactory.toSOQL();
        Set<Id> mockedAccountIds = new Set<Id>();
        Map<String, Object> bindVariablesMap = new Map<String, Object>{ 'mockedAccountIds' => mockedAccountIds };
        AccessLevel accessLevel = fflib_Database.getAccessLevel( selector.getContext() );

        // Set mocks
        mocks.startStubbing();
        mocks.when( queryProxyMock.getQueryLocator( testQueryFactoryExpression, bindVariablesMap, accessLevel ) ).thenReturn( null );
        mocks.stopStubbing();
        // Injecting the query proxy mock
        selector.m_queryProxy = queryProxyMock;

        // When - perform test
        selector.getQueryLocator( testQueryFactory, bindVariablesMap );

        // Then - validate
        fflib_ArgumentCaptor argumentCaptor = fflib_ArgumentCaptor.forClass( fflib_QueryFactory.class );
        ( ( fflib_Database_IQuery ) mocks.verify( queryProxyMock, 1 ) )
            .getQueryLocator( ( String ) argumentCaptor.capture(), ( Map<String, Object> ) argumentCaptor.capture(), ( AccessLevel ) fflib_Match.eq( accessLevel ) );
        List<Object> capturedArguments = argumentCaptor.getAllValues();
        String capturedQueryFactory = ( String ) capturedArguments[ 0 ];
        Map<String, Object> capturedBindingMap = ( Map<String, Object> ) capturedArguments[ 1 ];
        System.Assert.areEqual( testQueryFactoryExpression, capturedQueryFactory );
        System.Assert.areEqual( bindVariablesMap, capturedBindingMap );
    }

    @IsTest
    private static void mockExecuteAggregateQuery(){
        // Create mocks
        Testfflib_SObjectSelector selector = new Testfflib_SObjectSelector();
        fflib_ApexMocks mocks = selector.mockExecuteAggregateQuery();
        System.Assert.isInstanceOfType( mocks, fflib_ApexMocks.class, 'Expected initiated mocks' );
        System.Assert.areEqual( new List<AggregateResult>(), selector.m_queryProxy.query( 'soqlQuery', AccessLevel.USER_MODE ), 'Expected diff response due to execute-stub in mockExecuteAggregateQuery()' );
        System.Assert.areEqual( new List<AggregateResult>(), selector.m_queryProxy.query( 'soqlQuery', new Map<String, Object>(), AccessLevel.USER_MODE ), 'Expected diff response due to execute-bindVariables-stub in mockExecuteAggregateQuery()' );
    }

    @IsTest
    private static void getCursor(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_Database_IQuery queryProxyMock = ( fflib_Database_IQuery ) mocks.mock( fflib_Database_IQuery.class );

        // Given - create data
        Testfflib_SObjectSelector selector = new Testfflib_SObjectSelector();
        fflib_QueryFactory testQueryFactory = selector.newQueryFactory();
        String testQueryFactoryExpression = testQueryFactory.toSOQL();
        AccessLevel accessLevel = fflib_Database.getAccessLevel( selector.getContext() );

        // Set mocks
        mocks.startStubbing();
        mocks.when( queryProxyMock.getCursor( testQueryFactoryExpression, accessLevel ) ).thenReturn( null );
        mocks.stopStubbing();
        // Injecting the query proxy mock
        selector.m_queryProxy = queryProxyMock;

        // When - perform test
        selector.getCursor( testQueryFactory );

        // Then - validate
        fflib_ArgumentCaptor argumentCaptor = fflib_ArgumentCaptor.forClass( fflib_QueryFactory.class );
        ( ( fflib_Database_IQuery ) mocks.verify( queryProxyMock, 1 ) ).getCursor( ( String ) argumentCaptor.capture(), ( AccessLevel ) fflib_Match.eq( accessLevel ) );
        String capturedQueryFactory = ( String ) argumentCaptor.getValue();
        System.Assert.areEqual( testQueryFactoryExpression, capturedQueryFactory );
    }

    @IsTest
    private static void getCursorWithBindVariables(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_Database_IQuery queryProxyMock = ( fflib_Database_IQuery ) mocks.mock( fflib_Database_IQuery.class );

        // Given - create data
        Testfflib_SObjectSelector selector = new Testfflib_SObjectSelector();
        fflib_QueryFactory testQueryFactory = selector.newQueryFactory();
        testQueryFactory.setCondition( 'Id in :mockedAccountIds' );
        String testQueryFactoryExpression = testQueryFactory.toSOQL();
        Set<Id> mockedAccountIds = new Set<Id>();
        Map<String, Object> bindVariablesMap = new Map<String, Object>{ 'mockedAccountIds' => mockedAccountIds };
        AccessLevel accessLevel = fflib_Database.getAccessLevel( selector.getContext() );

        // Set mocks
        mocks.startStubbing();
        mocks.when( queryProxyMock.getCursor( testQueryFactoryExpression, bindVariablesMap, accessLevel ) ).thenReturn( null );
        mocks.stopStubbing();
        // Injecting the query proxy mock
        selector.m_queryProxy = queryProxyMock;

        // When - perform test
        selector.getCursor( testQueryFactory, bindVariablesMap );

        // Then - validate
        fflib_ArgumentCaptor argumentCaptor = fflib_ArgumentCaptor.forClass( fflib_QueryFactory.class );
        ( ( fflib_Database_IQuery ) mocks.verify( queryProxyMock, 1 ) )
            .getCursor( ( String ) argumentCaptor.capture(), ( Map<String, Object> ) argumentCaptor.capture(), ( AccessLevel ) fflib_Match.eq( accessLevel ) );
        List<Object> capturedArguments = argumentCaptor.getAllValues();
        System.Assert.areEqual( testQueryFactoryExpression, ( String ) capturedArguments[ 0 ] );
        System.Assert.areEqual( bindVariablesMap, ( Map<String, Object> ) capturedArguments[ 1 ] );
    }

    @IsTest
    private static void getPaginationCursor(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_Database_IQuery queryProxyMock = ( fflib_Database_IQuery ) mocks.mock( fflib_Database_IQuery.class );

        // Given - create data
        Testfflib_SObjectSelector selector = new Testfflib_SObjectSelector();
        fflib_QueryFactory testQueryFactory = selector.newQueryFactory();
        String testQueryFactoryExpression = testQueryFactory.toSOQL();
        AccessLevel accessLevel = fflib_Database.getAccessLevel( selector.getContext() );

        // Set mocks
        mocks.startStubbing();
        mocks.when( queryProxyMock.getPaginationCursor( testQueryFactoryExpression, accessLevel ) ).thenReturn( null );
        mocks.stopStubbing();
        // Injecting the query proxy mock
        selector.m_queryProxy = queryProxyMock;

        // When - perform test
        selector.getPaginationCursor( testQueryFactory );

        // Then - validate
        fflib_ArgumentCaptor argumentCaptor = fflib_ArgumentCaptor.forClass( fflib_QueryFactory.class );
        ( ( fflib_Database_IQuery ) mocks.verify( queryProxyMock, 1 ) ).getPaginationCursor( ( String ) argumentCaptor.capture(), ( AccessLevel ) fflib_Match.eq( accessLevel ) );
        String capturedQueryFactory = ( String ) argumentCaptor.getValue();
        System.Assert.areEqual( testQueryFactoryExpression, capturedQueryFactory );
    }

    @IsTest
    private static void getPaginationCursorWithBindVariables(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_Database_IQuery queryProxyMock = ( fflib_Database_IQuery ) mocks.mock( fflib_Database_IQuery.class );

        // Given - create data
        Testfflib_SObjectSelector selector = new Testfflib_SObjectSelector();
        fflib_QueryFactory testQueryFactory = selector.newQueryFactory();
        testQueryFactory.setCondition( 'Id in :mockedAccountIds' );
        String testQueryFactoryExpression = testQueryFactory.toSOQL();
        Set<Id> mockedAccountIds = new Set<Id>();
        Map<String, Object> bindVariablesMap = new Map<String, Object>{ 'mockedAccountIds' => mockedAccountIds };
        AccessLevel accessLevel = fflib_Database.getAccessLevel( selector.getContext() );

        // Set mocks
        mocks.startStubbing();
        mocks.when( queryProxyMock.getPaginationCursor( testQueryFactoryExpression, bindVariablesMap, accessLevel ) ).thenReturn( null );
        mocks.stopStubbing();
        // Injecting the query proxy mock
        selector.m_queryProxy = queryProxyMock;

        // When - perform test
        selector.getPaginationCursor( testQueryFactory, bindVariablesMap );

        // Then - validate
        fflib_ArgumentCaptor argumentCaptor = fflib_ArgumentCaptor.forClass( fflib_QueryFactory.class );
        ( ( fflib_Database_IQuery ) mocks.verify( queryProxyMock, 1 ) )
            .getPaginationCursor( ( String ) argumentCaptor.capture(), ( Map<String, Object> ) argumentCaptor.capture(), ( AccessLevel ) fflib_Match.eq( accessLevel ) );
        List<Object> capturedArguments = argumentCaptor.getAllValues();
        System.Assert.areEqual( testQueryFactoryExpression, ( String ) capturedArguments[ 0 ] );
        System.Assert.areEqual( bindVariablesMap, ( Map<String, Object> ) capturedArguments[ 1 ] );
    }

    @IsTest
    private static void getCursor_shouldThrowOnForUpdateQuery(){
        // Given - create data
        Testfflib_SObjectSelector selector = new Testfflib_SObjectSelector();
        fflib_QueryFactory qfWithForUpdate = selector.newQueryFactory().setForUpdate( true );

        // When, Then - FOR UPDATE is not supported by cursors
        try{
            selector.getCursor( qfWithForUpdate );
            System.Assert.fail( 'Expected InvalidCursorQueryException to be thrown for FOR UPDATE query' );
        } catch( fflib_SObjectSelector.InvalidCursorQueryException ex ){
            System.Assert.isTrue( ex.getMessage().contains( 'FOR UPDATE' ), 'Expected exception message to reference FOR UPDATE' );
        }

        // Also validate the raw String overload
        try{
            selector.getCursor( qfWithForUpdate.toSOQL() );
            System.Assert.fail( 'Expected InvalidCursorQueryException to be thrown for FOR UPDATE query string' );
        } catch( fflib_SObjectSelector.InvalidCursorQueryException ex ){
            System.Assert.isTrue( ex.getMessage().contains( 'FOR UPDATE' ), 'Expected exception message to reference FOR UPDATE' );
        }
    }

    @IsTest
    private static void getCursor_shouldThrowOnGroupByQuery(){
        // Given - create data
        Testfflib_SObjectSelector selector = new Testfflib_SObjectSelector();
        fflib_QueryFactory qfWithGroupBy = selector.newQueryFactory().setGroupByFieldName( 'Name' );

        // When, Then - GROUP BY via QueryFactory flag (caught before toSOQL())
        try{
            selector.getCursor( qfWithGroupBy );
            System.Assert.fail( 'Expected InvalidCursorQueryException to be thrown for GROUP BY query' );
        } catch( fflib_SObjectSelector.InvalidCursorQueryException ex ){
            System.Assert.isTrue( ex.getMessage().contains( 'GROUP BY' ), 'Expected exception message to reference GROUP BY' );
        }

        // Also validate the raw String overload (caught at string level)
        try{
            selector.getCursor( qfWithGroupBy.toSOQL() );
            System.Assert.fail( 'Expected InvalidCursorQueryException to be thrown for GROUP BY query string' );
        } catch( fflib_SObjectSelector.InvalidCursorQueryException ex ){
            System.Assert.isTrue( ex.getMessage().contains( 'GROUP BY' ), 'Expected exception message to reference GROUP BY' );
        }
    }

    @IsTest
    private static void getPaginationCursor_shouldThrowOnGroupByQuery(){
        // Given - create data
        Testfflib_SObjectSelector selector = new Testfflib_SObjectSelector();
        fflib_QueryFactory qfWithGroupBy = selector.newQueryFactory().setGroupByFieldName( 'Name' );

        // When, Then - GROUP BY is not supported by pagination cursors
        try{
            selector.getPaginationCursor( qfWithGroupBy );
            System.Assert.fail( 'Expected InvalidCursorQueryException to be thrown for GROUP BY query' );
        } catch( fflib_SObjectSelector.InvalidCursorQueryException ex ){
            System.Assert.isTrue( ex.getMessage().contains( 'GROUP BY' ), 'Expected exception message to reference GROUP BY' );
        }
    }

    @IsTest
    private static void verifyQuery_Exception_BindVariableProvided(){
        // Create mocks
        Testfflib_SObjectSelector selector = new Testfflib_SObjectSelector();
        fflib_ApexMocks mocks = selector.mockExecuteQuery();
        String query = 'SELECT Id FROM Account';
        Boolean param = true;

        // When - perform test
        selector.executeQuery( query, new Map<String, Object>{ 'bool' => param } );
        selector.getQueryLocator( query, new Map<String, Object>{ 'bool' => param } );
        selector.getCursor( query, new Map<String, Object>{ 'bool' => param } );
        selector.getPaginationCursor( query, new Map<String, Object>{ 'bool' => param } );

        // Then - validate, if calling wrong 'verify'-method, an Exception should be thrown
        try{
            selector.verifyQuery( mocks );
            System.Assert.fail( 'Assert failure was expected since a bindVariableMap was provided to executeQuery()' );
        } catch( Exception ex ){
            System.Assert.areEqual(
                'No executeQuery() was called without bindVariablesMap. If you provided a Map, please use verifyQueryAndBindVariableKeys()',
                ex.getMessage(),
                'Expected different Exception message'
            );
        }
        try{
            selector.verifyQueryLocator( mocks );
            System.Assert.fail( 'Assert failure was expected since a bindVariableMap was provided to getQueryLocator()' );
        } catch( Exception ex ){
            System.Assert.areEqual(
                'No getQueryLocator() was called without bindVariablesMap. If you provided a Map, please use verifyQueryLocatorAndBindVariables()',
                ex.getMessage(),
                'Expected different Exception message'
            );
        }
        try{
            selector.verifyCursor( mocks );
            System.Assert.fail( 'Assert failure was expected since a bindVariableMap was provided to getCursor()' );
        } catch( Exception ex ){
            System.Assert.areEqual(
                'No getCursor() was called without bindVariablesMap. If you provided a Map, please use verifyCursorAndBindVariableKeys()',
                ex.getMessage(),
                'Expected different Exception message'
            );
        }
        try{
            selector.verifyPaginationCursor( mocks );
            System.Assert.fail( 'Assert failure was expected since a bindVariableMap was provided to getPaginationCursor()' );
        } catch( Exception ex ){
            System.Assert.areEqual(
                'No getPaginationCursor() was called without bindVariablesMap. If you provided a Map, please use verifyPaginationCursorAndBindVariableKeys()',
                ex.getMessage(),
                'Expected different Exception message'
            );
        }
    }

    @IsTest
    private static void verifyQueryWithBindVariable_Exception_NoBindVariableProvided(){
        // Create mocks
        Testfflib_SObjectSelector selector = new Testfflib_SObjectSelector();
        fflib_ApexMocks mocks = selector.mockExecuteQuery();

        // When - perform test
        selector.executeQuery( 'SELECT Id FROM Account' );
        selector.getQueryLocator( 'SELECT Id FROM Account' );
        selector.getCursor( 'SELECT Id FROM Account' );
        selector.getPaginationCursor( 'SELECT Id FROM Account' );

        // Then - validate, if calling wrong 'verify'-method, an Exception should be thrown
        try{
            selector.verifyQueryAndBindVariableKeys( mocks );
            System.Assert.fail( 'Assert failure was expected since no bind variables were provided to executeQuery()' );
        } catch( Exception ex ){
            System.Assert.areEqual(
                'No executeQuery() was called providing bind-variables, if you didn\'t provide a bindVariablesMap, please use verifyQuery()',
                ex.getMessage(),
                'Expected different Exception message'
            );
        }
        try{
            selector.verifyQueryLocatorAndBindVariableKeys( mocks );
            System.Assert.fail( 'Assert failure was expected since no bind variables were provided to getQueryLocator()' );
        } catch( Exception ex ){
            System.Assert.areEqual(
                'No getQueryLocator() was called providing bind-variables, if you didn\'t provide a bindVariablesMap, please use verifyQueryLocator()',
                ex.getMessage(),
                'Expected different Exception message'
            );
        }
        try{
            selector.verifyCursorAndBindVariableKeys( mocks );
            System.Assert.fail( 'Assert failure was expected since no bind variables were provided to getCursor()' );
        } catch( Exception ex ){
            System.Assert.areEqual(
                'No getCursor() was called with bindVariablesMap. If you didn\'t provide a Map, please use verifyCursor()',
                ex.getMessage(),
                'Expected different Exception message'
            );
        }
        try{
            selector.verifyPaginationCursorAndBindVariableKeys( mocks );
            System.Assert.fail( 'Assert failure was expected since no bind variables were provided to getPaginationCursor()' );
        } catch( Exception ex ){
            System.Assert.areEqual(
                'No getPaginationCursor() was called with bindVariablesMap. If you didn\'t provide a Map, please use verifyPaginationCursor()',
                ex.getMessage(),
                'Expected different Exception message'
            );
        }
    }

    /**
     * Inner class used to mimic the behavior of an fflib_SObjectSelector instance.
     */
    private class Testfflib_SObjectSelector extends fflib_SObjectSelector{
        public Testfflib_SObjectSelector(){
            super( fflib_Database.Context.FULL );
        }

        public Testfflib_SObjectSelector( fflib_Database.Context securityContext ){
            super( securityContext );
        }

        public Testfflib_SObjectSelector( Boolean includeFieldSetFields ){
            super( includeFieldSetFields );
        }

        public Testfflib_SObjectSelector( Boolean includeFieldSetFields, DataAccess access ){
            super( includeFieldSetFields, access );
        }

        public Testfflib_SObjectSelector( Boolean includeFieldSetFields, fflib_Database.Context securityContext ){
            super( includeFieldSetFields, securityContext );
        }

        public Testfflib_SObjectSelector( Boolean includeFieldSetFields, Boolean enforceCRUD, Boolean enforceFLS ){
            super( includeFieldSetFields, enforceCRUD, enforceFLS );
        }

        public Testfflib_SObjectSelector( Boolean includeFieldSetFields, Boolean enforceCRUD, Boolean enforceFLS, Boolean sortSelectFields ){
            super( includeFieldSetFields, enforceCRUD, enforceFLS, sortSelectFields, false );
        }

        public Testfflib_SObjectSelector( Boolean includeFieldSetFields, Boolean sortSelectFields, fflib_Database.Context securityContext ){
            super( includeFieldSetFields, sortSelectFields, securityContext );
        }

        public Testfflib_SObjectSelector( Boolean includeFieldSetFields, Boolean enforceCRUD, Boolean enforceFLS, Boolean sortSelectFields, Boolean includeRelatedFieldSetFields ){
            super( includeFieldSetFields, enforceCRUD, enforceFLS, sortSelectFields, includeRelatedFieldSetFields );
        }

        public Testfflib_SObjectSelector( Boolean includeFieldSetFields, Boolean sortSelectFields, Boolean includeRelatedFieldSetFields, fflib_Database.Context securityContext ){
            super( includeFieldSetFields, sortSelectFields, includeRelatedFieldSetFields, securityContext );
        }

        protected override Set<String> getRelatedFieldSet(){
            return new Set<String>{
                'Parent.ShippingAddress',
                'Parent.BillingAddress'
            };
        }

        protected override List<Schema.SObjectField> getSObjectFieldList(){
            return new List<Schema.SObjectField>{
                Account.Name,
                Account.Id,
                Account.AccountNumber,
                Account.AnnualRevenue
            };
        }

        protected override Schema.SObjectType getSObjectType(){
            return Account.SObjectType;
        }

        public override String getOrderBy(){
            return 'Name DESC, AnnualRevenue ASC';
        }
    }

    /**
     * Inner class used to mimic the behavior of a fflib_QueryFactory instance.
     */
    private class MockQueryFactory extends fflib_QueryFactory{
        public MockQueryFactory(){
            super( Account.getSObjectType() );
        }

        public override fflib_QueryFactory assertIsAccessible(){
            throw new fflib_SecurityUtils.CrudException( fflib_SecurityUtils.OperationType.READ, Account.getSObjectType() );
        }
    }

    private class TestAccountSObjectSelector_WithoutOrderBy extends fflib_SObjectSelector{
        protected override SObjectType getSObjectType(){
            return Account.SObjectType;
        }

        protected override List<SObjectField> getSObjectFieldList(){
            return new List<SObjectField>();
        }
    }

    private class TestSObjectSelector_AccountHistory extends fflib_SObjectSelector{
        protected override SObjectType getSObjectType(){
            return AccountHistory.SObjectType;
        }

        protected override List<SObjectField> getSObjectFieldList(){
            return new List<SObjectField>();
        }
    }

    private class TestSObjectSelector_GroupMember extends fflib_SObjectSelector{
        protected override SObjectType getSObjectType(){
            return GroupMember.SObjectType;
        }

        protected override List<SObjectField> getSObjectFieldList(){
            return new List<SObjectField>();
        }
    }
}
