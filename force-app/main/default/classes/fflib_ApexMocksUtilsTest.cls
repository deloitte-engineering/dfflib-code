/**
 * Copyright (c), FinancialForce.com, inc
 * Copyright (c) 2019, Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
/** 
 * Public class given several methods are used in this 'Utils' class
 */
@IsTest( isParallel = true )
@SuppressWarnings('PMD.ClassNamingConventions, PMD.ApexUnitTestClassShouldHaveRunAs, PMD.ApexDoc')
public with sharing class fflib_ApexMocksUtilsTest{
    public static Schema.FieldSet findAnyFieldSet(){
        for( Schema.SObjectType objectType : Schema.getGlobalDescribe().values() ){
            for( Schema.FieldSet fs : objectType.getDescribe().fieldSets.getMap().values() ){
                return fs;
            }
        }

        return null;
    }

    @IsTest
    private static void makeRelationship_returnsObjectsWithRelationFieldSet(){
        // Given - create data
        Account acc = new Account(
            Id = fflib_IDGenerator.generate( Account.SObjectType ),
            Name = 'AccName',
            NumberOfEmployees = 7
        );

        Contact contact1 = new Contact(
            Id = fflib_IDGenerator.generate( Contact.SObjectType ),
            DoNotCall = true
        );

        Contact contact2 = new Contact(
            Id = fflib_IDGenerator.generate( Contact.SObjectType ),
            DoNotCall = false
        );

        // When - perform test
        Account accWithRelationships = ( ( List<Account> ) fflib_ApexMocksUtils.makeRelationship(
            List<Account>.class,
            new List<Account>{ acc },
            Contact.AccountId,
            new List<List<Contact>>{ new List<Contact>{ contact1, contact2 } }
        ) )[ 0 ];

        // Then - validate
        System.Assert.areEqual( acc.Id, accWithRelationships.Id );
        System.Assert.areEqual( acc.Name, accWithRelationships.Name );
        System.Assert.areEqual( acc.NumberOfEmployees, accWithRelationships.NumberOfEmployees );

        //Assert relationship fields
        List<Contact> contacts = accWithRelationships.Contacts;
        System.Assert.isNotNull( contacts );
        System.Assert.areEqual( 2, contacts.size() );

        System.Assert.areEqual( contact1.Id, contacts[ 0 ].Id );
        System.Assert.areEqual( contact1.DoNotCall, contacts[ 0 ].DoNotCall );

        System.Assert.areEqual( contact2.Id, contacts[ 1 ].Id );
        System.Assert.areEqual( contact2.DoNotCall, contacts[ 1 ].DoNotCall );
    }

    @IsTest
    private static void makeRelationship_GenericOverload_ReturnsObjectsWithRelationFieldSet(){
        // Given - create data
        SObject acc = Schema.getGlobalDescribe().get( 'Account' ).newSObject();
        acc.put( 'Id', fflib_IDGenerator.generate( acc.getSObjectType() ) );
        acc.put( 'Name', 'AccName' );
        acc.put( 'NumberOfEmployees', 7 );

        SObject contact1 = Schema.getGlobalDescribe().get( 'Contact' ).newSObject();
        contact1.put( 'Id', fflib_IDGenerator.generate( contact1.getSObjectType() ) );
        contact1.put( 'DoNotCall', true );

        SObject contact2 = Schema.getGlobalDescribe().get( 'Contact' ).newSObject();
        contact2.put( 'Id', fflib_IDGenerator.generate( contact2.getSObjectType() ) );
        contact2.put( 'DoNotCall', false );

        // When - perform test
        SObject accWithRelationships = ( ( List<SObject> ) fflib_ApexMocksUtils.makeRelationship(
            'Account',
            'Contact',
            new List<SObject>{ acc },
            'AccountId',
            new List<List<SObject>>{ new List<SObject>{ contact1, contact2 } }

        ) )[ 0 ];

        // Then - validate
        System.Assert.areEqual( acc.Id, accWithRelationships.Id );
        System.Assert.areEqual( acc.get( 'Name' ), accWithRelationships.get( 'Name' ) );
        System.Assert.areEqual( acc.get( 'NumberOfEmployees' ), accWithRelationships.get( 'NumberOfEmployees' ) );

        //Assert relationship fields
        List<SObject> contacts = accWithRelationships.getSObjects( 'Contacts' );
        System.Assert.isNotNull( contacts );
        System.Assert.areEqual( 2, contacts.size() );

        System.Assert.areEqual( contact1.Id, contacts[ 0 ].Id );
        System.Assert.areEqual( ( Boolean ) contact1.get( 'DoNotCall' ), ( Boolean ) contacts[ 0 ].get( 'DoNotCall' ) );

        System.Assert.areEqual( contact2.Id, contacts[ 1 ].Id );
        System.Assert.areEqual( ( Boolean ) contact2.get( 'DoNotCall' ), ( Boolean ) contacts[ 1 ].get( 'DoNotCall' ) );
    }

    @IsTest
    private static void makeRelationship_GenericOverload_ThrowsErrorOnInvalidParentType(){
        // Setup parent object
        SObject acc = Schema.getGlobalDescribe().get( 'Account' ).newSObject();
        acc.put( 'Id', fflib_IDGenerator.generate( acc.getSObjectType() ) );

        // Setup child object
        SObject cont = Schema.getGlobalDescribe().get( 'Contact' ).newSObject();
        cont.put( 'Id', fflib_IDGenerator.generate( cont.getSObjectType() ) );

        String errorMessage = '';
        try{
            // Call method under test
            SObject accWithRelationships = ( ( List<SObject> ) fflib_ApexMocksUtils.makeRelationship(
                'MyInvalidParentType',
                'Contact',
                new List<SObject>{ acc },
                'AccountId',
                new List<List<SObject>>{ new List<SObject>{ cont } }
            ) )[ 0 ];
        } catch( Exception exc ){
            errorMessage = exc.getMessage();
        }
        System.Assert.areEqual( 'SObject type not found: MyInvalidParentType', errorMessage );
    }

    @IsTest
    private static void makeRelationship_GenericOverload_ThrowsErrorOnInvalidChildType(){
        // Setup parent object
        SObject acc = Schema.getGlobalDescribe().get( 'Account' ).newSObject();
        acc.put( 'Id', fflib_IDGenerator.generate( acc.getSObjectType() ) );

        // Setup child object
        SObject cont = Schema.getGlobalDescribe().get( 'Contact' ).newSObject();
        cont.put( 'Id', fflib_IDGenerator.generate( cont.getSObjectType() ) );

        String errorMessage = '', relationshipName = 'My_Invalid_ChildType';
        try{
            // Call method under test
            SObject accWithRelationships = ( ( List<SObject> ) fflib_ApexMocksUtils.makeRelationship(
                'Account',
                relationshipName,
                new List<SObject>{ acc },
                'AccountId',
                new List<List<SObject>>{ new List<SObject>{ cont } }
            ) )[ 0 ];
        } catch( Exception exc ){
            errorMessage = exc.getMessage();
        }
        System.Assert.areEqual( 'SObject type not found: ' + relationshipName, errorMessage );
    }

    @IsTest
    private static void makeRelationship_GenericOverload_ThrowsErrorOnInvalidFieldName(){
        // Setup parent object
        SObject acc = Schema.getGlobalDescribe().get( 'Account' ).newSObject();
        acc.put( 'Id', fflib_IDGenerator.generate( acc.getSObjectType() ) );

        // Setup child object
        SObject cont = Schema.getGlobalDescribe().get( 'Contact' ).newSObject();
        cont.put( 'Id', fflib_IDGenerator.generate( cont.getSObjectType() ) );

        String errorMessage = '';
        try{
            // Call method under test
            SObject accWithRelationships = ( ( List<SObject> ) fflib_ApexMocksUtils.makeRelationship(
                'Account',
                'Contact',
                new List<SObject>{ acc },
                'MyInvalidField',
                new List<List<SObject>>{ new List<SObject>{ cont } }
            ) )[ 0 ];
        } catch( Exception exc ){
            errorMessage = exc.getMessage();
        }
        System.Assert.areEqual( 'SObject field not found: MyInvalidField', errorMessage );
    }

    @IsTest
    private static void makeRelationship_ObjectWithNull_DoesNotThrowErrorOnJSONExceptionCanNotWriteAFieldNameExpectingAValue(){
        // Given
        Product2 prod1 = new Product2(
            Id = fflib_IDGenerator.generate( Product2.SObjectType ),
            Name = 'Product1',
            ProductCode = 'P1',
            Description = null,
            StockKeepingUnit = 'P1'
        );

        Product2 prod2 = new Product2(
            Id = fflib_IDGenerator.generate( Product2.SObjectType ),
            Name = 'Product2',
            ProductCode = 'P2',
            Description = 'this is another product',
            StockKeepingUnit = 'P2'
        );

        OpportunityLineItem oli1 = new OpportunityLineItem(
            Id = fflib_IDGenerator.generate( OpportunityLineItem.SObjectType ),
            Product2Id = prod1.Id,
            Product2 = prod1,
            UnitPrice = 10,
            Quantity = 1
        );

        OpportunityLineItem oli2 = new OpportunityLineItem(
            Id = fflib_IDGenerator.generate( OpportunityLineItem.SObjectType ),
            Product2Id = prod2.Id,
            Product2 = prod2,
            UnitPrice = 10,
            Quantity = 1
        );

        Opportunity opportunity = new Opportunity();

        Exception exceptionThatWasCalled = null;

        // When
        try{
            fflib_ApexMocksUtils.makeRelationship(
                List<Opportunity>.class,
                new List<Opportunity>{ opportunity },
                OpportunityLineItem.OpportunityId,
                new List<List<OpportunityLineItem>>{ new List<OpportunityLineItem>{ oli1, oli2 } }
            );
        } catch( JSONException e ){
            exceptionThatWasCalled = e;
        }

        // Then
        System.debug( exceptionThatWasCalled );
        Assert.isNull( exceptionThatWasCalled, 'Exception should not have been called' );
    }

    @isTest
    private static void setReadOnlyFields_CreatedByIdSetToCurrentUserId_IdFieldSetSuccessfully(){

        Account acc = new Account();
        Id userId = fflib_IDGenerator.generate( ( new User() ).getSObjectType() );

        acc = ( Account ) fflib_ApexMocksUtils.setReadOnlyFields(
            acc,
            Account.class,
            new Map<SObjectField, Object>{ Account.CreatedById => userId }
        );

        System.Assert.areEqual( userId, acc.CreatedById );
    }

    @isTest
    private static void setReadOnlyFields_LastReferencedDateSetOnAccount_DateTimeFieldSetSuccessfully(){

        Account acc = new Account();
        DateTime lastRefDate = DateTime.newInstanceGmt( 2020, 1, 7, 23, 30, 0 );

        acc = ( Account ) fflib_ApexMocksUtils.setReadOnlyFields(
            acc,
            Account.class,
            new Map<SObjectField, Object>{ Account.LastReferencedDate => lastRefDate }
        );

        System.Assert.areEqual( lastRefDate, acc.LastReferencedDate );
    }

    @isTest
    private static void setReadOnlyFields_IsDeletedSetOnAccount_BooleanFieldSetSuccessfully(){

        Account acc = new Account();
        Boolean isDeleted = true;

        acc = ( Account ) fflib_ApexMocksUtils.setReadOnlyFields(
            acc,
            Account.class,
            new Map<SObjectField, Object>{ Account.IsDeleted => isDeleted }
        );

        System.Assert.areEqual( isDeleted, acc.IsDeleted );
    }

    @isTest
    private static void setReadOnlyFields_PolymorphicRelationJoin_FieldSetSuccessfully(){

        Account acc = new Account( Name = 'TestAccount' );
        Task t = new Task();

        t = ( Task ) fflib_ApexMocksUtils.setReadOnlyFields(
            t,
            Task.class,
            new Map<String, Object>{ 'What' => acc }
        );

        System.Assert.areEqual( acc.Name, t.What.Name );
    }

    @IsTest
    private static void setReadOnlyFields_WithChildren_FieldSetSuccessfully(){
        // Given
        Contact cont = new Contact(
            Id = fflib_IDGenerator.generate( Contact.SObjectType ),
            LastName = 'ContactName'
        );

        Opportunity opp = new Opportunity(
            Id = fflib_IDGenerator.generate( Opportunity.SObjectType ),
            Name = 'OpportunityName'
        );

        Account acc = new Account();

        Id userId = fflib_IDGenerator.generate( ( new User() ).getSObjectType() );

        acc = ( ( List<Account> ) fflib_ApexMocksUtils.makeRelationship(
            List<Account>.class,
            new List<Account>{ acc },
            Contact.AccountId,
            new List<List<Contact>>{ new List<Contact>{ cont } }
        ) )[0];

        acc = ( ( List<Account> ) fflib_ApexMocksUtils.makeRelationship(
            List<Account>.class,
            new List<Account>{ acc },
            Opportunity.AccountId,
            new List<List<Opportunity>>{ new List<Opportunity>{ opp } }
        ) )[0];

        // When
        acc = ( Account ) fflib_ApexMocksUtils.setReadOnlyFields(
            acc,
            Account.class,
            new Map<SObjectField, Object>{ Account.CreatedById => userId }
        );

        Assert.areEqual( userId, acc.CreatedById );
    }

    @IsTest
    private static void setReadOnlyFields_WithChildren_PreservesChildRelationships(){
        // Given
        Contact cont = new Contact(
            Id = fflib_IDGenerator.generate( Contact.SObjectType ),
            LastName = 'ContactName'
        );

        Opportunity opp = new Opportunity(
            Id = fflib_IDGenerator.generate( Opportunity.SObjectType ),
            Name = 'OpportunityName'
        );

        Account acc = new Account();

        Id userId = fflib_IDGenerator.generate( ( new User() ).getSObjectType() );

        acc = ( ( List<Account> ) fflib_ApexMocksUtils.makeRelationship(
            List<Account>.class,
            new List<Account>{ acc },
            Contact.AccountId,
            new List<List<Contact>>{ new List<Contact>{ cont } }
        ) )[0];

        acc = ( ( List<Account> ) fflib_ApexMocksUtils.makeRelationship(
            List<Account>.class,
            new List<Account>{ acc },
            Opportunity.AccountId,
            new List<List<Opportunity>>{ new List<Opportunity>{ opp } }
        ) )[0];

        // When
        acc = ( Account ) fflib_ApexMocksUtils.setReadOnlyFields(
            acc,
            Account.class,
            new Map<SObjectField, Object>{ Account.CreatedById => userId }
        );

        // Then
        System.Assert.areEqual( userId, acc.CreatedById );
        System.Assert.isNotNull( acc.Contacts );
        System.Assert.areEqual( 1, acc.Contacts.size() );
        System.Assert.areEqual( cont.Id, acc.Contacts[0].Id );
        System.Assert.areEqual( cont.LastName, acc.Contacts[0].LastName );
        System.Assert.isNotNull( acc.Opportunities );
        System.Assert.areEqual( 1, acc.Opportunities.size() );
        System.Assert.areEqual( opp.Id, acc.Opportunities[0].Id );
        System.Assert.areEqual( opp.Name, acc.Opportunities[0].Name );
    }

    @isTest
    private static void setReadOnlyFields_WithChildren_PreservesWritableFields(){
        // Given - Name and NumberOfEmployees are updateable=true; CreatedById is updateable=false (the injected field)
        Contact cont = new Contact(
            Id = fflib_IDGenerator.generate( Contact.SObjectType ),
            LastName = 'ContactName'
        );

        Account acc = new Account(
            Id = fflib_IDGenerator.generate( Account.SObjectType ),
            Name = 'AccName',
            NumberOfEmployees = 7
        );

        Id userId = fflib_IDGenerator.generate( ( new User() ).getSObjectType() );

        acc = ( ( List<Account> ) fflib_ApexMocksUtils.makeRelationship(
            List<Account>.class,
            new List<Account>{ acc },
            Contact.AccountId,
            new List<List<Contact>>{ new List<Contact>{ cont } }
        ) )[ 0 ];

        // When
        acc = ( Account ) fflib_ApexMocksUtils.setReadOnlyFields(
            acc,
            Account.class,
            new Map<SObjectField, Object>{ Account.CreatedById => userId }
        );

        // Then - writable fields (updateable=true) must survive the round-trip
        System.Assert.areEqual( 'AccName', acc.Name );
        System.Assert.areEqual( 7, acc.NumberOfEmployees );
        System.Assert.areEqual( userId, acc.CreatedById );
        System.Assert.areEqual( 1, acc.Contacts.size() );
        System.Assert.areEqual( cont.LastName, acc.Contacts[0].LastName );
    }

    @isTest
    private static void setReadOnlyFields_OverwritesExistingNonUpdateableField(){
        // Given - CreatedById is updateable=false; second call should replace the injected value
        Account acc = new Account();
        Id firstUserId = fflib_IDGenerator.generate( ( new User() ).getSObjectType() );
        Id secondUserId = fflib_IDGenerator.generate( ( new User() ).getSObjectType() );

        acc = ( Account ) fflib_ApexMocksUtils.setReadOnlyFields(
            acc,
            Account.class,
            new Map<SObjectField, Object>{ Account.CreatedById => firstUserId }
        );

        // When - field already present in serialized JSON; properties map should overwrite it
        acc = ( Account ) fflib_ApexMocksUtils.setReadOnlyFields(
            acc,
            Account.class,
            new Map<SObjectField, Object>{ Account.CreatedById => secondUserId }
        );

        // Then
        System.Assert.areEqual( secondUserId, acc.CreatedById );
    }

    @isTest
    private static void setReadOnlyFields_EmptyProperties_PreservesRecord(){
        // Given
        Contact cont = new Contact(
            Id = fflib_IDGenerator.generate( Contact.SObjectType ),
            LastName = 'ContactName'
        );

        Account acc = new Account(
            Id = fflib_IDGenerator.generate( Account.SObjectType ),
            Name = 'AccName',
            NumberOfEmployees = 7
        );

        acc = ( ( List<Account> ) fflib_ApexMocksUtils.makeRelationship(
            List<Account>.class,
            new List<Account>{ acc },
            Contact.AccountId,
            new List<List<Contact>>{ new List<Contact>{ cont } }
        ) )[ 0 ];

        // When
        acc = ( Account ) fflib_ApexMocksUtils.setReadOnlyFields(
            acc,
            Account.class,
            new Map<String, Object>()
        );

        // Then
        System.Assert.areEqual( 'AccName', acc.Name );
        System.Assert.areEqual( 7, acc.NumberOfEmployees );
        System.Assert.areEqual( 1, acc.Contacts.size() );
        System.Assert.areEqual( cont.LastName, acc.Contacts[0].LastName );
    }

    @isTest
    private static void setReadOnlyFields_WithChildren_NonUpdateableNumericFieldSetSuccessfully(){
        // Given - mirrors issue #163: inject a non-updateable numeric field (ExpectedRevenue: updateable=false, type=currency)
        // on a parent that already has children via makeRelationship
        OpportunityLineItem oli = new OpportunityLineItem(
            Id = fflib_IDGenerator.generate( OpportunityLineItem.SObjectType ),
            UnitPrice = 10,
            Quantity = 1
        );

        Opportunity opp = new Opportunity(
            Id = fflib_IDGenerator.generate( Opportunity.SObjectType ),
            Name = 'OpportunityName'
        );

        Decimal expectedRevenue = 4200;

        opp = ( ( List<Opportunity> ) fflib_ApexMocksUtils.makeRelationship(
            List<Opportunity>.class,
            new List<Opportunity>{ opp },
            OpportunityLineItem.OpportunityId,
            new List<List<OpportunityLineItem>>{ new List<OpportunityLineItem>{ oli } }
        ) )[ 0 ];

        // When
        opp = ( Opportunity ) fflib_ApexMocksUtils.setReadOnlyFields(
            opp,
            Opportunity.class,
            new Map<SObjectField, Object>{ Opportunity.ExpectedRevenue => expectedRevenue }
        );

        // Then
        System.Assert.areEqual( expectedRevenue, opp.ExpectedRevenue );
        System.Assert.areEqual( 'OpportunityName', opp.Name );
        System.Assert.areEqual( 1, opp.OpportunityLineItems.size() );
        System.Assert.areEqual( oli.Id, opp.OpportunityLineItems[0].Id );
    }

    @isTest
    private static void setReadOnlyFields_MultipleProperties_AllFieldsSet(){
        // Given
        Account acc = new Account();
        Id userId = fflib_IDGenerator.generate( ( new User() ).getSObjectType() );
        DateTime lastRefDate = DateTime.newInstanceGmt( 2020, 1, 7, 23, 30, 0 );

        // When
        acc = ( Account ) fflib_ApexMocksUtils.setReadOnlyFields(
            acc,
            Account.class,
            new Map<SObjectField, Object>{
                Account.CreatedById => userId,
                Account.LastReferencedDate => lastRefDate,
                Account.IsDeleted => true
            }
        );

        // Then
        System.Assert.areEqual( userId, acc.CreatedById );
        System.Assert.areEqual( lastRefDate, acc.LastReferencedDate );
        System.Assert.isTrue( acc.IsDeleted );
    }

    @isTest
    private static void setReadOnlyFields_NullPropertyValue_FieldSetToNull(){
        // Given - LastReferencedDate is updateable=false; null must round-trip via writeNullField
        Account acc = new Account( Name = 'AccName' );

        // When
        acc = ( Account ) fflib_ApexMocksUtils.setReadOnlyFields(
            acc,
            Account.class,
            new Map<SObjectField, Object>{ Account.LastReferencedDate => null }
        );

        // Then
        System.Assert.isNull( acc.LastReferencedDate );
        System.Assert.areEqual( 'AccName', acc.Name );
    }
}
