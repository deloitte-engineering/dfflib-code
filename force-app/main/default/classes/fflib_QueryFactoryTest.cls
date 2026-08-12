/**
 * Copyright (c), FinancialForce.com, inc
 * Copyright (c), Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
@IsTest( IsParallel = true )
private with sharing class fflib_QueryFactoryTest{

    @IsTest
    private static void fieldSelections(){
        // Given - create data
        fflib_QueryFactory qf = new fflib_QueryFactory( Contact.SObjectType );

        // When - perform test
        qf.selectField( 'firstName' );
        qf.selectField( Schema.Contact.SObjectType.fields.lastName );
        qf.selectFields( new Set<String>{ 'acCounTId', 'account.name' } );
        qf.selectFields( new List<String>{ 'homePhonE', 'fAX' } );
        qf.selectFields( new List<Schema.SObjectField>{ Contact.Email, Contact.Title } );

        // Then - validate
        System.Assert.areEqual(
            new Set<String>{
                'firstname',
                'lastname',
                'accountid',
                'account.name',
                'homephone',
                'fax',
                'email',
                'title'
            },
            qf.getSelectedFields() );
    }

    @IsTest
    private static void simpleFieldSelection(){
        // Given - create data
        fflib_QueryFactory qf = new fflib_QueryFactory( Contact.SObjectType );

        // When - perform test
        qf.selectField( 'NAMe' ).selectFields( new Set<String>{ 'naMe', 'email' } );
        String query = qf.toSOQL();

        // Then - validate
        System.Assert.isTrue( Pattern.matches( 'SELECT.*name.*FROM.*', query ), 'Expected Name field in query, got ' + query );
        System.Assert.isTrue( Pattern.matches( 'SELECT.*email.*FROM.*', query ), 'Expected Name field in query, got ' + query );
        qf.setLimit( 100 );
        System.Assert.areEqual( 100, qf.getLimit() );
        System.Assert.isTrue( qf.toSOQL().endsWithIgnoreCase( 'LIMIT ' + qf.getLimit() ), 'Failed to respect limit clause:' + qf.toSOQL() );
    }

    @IsTest
    private static void simpleFieldCondition(){
        // Given - create data
        String whereClause = 'name = \'test\'';
        fflib_QueryFactory qf = new fflib_QueryFactory( Contact.SObjectType );

        // When - perform test
        qf.selectField( 'name' );
        qf.selectField( 'email' );
        qf.setCondition( whereClause );

        // Then - validate
        System.Assert.areEqual( whereClause, qf.getCondition() );
        String query = qf.toSOQL();
        System.Assert.isTrue( query.endsWith( 'WHERE name = \'test\'' ), 'Query should have ended with a filter on name, got: ' + query );
    }

    @IsTest
    private static void duplicateFieldSelection(){
        // Given - create data
        fflib_QueryFactory qf = new fflib_QueryFactory( Contact.SObjectType );

        // When - perform test
        qf.selectField( 'NAMe' ).selectFields( new Set<String>{ 'naMe', 'email' } );
        String query = qf.toSOQL();

        // Then - validate
        System.Assert.areEqual( 1, query.countMatches( 'name' ), 'Expected one name field in query: ' + query );
    }

    @IsTest
    private static void selectFunction_toLabel(){
        // Given - construct QueryFactory in legacy to allow original REGEX logic to be validated
        fflib_QueryFactory qf = new fflib_QueryFactory( Contact.SObjectType ).setEnforceFLS( fflib_QueryFactory.FLSEnforcement.LEGACY );

        // When - perform test
        qf.selectField( 'toLabel(Name)' );
        qf.selectField( 'toLabel( Account.Name ) as AccountName' );
        qf.selectField( 'COUNT( ID)' );
        qf.selectField( 'COUNT(id ) as num' );
        String query = qf.toSOQL();

        // Then - validate
        System.Assert.areEqual( 'SELECT COUNT( Id), COUNT(Id ) as num, toLabel( Account.Name ) as AccountName, toLabel(Name) FROM Contact', query, 'Expected COUNT fields to be in query ' + query );
    }

    @IsTest
    private static void selectField_Lookup_Polymorph(){
        // Given - create data
        fflib_QueryFactory qf = new fflib_QueryFactory( Case.SObjectType ).setEnforceFLS( fflib_QueryFactory.FLSEnforcement.LEGACY );

        // When - perform test
        try{
            qf.selectField( 'Account.(User)Owner.Phone' );
            qf.selectField( 'Owner.Phone' ); // Owner on Case is Polymorphic to Group and User
            throw new fflib.InvalidImplementationException( 'This Exception should never been thrown since PolymorphicLookup Exception should be thrown due to Owner-Group field' );
        } catch( Exception ex ){
            System.Assert.areEqual( 'fflib_QueryFactory.InvalidFieldException', ex.getTypeName(), 'Expected different Exception Type' );
            System.Assert.areEqual( 'Invalid field \'Phone\' for object \'Group\'', ex.getMessage(), 'Expected Phone and Group message' );
        }
    }

    @IsTest
    private static void selectField_Lookup_Casting(){
        // Given - create data
        fflib_QueryFactory qf = new fflib_QueryFactory( Case.SObjectType );
        String exceptionMessage;

        // When - perform test
        try{
            qf.selectField( '(User)Owner.Phone' );
            String query = qf.toSOQL();
            System.Assert.isTrue( query.containsIgnoreCase( 'Owner.Phone' ), 'Expected Owner.Phone to be a query field ' + query );
        } catch( fflib_QueryFactory.PolymorphicLookupException ex ){
            exceptionMessage = ex.getMessage();
        }

        // Then - validate
        System.Assert.isNull( exceptionMessage, 'Expected no exception message' );
    }

    @IsTest
    private static void selectField_Lookup_Polymorph_Casting(){
        // Given - create data
        fflib_QueryFactory qf = new fflib_QueryFactory( Contact.SObjectType ).setEnforceFLS( fflib_QueryFactory.FLSEnforcement.LEGACY );
        Exception e;

        // When - perform test
        try{
            qf.selectField( 'Account.(User)Owner.Phone' );
            String query = qf.toSOQL();
            System.Assert.isTrue( query.containsIgnoreCase( 'Account.Owner.Phone' ), 'Expected Account.Owner.Phone to be a query field ' + query );
        } catch( fflib_QueryFactory.PolymorphicLookupException ex ){
            e = ex;
        }

        // Then - validate
        System.Assert.isNull( e );
    }

    @IsTest
    private static void selectField_Lookup_Polymorph_InvalidCasts(){
        // Given - create data
        fflib_QueryFactory qf = new fflib_QueryFactory( Case.SObjectType ).setEnforceFLS( fflib_QueryFactory.FLSEnforcement.LEGACY );

        // When - perform test
        try{
            qf.selectField( '()Owner.Phone' );
            throw new fflib_QueryFactory.PolymorphicLookupException( 'Expected exception to be thrown due to empty cast' );
        } catch( fflib_QueryFactory.PolymorphicLookupException ex ){
            System.Assert.areEqual( 'fflib_QueryFactory.PolymorphicLookupException', ex.getTypeName(), 'Expected different Exception type' );
            System.Assert.areEqual( 'Cannot have an empty type cast', ex.getMessage(), 'Expected different exception message' );
        }

        try{
            qf.selectField( '(ApexClass)Owner.Phone' );
            throw new fflib_QueryFactory.PolymorphicLookupException( 'Expected exception to be thrown due to invalid SObjectType cast' );
        } catch( fflib_QueryFactory.PolymorphicLookupException ex ){
            System.Assert.areEqual( 'fflib_QueryFactory.PolymorphicLookupException', ex.getTypeName(), 'Expected different Exception type' );
            System.Assert.isTrue( ex.getMessage().contains( 'Invalid type cast for the polymorphic lookup' ), 'Expected different exception message ' + ex.getMessage() );
        }
    }

    @IsTest
    private static void selectTypeOf(){
        // Given - create data
        fflib_QueryFactory qf = new fflib_QueryFactory( Task.SObjectType );

        // When - perform test
        qf.selectFieldsTypeOf( 'Owner', new Map<Schema.SObjectType, Set<Schema.SObjectField>>{
            User.SObjectType => new Set<Schema.SObjectField>{ User.Name },
            Group.SObjectType => new Set<Schema.SObjectField>{ Group.Name }
        } );
        String query = qf.toSOQL();

        // Then - validate
        Assert.isTrue( query.contains(
            'SELECT TYPEOF Owner WHEN User THEN Name WHEN Group THEN Name END FROM Task' ),
            'Expected Name field in query related to the User and Group SObject type for the Owner field, got ' + query
        );
    }

    @IsTest
    private static void equalityCheck(){
        // Given - create data
        fflib_QueryFactory qf1 = new fflib_QueryFactory( Contact.SObjectType );
        fflib_QueryFactory qf2 = new fflib_QueryFactory( Contact.SObjectType );

        // When, Then
        System.Assert.areEqual( qf1, qf2 );
        qf1.selectField( 'name' );
        System.Assert.areNotEqual( qf1, qf2 );
        qf2.selectField( 'NAmE' );
        System.Assert.areEqual( qf1, qf2 );
        qf1.selectField( 'name' ).selectFields( new Set<String>{ 'NAME', 'name' } ).selectFields( new Set<Schema.SObjectField>{ Contact.Name, Contact.Name } );
        System.Assert.areEqual( qf1, qf2 );
    }

    @IsTest
    private static void nonReferenceField(){
        // Given - create data
        fflib_QueryFactory qf = new fflib_QueryFactory( Contact.SObjectType ).setEnforceFLS( fflib_QueryFactory.FLSEnforcement.LEGACY );
        fflib_QueryFactory.NonReferenceFieldException e;

        // When - perform test
        try{
            qf.selectField( 'name.title' );
        } catch( fflib_QueryFactory.NonReferenceFieldException ex ){
            e = ex;
        }

        // Then - validate
        System.Assert.areNotEqual( null, e, 'Cross-object notation on a non-reference field should throw NonReferenceFieldException.' );
    }

    @IsTest
    private static void invalidCrossObjectField(){
        // Given - create data
        fflib_QueryFactory qf = new fflib_QueryFactory( Contact.SObjectType ).setEnforceFLS( fflib_QueryFactory.FLSEnforcement.LEGACY );
        fflib_QueryFactory.InvalidFieldException e;

        // When - perform test
        try{
            qf.selectField( 'account.NOT_A_REAL_FIELD' );
        } catch( fflib_QueryFactory.InvalidFieldException ex ){
            e = ex;
        }

        // Then - validate
        System.Assert.areNotEqual( null, e, 'Cross-object notation on a non-reference field should throw NonReferenceFieldException.' );
    }

    @IsTest
    private static void invalidFieldTests(){
        // Given - create data
        List<fflib_QueryFactory.InvalidFieldException> exceptions = new List<fflib_QueryFactory.InvalidFieldException>();
        fflib_QueryFactory qf = new fflib_QueryFactory( Contact.SObjectType ).setEnforceFLS( fflib_QueryFactory.FLSEnforcement.LEGACY );

        // When - perform test
        try{
            qf.selectField( 'Not_a_field' );
        } catch( fflib_QueryFactory.InvalidFieldException e ){
            exceptions.add( e );
        }

        try{
            qf.selectFields( new Set<String>{ 'Not_a_field', 'alsoNotreal' } );
        } catch( fflib_QueryFactory.InvalidFieldException e ){
            exceptions.add( e );
        }

        try{
            qf.selectFields( new Set<Schema.SObjectField>{ null } );
        } catch( fflib_QueryFactory.InvalidFieldException e ){
            exceptions.add( e );
        }

        try{
            qf.selectFields( new List<Schema.SObjectField>{ null, Contact.title } );
        } catch( fflib_QueryFactory.InvalidFieldException e ){
            exceptions.add( e );
        }

        // Then - validate
        System.Assert.areEqual( 4, exceptions.size() );
    }

    @IsTest
    private static void ordering(){
        // Given - create data
        fflib_QueryFactory qf = new fflib_QueryFactory( Contact.SObjectType );

        // When - perform test
        qf.selectField( 'name' );
        qf.selectField( 'email' );
        qf.setCondition( 'name = \'test\'' );
        qf.addOrdering( new fflib_QueryFactory.Ordering( 'Contact', 'name', fflib_QueryFactory.SortOrder.ASCENDING ) )
            .addOrdering(
                new fflib_QueryFactory.Ordering(
                    fflib_SObjectDescribe.getDescribe( 'Contact' ).getField( 'CreatedDATE' ),
                    fflib_QueryFactory.SortOrder.DESCENDING,
                    true
                )
            );
        String query = qf.toSOQL();

        // Then - validate
        System.Assert.areEqual( 2, qf.getOrderings().size() );
        System.Assert.areEqual( 'Name', qf.getOrderings()[ 0 ].getField() );
        System.Assert.areEqual( fflib_QueryFactory.SortOrder.DESCENDING, qf.getOrderings()[ 1 ].getDirection() );

        System.Assert.isTrue( Pattern.matches( 'SELECT.*name.*FROM.*', query ), 'Expected Name field in query, got ' + query );
        System.Assert.isTrue( Pattern.matches( 'SELECT.*email.*FROM.*', query ), 'Expected Name field in query, got ' + query );

        qf.emptyOrdering();
        System.Assert.areEqual( 0, qf.getOrderings().size() );

    }

    @IsTest
    private static void setOrdering_ReplacesPreviousOrderingsWithExpectedOrdering(){
        // Given - create data
        fflib_QueryFactory qf = new fflib_QueryFactory( Contact.SObjectType );

        // When - perform test
        qf.selectField( 'name' );
        qf.selectField( 'email' );
        qf.setCondition( 'name = \'test\'' );

        // Test base method with ordering by OwnerId Descending
        qf.setOrdering( new fflib_QueryFactory.Ordering( 'Contact', 'OwnerId', fflib_QueryFactory.SortOrder.DESCENDING ) );

        // Then - validate
        System.Assert.areEqual( 1, qf.getOrderings().size(), 'Unexpected order size - setOrder should replace default Orderings' );
        System.Assert.areEqual( Contact.OwnerId.getDescribe().getName(), qf.getOrderings()[ 0 ].getField(), 'Unexpected order field - should have been resolved from the field OwnerId' );
        System.Assert.areEqual( fflib_QueryFactory.SortOrder.DESCENDING, qf.getOrderings()[ 0 ].getDirection(), 'Unexpected order direction.' );

        // Test method overload with ordering by LastModifiedDate Ascending
        qf.setOrdering( 'LastModifiedDate', fflib_QueryFactory.SortOrder.ASCENDING, true );

        System.Assert.areEqual( 1, qf.getOrderings().size(), 'Unexpected order size - setOrder should replace previous Orderings' );
        System.Assert.areEqual( Contact.LastModifiedDate.getDescribe().getName(), qf.getOrderings()[ 0 ].getField(), 'Unexpected order field - should have been resolved from the field LastModifiedDate' );
        System.Assert.areEqual( fflib_QueryFactory.SortOrder.ASCENDING, qf.getOrderings()[ 0 ].getDirection(), 'Unexpected order direction.' );

        // Test method overload with ordering by CreatedDate Descending
        qf.setOrdering( Contact.CreatedDate, fflib_QueryFactory.SortOrder.DESCENDING, true );

        System.Assert.areEqual( 1, qf.getOrderings().size(), 'Unexpected order size - setOrder should replace previous Orderings' );
        System.Assert.areEqual( Contact.CreatedDate.getDescribe().getName(), qf.getOrderings()[ 0 ].getField(), 'Unexpected order field - should have been resolved from the field CreatedDate' );
        System.Assert.areEqual( fflib_QueryFactory.SortOrder.DESCENDING, qf.getOrderings()[ 0 ].getDirection(), 'Unexpected order direction.' );

        // Test method overload with ordering by CreatedBy.Name Descending
        qf.setOrdering( 'CreatedBy.Name', fflib_QueryFactory.SortOrder.DESCENDING );

        System.Assert.areEqual( 1, qf.getOrderings().size(), 'Unexpected order size - setOrder should replace previous Orderings' );
        System.Assert.areEqual( fflib_QueryFactory.SortOrder.DESCENDING, qf.getOrderings()[ 0 ].getDirection(), 'Unexpected order direction.' );

        // Test method overload with ordering by Birthdate Ascending
        qf.setOrdering( Contact.Birthdate, fflib_QueryFactory.SortOrder.ASCENDING );

        System.Assert.areEqual( 1, qf.getOrderings().size(), 'Unexpected order size - setOrder should replace previous Orderings' );
        System.Assert.areEqual( Contact.Birthdate.getDescribe().getName(), qf.getOrderings()[ 0 ].getField(), 'Unexpected order field - should have been resolved from the field Birthdate' );
        System.Assert.areEqual( fflib_QueryFactory.SortOrder.ASCENDING, qf.getOrderings()[ 0 ].getDirection(), 'Unexpected order direction.' );

        String query = qf.toSOQL();
    }

    @IsTest
    private static void setOrderingDistance_ReplacesPreviousOrderingsWithExpectedOrdering(){
        // Given - create data
        fflib_QueryFactory qf = new fflib_QueryFactory( Account.SObjectType );

        // When - perform test
        qf.selectField( 'Id' );

        // Test base method
        qf.setOrderingDistance( 'BillingAddress', 6.0, 5.5, fflib_QueryFactory.DistanceUnit.KILOMETERS, fflib_QueryFactory.SortOrder.ASCENDING, true );

        // Then - validate
        System.Assert.areEqual( 1, qf.getOrderings().size(), 'Unexpected order size - setOrderingDistance should replace default Orderings' );
        System.Assert.areEqual( 'DISTANCE( BillingAddress, GEOLOCATION( 5.5, 6.0 ), \'km\' )', qf.getOrderings()[ 0 ].getField(), 'Unexpected order field - should have been resolved from the field Address' );
        System.Assert.areEqual( fflib_QueryFactory.SortOrder.ASCENDING, qf.getOrderings()[ 0 ].getDirection(), 'Unexpected order direction.' );

        // Test base method
        qf.setOrderingDistance( 'BillingAddress', 6.0, 5.5, fflib_QueryFactory.DistanceUnit.MILES, fflib_QueryFactory.SortOrder.ASCENDING, true );

        // Then - validate
        System.Assert.areEqual( 1, qf.getOrderings().size(), 'Unexpected order size - setOrderingDistance should replace default Orderings' );
        System.Assert.areEqual( 'DISTANCE( BillingAddress, GEOLOCATION( 5.5, 6.0 ), \'mi\' )', qf.getOrderings()[ 0 ].getField(), 'Unexpected order field - should have been resolved from the field Address' );
        System.Assert.areEqual( fflib_QueryFactory.SortOrder.ASCENDING, qf.getOrderings()[ 0 ].getDirection(), 'Unexpected order direction.' );
    }

    @IsTest
    private static void addOrderingDistance_AddsOrderingsWithExpectedOrdering(){
        // Given - create data
        fflib_QueryFactory qf = new fflib_QueryFactory( Account.SObjectType );

        // When - perform test
        qf.selectField( 'Id' );
        qf.setOrdering( Account.Name, fflib_QueryFactory.SortOrder.ASCENDING, true );

        // Test base method
        qf.addOrderingDistance( 'BillingAddress', 6.0, 5.5, fflib_QueryFactory.DistanceUnit.KILOMETERS, fflib_QueryFactory.SortOrder.ASCENDING, true );

        // Then - validate
        System.Assert.areEqual( 2, qf.getOrderings().size(), 'Unexpected order size - addOrderingDistance should replace default Orderings' );
        System.Assert.areEqual( 'Name', qf.getOrderings()[ 0 ].getField(), 'Unexpected order field - should have been resolved from the field Name' );
        System.Assert.areEqual( 'DISTANCE( BillingAddress, GEOLOCATION( 5.5, 6.0 ), \'km\' )', qf.getOrderings()[ 1 ].getField(), 'Unexpected order field - should have been resolved from the field Address' );
        System.Assert.areEqual( fflib_QueryFactory.SortOrder.ASCENDING, qf.getOrderings()[ 0 ].getDirection(), 'Unexpected order direction.' );

        // When - perform test
        qf.setOrdering( Account.Name, fflib_QueryFactory.SortOrder.ASCENDING, true );

        // Test base method
        qf.addOrderingDistance( 'BillingAddress', 6.0, 5.5, fflib_QueryFactory.DistanceUnit.MILES, fflib_QueryFactory.SortOrder.ASCENDING, true );

        // Then - validate
        System.Assert.areEqual( 2, qf.getOrderings().size(), 'Unexpected order size - addOrderingDistance should replace default Orderings' );
        System.Assert.areEqual( 'Name', qf.getOrderings()[ 0 ].getField(), 'Unexpected order field - should have been resolved from the field Name' );
        System.Assert.areEqual( 'DISTANCE( BillingAddress, GEOLOCATION( 5.5, 6.0 ), \'mi\' )', qf.getOrderings()[ 1 ].getField(), 'Unexpected order field - should have been resolved from the field Address' );
        System.Assert.areEqual( fflib_QueryFactory.SortOrder.ASCENDING, qf.getOrderings()[ 0 ].getDirection(), 'Unexpected order direction.' );
    }

    @IsTest
    private static void invalidField_string(){
        // Given - create data
        fflib_QueryFactory qf = new fflib_QueryFactory( Contact.SObjectType ).setEnforceFLS( fflib_QueryFactory.FLSEnforcement.LEGACY );
        qf.selectField( 'name' );
        Exception e;

        // When - perform test
        try{
            qf.selectField( 'not_a__field' );
        } catch( fflib_QueryFactory.InvalidFieldException ex ){
            e = ex;
        }

        // Then - validate
        System.Assert.areNotEqual( null, e );
    }

    @IsTest
    private static void invalidFields_string(){
        // Given - create data
        fflib_QueryFactory qf = new fflib_QueryFactory( Contact.SObjectType ).setEnforceFLS( fflib_QueryFactory.FLSEnforcement.LEGACY );
        qf.selectField( 'name' );
        Exception e;

        // When - perform test
        try{
            qf.selectFields( new List<String>{ 'not_a__field' } );
        } catch( fflib_QueryFactory.InvalidFieldException ex ){
            e = ex;
        }

        // Then - validate
        System.Assert.areNotEqual( null, e );
    }

    @IsTest
    private static void invalidField_nullToken(){
        // Given - create data
        fflib_QueryFactory qf = new fflib_QueryFactory( Contact.SObjectType );
        qf.selectField( 'name' );
        Exception e;
        Schema.SObjectField token = null;

        // When - perform test
        try{
            qf.selectField( token );
        } catch( fflib_QueryFactory.InvalidFieldException ex ){
            e = ex;
        }

        // Then - validate
        System.Assert.areNotEqual( null, e );
    }

    @IsTest
    private static void invalidFields_nullToken(){
        // Given - create data
        fflib_QueryFactory qf = new fflib_QueryFactory( Contact.SObjectType );
        qf.selectField( 'name' );
        Exception e;
        List<Schema.SObjectField> token = new List<Schema.SObjectField>{ null };

        // When - perform test
        try{
            qf.selectFields( token );
        } catch( fflib_QueryFactory.InvalidFieldException ex ){
            e = ex;
        }

        // Then - validate
        System.Assert.areNotEqual( null, e );
    }

    @IsTest
    private static void invalidFields_noQueryField(){
        // Given, When
        try{
            String path = fflib_QueryFactory.getFieldTokenPath( null );
            throw new fflib.InvalidImplementationException( 'This Exception should never been thrown since InvalidFieldException should have been thrown' );
        } catch( Exception e ){
            System.Assert.areEqual( 'fflib_QueryFactory.InvalidFieldException', e.getTypeName() );
        }
    }

    @IsTest
    private static void queryFieldsNotEquals(){
        // Given, When
        String qfld = fflib_QueryFactory.getFieldTokenPath( Contact.Name );
        String qfld2 = fflib_QueryFactory.getFieldTokenPath( Contact.LastName );

        // Then - validate
        System.Assert.isFalse( qfld.equals( qfld2 ) );
    }

    @IsTest
    private static void addChildQueriesWithChildRelationship_success(){
        // Given - create data
        fflib_QueryFactory qf = new fflib_QueryFactory( Contact.SObjectType );
        qf.selectField( 'name' ).selectField( 'Id' ).setCondition( 'LastName = :CONTACT_LAST_NAME' ).addOrdering( 'CreatedDate', fflib_QueryFactory.SortOrder.DESCENDING, true );
        Schema.DescribeSObjectResult descResult = Contact.SObjectType.getDescribe();
        // Explicitly assert object accessibility when creating the subselect
        qf.subselectQuery( 'Tasks', true ).selectField( 'Id' ).selectField( 'Subject' ).setCondition( ' IsDeleted = false ' );

        // When - perform test
        List<fflib_QueryFactory> queries = qf.getSubselectQueries();

        // Then - validate
        System.Assert.isNotNull( queries );
        System.Assert.isTrue(
            Pattern.matches( 'SELECT.*(SELECT.*FROM Tasks WHERE.*).*FROM Contact WHERE.*', qf.toSOQL() ),
            'Incorrect returned query'
        );
    }

    @IsTest
    private static void addChildQueriesWithChildRelationshipNoAccessibleCheck_success(){
        // Given - create data
        fflib_QueryFactory qf = new fflib_QueryFactory( Contact.SObjectType );
        qf.selectField( 'name' ).selectField( 'Id' ).setCondition( 'LastName = :CONTACT_LAST_NAME' ).addOrdering( 'CreatedDate', fflib_QueryFactory.SortOrder.DESCENDING, true );
        // Explicitly assert object accessibility when creating the subselect
        qf.subselectQuery( 'Tasks' ).selectField( 'Id' ).selectField( 'Subject' ).setCondition( ' IsDeleted = false ' );

        // When - perform test
        List<fflib_QueryFactory> queries = qf.getSubselectQueries();

        // Then - validate
        System.Assert.isNotNull( queries );
        System.Assert.isTrue(
            Pattern.matches( 'SELECT.*(SELECT.*FROM Tasks WHERE.*).*FROM Contact WHERE.*', qf.toSOQL() ),
            'Incorrect returned query'
        );
    }

    @IsTest
    private static void addChildQueriesWithChildRelationshipObjCheckIsAccessible_success(){
        // Given - create data
        fflib_QueryFactory qf = new fflib_QueryFactory( Contact.SObjectType );
        qf.selectField( 'name' ).selectField( 'Id' ).setCondition( 'LastName = :CONTACT_LAST_NAME' ).addOrdering( 'CreatedDate', fflib_QueryFactory.SortOrder.DESCENDING, true );
        Schema.DescribeSObjectResult descResult = Contact.SObjectType.getDescribe();
        Schema.ChildRelationship relationship;
        for( Schema.ChildRelationship childRow : descResult.getChildRelationships() ){
            // Occasionally on some standard objects (Like Contact child of Contact) do not have a relationship name.
            // If there is no relationship name, we cannot query on it, so throw an exception.
            if( childRow.getRelationshipName() == 'Tasks' ){
                relationship = childRow;
            }
        }
        // Explicitly assert object accessibility when creating the subselect
        qf.subselectQuery( relationship, true ).selectField( 'Id' ).selectField( 'Subject' )
            .setCondition( ' IsDeleted = false ' );

        // When - perform test
        List<fflib_QueryFactory> queries = qf.getSubselectQueries();

        // Then - validate
        System.Assert.isNotNull( queries );
        System.Assert.isTrue(
            Pattern.matches( 'SELECT.*(SELECT.*FROM Tasks WHERE.*).*FROM Contact WHERE.*', qf.toSOQL() ),
            'Incorrect returned query'
        );
    }

    @IsTest
    private static void addChildQueriesWithChildRelationshipObj_success(){
        // Given - create data
        fflib_QueryFactory qf = new fflib_QueryFactory( Contact.SObjectType );
        qf.selectField( 'name' ).selectField( 'Id' ).setCondition( 'LastName = :CONTACT_LAST_NAME' ).addOrdering( 'CreatedDate', fflib_QueryFactory.SortOrder.DESCENDING, true );
        Schema.DescribeSObjectResult descResult = Contact.SObjectType.getDescribe();
        Schema.ChildRelationship relationship;
        for( Schema.ChildRelationship childRow : descResult.getChildRelationships() ){
            // Occasionally on some standard objects (Like Contact child of Contact) do not have a relationship name.
            //If there is no relationship name, we cannot query on it, so throw an exception.
            if( childRow.getRelationshipName() == 'Tasks' ){
                relationship = childRow;
            }
        }

        // Explicitly assert object accessibility when creating the subselect
        qf.subselectQuery( relationship ).selectField( 'Id' ).selectField( 'Subject' ).setCondition( ' IsDeleted = false ' );

        // When - perform test
        List<fflib_QueryFactory> queries = qf.getSubselectQueries();

        // Then - validate
        System.Assert.isNotNull( queries );
        System.Assert.isTrue(
            Pattern.matches( 'SELECT.*(SELECT.*FROM Tasks WHERE.*).*FROM Contact WHERE.*', qf.toSOQL() ),
            'Incorrect returned query'
        );
    }

    @IsTest
    private static void addChildQueriesWithChildRelationshipNoAccessibleCheck_fail(){
        // Given - create data
        fflib_QueryFactory qf = new fflib_QueryFactory( Contact.SObjectType );
        qf.selectField( 'name' ).selectField( 'Id' ).setCondition( 'name like \'%test%\'' ).addOrdering( 'CreatedDate', fflib_QueryFactory.SortOrder.DESCENDING, true );
        Schema.DescribeSObjectResult descResult = Contact.SObjectType.getDescribe();
        // Explicitly assert object accessibility when creating the subselect
        Exception e;

        // When - perform test
        try{
            qf.subselectQuery( 'Tas' ).selectField( 'Id' ).selectField( 'Subject' )
                .setCondition( ' IsDeleted = false ' );
        } catch( fflib_QueryFactory.InvalidSubqueryRelationshipException ex ){
            e = ex;
        }

        // Then - validate
        System.Assert.areNotEqual( e, null );
    }

    @IsTest
    private static void addChildQueries_success(){
        // Given - create data
        fflib_QueryFactory qf = new fflib_QueryFactory( Contact.SObjectType );
        qf.selectField( 'name' ).selectField( 'Id' ).setCondition( 'LastName = :CONTACT_LAST_NAME' ).addOrdering( 'CreatedDate', fflib_QueryFactory.SortOrder.DESCENDING, true );
        Schema.DescribeSObjectResult descResult = Contact.SObjectType.getDescribe();
        // Explicitly assert object accessibility when creating the subselect
        qf.subselectQuery( Task.SObjectType, true ).selectField( 'Id' ).selectField( 'Subject' ).setCondition( ' IsDeleted = false ' );

        // When - perform test
        List<fflib_QueryFactory> queries = qf.getSubselectQueries();

        // Then - validate
        System.Assert.isNotNull( queries );
        System.Assert.isTrue(
            Pattern.matches( 'SELECT.*(SELECT.*FROM Tasks WHERE.*).*FROM Contact WHERE.*', qf.toSOQL() ),
            'Incorrect returned query'
        );
    }

    @IsTest
    private static void addChildQuerySameRelationshipAgain_success(){
        // Given - create data
        fflib_QueryFactory qf = new fflib_QueryFactory( Contact.SObjectType );

        // When - perform test
        qf.selectField( 'name' );
        qf.selectField( 'Id' );
        qf.setCondition( 'name like \'%test%\'' );
        qf.addOrdering( new fflib_QueryFactory.Ordering( 'Contact', 'name', fflib_QueryFactory.SortOrder.ASCENDING ) )
            .addOrdering( 'CreatedBy.Name', fflib_QueryFactory.SortOrder.DESCENDING );
        Schema.DescribeSObjectResult descResult = Contact.SObjectType.getDescribe();
        ChildRelationship relationship;
        for( Schema.ChildRelationship childRow : descResult.getChildRelationships() ){
            if( childRow.getRelationshipName() == 'Tasks' ){
                relationship = childRow;
            }
        }

        // Then - validate
        System.Assert.isTrue( qf.getSubselectQueries() == null );
        fflib_QueryFactory childQf = qf.subselectQuery( Task.SObjectType );
        childQf.assertIsAccessible();
        childQf.setEnforceFLS( true );
        childQf.selectField( 'Id' );

        fflib_QueryFactory childQf2 = qf.subselectQuery( Task.SObjectType );
        List<fflib_QueryFactory> queries = qf.getSubselectQueries();
        System.Assert.isTrue( queries != null );
        System.Assert.isTrue( queries.size() == 1 );
    }

    @IsTest
    private static void addChildQueries_invalidChildRelationship(){
        // Given - create data
        fflib_QueryFactory qf = new fflib_QueryFactory( Contact.SObjectType );
        qf.selectField( 'name' );
        qf.selectField( 'email' );
        qf.setCondition( 'name like \'%test%\'' );
        qf.addOrdering( new fflib_QueryFactory.Ordering( 'Contact', 'name', fflib_QueryFactory.SortOrder.ASCENDING ) )
            .addOrdering( 'CreatedDATE', fflib_QueryFactory.SortOrder.DESCENDING );
        Schema.DescribeSObjectResult descResult = Account.SObjectType.getDescribe();
        Exception e;

        // When - perform test
        try{
            SObjectType invalidType = null;
            fflib_QueryFactory childQf = qf.subselectQuery( invalidType );
            childQf.selectField( 'Id' );
        } catch( fflib_QueryFactory.InvalidSubqueryRelationshipException ex ){
            e = ex;
        }

        // Then - validate
        System.Assert.areNotEqual( e, null );
    }

    @IsTest
    private static void addChildQueries_inheritFLSEnforcementFromParentFactory(){
        // Given - create data
        fflib_QueryFactory qf = new fflib_QueryFactory( Contact.SObjectType );
        qf.selectField( Contact.Name )
            .setEnforceFLS( true )
            .subselectQuery( Task.SObjectType );

        // When - perform test
        List<fflib_QueryFactory> queries = qf.getSubselectQueries();

        // Then - validate
        System.Assert.isTrue( queries.size() == 1 );
        System.Assert.areEqual( qf.mFlsEnforcement, queries[ 0 ].mFlsEnforcement, 'Expected child query to have the same FLS enforcement as the parent query' );

        // Explicitly set it to false
        qf.setEnforceFLS( false )
            .subselectQuery( ActivityHistory.SObjectType );

        // When - perform test
        queries = qf.getSubselectQueries();

        // Then - validate
        System.Assert.isTrue( queries.size() == 2 );
        System.Assert.areEqual( qf.mFlsEnforcement, queries[ 0 ].mFlsEnforcement, 'Expected child query to have the same FLS enforcement as the parent query' );
        System.Assert.areEqual( qf.mFlsEnforcement, queries[ 1 ].mFlsEnforcement, 'Expected child query to have the same FLS enforcement as the parent query' );
    }

    @IsTest
    private static void checkFieldObjectReadSort_success(){
        // Given - create data
        fflib_QueryFactory qf = new fflib_QueryFactory( Contact.SObjectType );
        qf.assertIsAccessible()
            .setEnforceFLS( true )
            .selectField( 'createdby.name' )
            .selectField( Contact.LastModifiedById )
            .selectFields( new List<SObjectField>{ Contact.LastModifiedDate } )
            .setEnforceFLS( false )
            .selectField( Contact.LastName )
            .selectFields( new List<SObjectField>{ Contact.Id } )
            .setCondition( 'name like \'%test%\'' )
            .setEnforceFLS( true )
            .selectFields( new Set<SObjectField>{ Contact.FirstName } )
            .addOrdering( new fflib_QueryFactory.Ordering( 'Contact', 'name', fflib_QueryFactory.SortOrder.ASCENDING ) )
            .addOrdering( Contact.LastModifiedDate, fflib_QueryFactory.SortOrder.DESCENDING )
            .addOrdering( Contact.CreatedDate, fflib_QueryFactory.SortOrder.DESCENDING, true );
        Set<String> fields = qf.getSelectedFields();

        // When - perform test
        fflib_QueryFactory.Ordering ordering = new fflib_QueryFactory.Ordering( 'Contact', 'name', fflib_QueryFactory.SortOrder.ASCENDING );

        // Then - validate
        System.Assert.areEqual( 'Name', ordering.getField() );

        System.Assert.areEqual(
            new Set<String>{
                'CreatedBy.Name',
                'LastModifiedById',
                'LastModifiedDate',
                'LastName',
                'Id',
                'FirstName'
            },
            fields );

        System.Assert.isTrue( qf.toSOQL().containsIgnoreCase( 'NULLS LAST' ) );
    }

    @IsTest
    private static void checkObjectRead_fail(){
        // Given - create data
        User usr = createTestUser_noAccess();
        if( usr != null ){
            // When - perform test
            System.runAs( usr ){
                // Create a query factory object for Account.
                fflib_QueryFactory qf = new fflib_QueryFactory( Account.SObjectType );
                Boolean excThrown = false;
                try{
                    // Check to see if this record is accessible, it isn't.
                    qf.assertIsAccessible();
                } catch( fflib_SecurityUtils.CrudException e ){
                    excThrown = true;
                }

                // Then - validate
                System.Assert.isTrue( excThrown );
            }
        }
    }

    @IsTest
    private static void checkFieldRead_fail(){
        // Given - create data
        User usr = createTestUser_noAccess();
        if( usr != null ){
            // When - perform test
            System.runAs( usr ){
                //create a query factory object for Account.
                fflib_QueryFactory qf = new fflib_QueryFactory( Account.SObjectType );
                Boolean excThrown = false;
                try{
                    // Set field to enforce FLS, then try to add a field.
                    qf.setEnforceFLS( true );
                    qf.selectField( 'Name' );
                } catch( fflib_SecurityUtils.FlsException e ){
                    excThrown = true;
                }
                // Then - validate
                System.Assert.isTrue( excThrown );
            }
        }
    }

    @IsTest
    private static void queryWith_noFields(){
        // Given - create data
        fflib_QueryFactory qf = new fflib_QueryFactory( Contact.SObjectType );

        // When - perform test
        qf.assertIsAccessible().setEnforceFLS( true ).setCondition( 'name like \'%test%\'' ).addOrdering( 'CreatedDate', fflib_QueryFactory.SortOrder.DESCENDING );
        String query = qf.toSOQL();

        // Then - validate
        System.Assert.isTrue( query.containsIgnoreCase( 'SELECT Id FROM Contact' ), 'Expected \'SELECT Id FROM Contact\' in the SOQL, found: ' + query );
    }

    @IsTest
    private static void deterministic_toSOQL(){
        // Given - create data
        fflib_QueryFactory qf1 = new fflib_QueryFactory( User.SObjectType );
        fflib_QueryFactory qf2 = new fflib_QueryFactory( User.SObjectType );

        // When - perform test
        for( fflib_QueryFactory qf : new Set<fflib_QueryFactory>{ qf1, qf2 } ){
            qf.selectFields( new List<String>{
                'Id',
                'FirstName',
                'LastName',
                'CreatedBy.Name',
                'CreatedBy.Manager',
                'LastModifiedBy.Email'
            } );
        }
        String expectedQuery =
            'SELECT createdby.manager, createdby.name, '
            + 'firstname, id, lastmodifiedby.email, lastname '
            + 'FROM User';

        // Then - validate
        System.Assert.areEqual( qf1.toSOQL(), qf2.toSOQL() );
        System.Assert.areEqual( expectedQuery, qf1.toSOQL() );
        System.Assert.areEqual( expectedQuery, qf2.toSOQL() );
    }

    @IsTest
    private static void deepCloneBasicNoChanges(){
        // Given - create data
        fflib_QueryFactory qf = new fflib_QueryFactory( Contact.SObjectType )
            .setLimit( 10 )
            .setCondition( 'id=12345' )
            .selectField( 'Description' )
            .addOrdering( new fflib_QueryFactory.Ordering( 'Contact', 'name', fflib_QueryFactory.SortOrder.ASCENDING ) )
            .addOrdering( new fflib_QueryFactory.Ordering( 'Contact', 'CreatedDATE', fflib_QueryFactory.SortOrder.DESCENDING ) )
            .setEnforceFLS( true );

        // When - perform test
        fflib_QueryFactory qf2 = qf.deepClone();

        // Then - validate
        System.Assert.areEqual( qf2, qf );

        System.Assert.areEqual( qf.getLimit(), qf2.getLimit() );
        System.Assert.areEqual( qf.getCondition(), qf2.getCondition() );
        System.Assert.areEqual( qf.toSOQL(), qf2.toSOQL() );
        System.Assert.areEqual( qf.getOrderings(), qf2.getOrderings() );
    }

    @IsTest
    private static void aggregateCountFunctionShouldBeSelected(){
        // Given, When - legacy construct with REGEX validation (to cover no field within SOQL function logic)
        fflib_QueryFactory qf = new fflib_QueryFactory( User.SObjectType ).setEnforceFLS( fflib_QueryFactory.FLSEnforcement.LEGACY )
            .selectField( 'COUNT()' );

        // Then - validate
        System.Assert.areEqual( 'SELECT COUNT() FROM User', qf.toSOQL(), 'Expected uppercase COUNT() since legacy FLSEnforcement' );
    }

    @IsTest
    private static void aggregateToLabelFunctionShouldBeSelected(){
        // Given, When
        fflib_QueryFactory qf = new fflib_QueryFactory( User.SObjectType ).selectField( 'TOLABEL(LanguageLocaleKey)' );

        // Then - validate
        System.Assert.areEqual( 'SELECT tolabel(languagelocalekey) FROM User', qf.toSOQL(), 'Expected lowercase given no legacy enforceCRUD nor FLSEnforcement' );
    }

    @IsTest
    private static void aggregateAliasCountFunctionShouldBeSelected(){
        // Given, When
        fflib_QueryFactory qf = new fflib_QueryFactory( User.SObjectType ).selectField( 'COUNT() total' );

        // Then - validate
        System.Assert.areEqual( 'SELECT count() total FROM User', qf.toSOQL() );
    }

    @IsTest
    private static void deepCloneSubqueryNoChanges(){
        // Given - create data
        fflib_QueryFactory qf = new fflib_QueryFactory( Account.SObjectType )
            .setLimit( 10 )
            .setCondition( 'id=12345' )
            .selectField( 'Description' )
            .addOrdering( new fflib_QueryFactory.Ordering( 'Account', 'Name', fflib_QueryFactory.SortOrder.ASCENDING ) )
            .addOrdering( new fflib_QueryFactory.Ordering( 'Account', 'Description', fflib_QueryFactory.SortOrder.DESCENDING ) )
            .setEnforceFLS( true );

        // When - perform test
        qf.subselectQuery( 'Contacts', true );

        fflib_QueryFactory qf2 = qf.deepClone();

        // Then - validate
        System.Assert.areEqual( qf, qf2 );

        System.Assert.areEqual( qf.getLimit(), qf2.getLimit() );
        System.Assert.areEqual( qf.getCondition(), qf2.getCondition() );
        System.Assert.areEqual( qf.toSOQL(), qf2.toSOQL() );
        System.Assert.areEqual( qf.getOrderings(), qf2.getOrderings() );
        System.Assert.areEqual( qf.getSubselectQueries(), qf2.getSubselectQueries() );
    }

    @IsTest
    private static void deepCloneBasic(){
        // Given - create data
        fflib_QueryFactory qf = new fflib_QueryFactory( Contact.SObjectType )
            .setLimit( 10 )
            .setCondition( 'id=12345' )
            .setOffset( 2 )
            .selectField( 'Description' )
            .setAllRowsRequired( true )
            .setGroupByFieldName( 'Description' )
            .addOrdering( new fflib_QueryFactory.Ordering( 'Contact', 'name', fflib_QueryFactory.SortOrder.ASCENDING ) )
            .addOrdering( new fflib_QueryFactory.Ordering( 'Contact', 'CreatedDATE', fflib_QueryFactory.SortOrder.DESCENDING ) )
            .setEnforceFLS( true );

        // When - perform test
        fflib_QueryFactory qf2 = qf.deepClone()
            .setLimit( 200 )
            .setOffset( 1 )
            .setAllRowsRequired( false )
            .setCondition( 'id=54321' )
            .selectField( 'Fax' )
            .setGroupByFieldName( 'Fax', true ) // preserve ordering of cloned QueryFactory
            .addOrdering( new fflib_QueryFactory.Ordering( 'Contact', 'Fax', fflib_QueryFactory.SortOrder.ASCENDING ) )
            .setEnforceFLS( false );

        qf2.getOrderings().remove( 0 );

        // Then - validate
        System.Assert.areEqual( 10, qf.getLimit() );
        System.Assert.areEqual( 200, qf2.getLimit() );

        System.Assert.areEqual( 'id=12345', qf.getCondition() );
        System.Assert.areEqual( 'id=54321', qf2.getCondition() );

        System.Assert.areEqual( 2, qf.getOffset() );
        System.Assert.areEqual( 1, qf2.getOffset() );

        System.Assert.isTrue( qf.getAllRowsRequired() );
        System.Assert.isFalse( qf2.getAllRowsRequired() );

        System.Assert.areEqual( 'Description', qf.getGroupByFieldName() );
        System.Assert.areEqual( 'Fax', qf2.getGroupByFieldName() );

        String query = qf.toSOQL();
        String query2 = qf2.toSOQL();

        System.Assert.isTrue( query.containsIgnoreCase( 'Fax' ) == false );
        System.Assert.isTrue( query.containsIgnoreCase( 'Description' ) );
        System.Assert.isTrue( query2.containsIgnoreCase( 'Description' ) );
        System.Assert.isTrue( query2.containsIgnoreCase( 'Fax' ) );

        System.Assert.areEqual( 2, qf.getOrderings().size() );
        System.Assert.areEqual( 'Name', qf.getOrderings()[ 0 ].getField() );
        System.Assert.areEqual( fflib_QueryFactory.SortOrder.DESCENDING, qf.getOrderings()[ 1 ].getDirection() );

        System.Assert.areEqual( 2, qf2.getOrderings().size() );
        System.Assert.areEqual( 'Fax', qf2.getOrderings()[ 1 ].getField() );
        System.Assert.areEqual( fflib_QueryFactory.SortOrder.ASCENDING, qf2.getOrderings()[ 1 ].getDirection() );
    }

    @IsTest
    private static void deepCloneSubQuery(){
        // Given - create data
        fflib_QueryFactory qf = new fflib_QueryFactory( Account.SObjectType );
        qf.subselectQuery( 'Contacts', true );

        // When - perform test
        fflib_QueryFactory qf2 = qf.deepClone();
        qf2.subselectQuery( 'Opportunities', true );

        List<fflib_QueryFactory> subqueries = qf.getSubselectQueries();
        List<fflib_QueryFactory> subqueries2 = qf2.getSubselectQueries();

        fflib_QueryFactory subquery2_0 = subqueries2.get( 0 );

        subquery2_0.addOrdering( new fflib_QueryFactory.Ordering( 'Contact', 'Name', fflib_QueryFactory.SortOrder.ASCENDING ) );

        // Then - validate
        System.Assert.isTrue( subqueries.size() == 1 );
        System.Assert.isTrue( subqueries2.size() == 2 );

        System.Assert.isTrue( qf.getSubselectQueries().get( 0 ).getOrderings().size() == 0 );
        System.Assert.isTrue( qf2.getSubselectQueries().get( 0 ).getOrderings().size() == 1 );
    }

    @IsTest
    private static void testToSOQL_unsortedSelectFields(){
        // Given - create data
        fflib_QueryFactory qf = new fflib_QueryFactory( User.SObjectType );
        qf.selectFields( new List<String>{
            'Id',
            'FirstName',
            'LastName',
            'CreatedBy.Name',
            'CreatedBy.Manager',
            'LastModifiedBy.Email'
        } );

        // When - perform test
        qf.setSortSelectFields( false );

        String orderedQuery =
            'SELECT '
            + 'FirstName, Id, LastName, ' // Less joins come first, alphabetically
            + 'CreatedBy.ManagerId, CreatedBy.Name, LastModifiedBy.Email ' // Alphabetical on the same number of joins'
            + 'FROM User';

        String actualSoql = qf.toSOQL();

        // Then - validate
        System.Assert.areNotEqual( orderedQuery, actualSoql );
    }

    @IsTest
    private static void setGroupByField_resetOrdering(){
        // Given - create data
        fflib_QueryFactory qf = new fflib_QueryFactory( User.SObjectType );
        qf.addOrdering( new fflib_QueryFactory.Ordering( User.Name, fflib_QueryFactory.SortOrder.ASCENDING ) );
        
        // When - perform test
        qf.setGroupByField( User.ProfileId );

        // Then - validate
        System.Assert.areEqual( qf.getOrderings().size(), 0, 'Expected orderings to be cleared when group by field is set.' );
    }

    @IsTest
    private static void setGroupByField_preserveOrdering(){
        // Given - create data
        fflib_QueryFactory qf = new fflib_QueryFactory( User.SObjectType );
        qf.addOrdering( new fflib_QueryFactory.Ordering( User.Name, fflib_QueryFactory.SortOrder.ASCENDING ) );
        
        // When - perform test
        qf.setGroupByField( User.ProfileId, true );

        // Then - validate
        System.Assert.areEqual( qf.getOrderings().size(), 1, 'Expected orderings to be preserved when group by field is set with preserveOrderings=true.' );
    }

    @IsTest
    private static void setGroupByFieldName_resetOrdering(){
        // Given - create data
        fflib_QueryFactory qf = new fflib_QueryFactory( User.SObjectType );
        qf.addOrdering( new fflib_QueryFactory.Ordering( User.Name, fflib_QueryFactory.SortOrder.ASCENDING ) );
        
        // When - perform test, with preserve orderings default to false
        qf.setGroupByFieldName( 'ProfileId' );

        // Then - validate
        System.Assert.areEqual( qf.getOrderings().size(), 0, 'Expected orderings to be cleared when group by field is set.' );
    }

    @IsTest
    private static void setGroupByFieldName_preserveOrdering(){
        // Given - create data
        fflib_QueryFactory qf = new fflib_QueryFactory( User.SObjectType );
        qf.addOrdering( new fflib_QueryFactory.Ordering( User.Name, fflib_QueryFactory.SortOrder.ASCENDING ) );
        
        // When - perform test, with preserve orderings default to false
        qf.setGroupByFieldName( 'ProfileId', true );

        // Then - validate
        System.Assert.areEqual( qf.getOrderings().size(), 1, 'Expected orderings to be preserved when group by field is set with preserveOrderings=true.' );
    }

    @IsTest
    private static void setHaving_testSettingSOQLClause(){
        // Given - create data
        fflib_QueryFactory qf = new fflib_QueryFactory( Contact.SObjectType );
        qf.setGroupByFieldName( 'Name' );

        // When - perform test
        qf.setHaving( 'COUNT(Id) > 1' );
        String query = qf.toSOQL();

        // Then
        System.Assert.isTrue( query.contains( 'HAVING COUNT(Id) > 1' ), 'Query should contain the HAVING clause.' );
        System.Assert.isTrue( query.indexOf( 'GROUP BY' ) < query.indexOf( 'HAVING' ), 'GROUP BY must precede HAVING.' );
    }

    @IsTest
    private static void setHaving_testSequenceOfSOQLClauseOrdering(){
        // Given - create data
        fflib_QueryFactory qf = new fflib_QueryFactory( Contact.SObjectType );
        qf.setGroupByFieldName( 'Name' );
        qf.setHaving( 'COUNT(Id) > 5' );
        qf.setLimit( 10 );

        // When - perform test
        String query = qf.toSOQL();

        // Then - Verify sequence using string index positions. Order: GROUP BY -> HAVING -> LIMIT
        Integer groupPos = query.indexOf( 'GROUP BY' );
        Integer havingPos = query.indexOf( 'HAVING' );
        Integer limitPos = query.indexOf( 'LIMIT' );

        System.Assert.isTrue( groupPos < havingPos, 'GROUP BY must be before HAVING' );
        System.Assert.isTrue( havingPos < limitPos, 'HAVING must be before LIMIT' );
    }

    @IsTest
    private static void setHaving_testAbsenceOfGROUPBYClause(){
        // Given - create data
        fflib_QueryFactory qf = new fflib_QueryFactory( Contact.SObjectType );
        qf.setHaving( 'COUNT(Id) > 1' );

        // Then - Validate that HAVING clause when no GROUP BY is present prevents invalid SOQL, with a runtime exception indicating the issue
        try{
            qf.toSOQL();
            System.Assert.fail( 'Expected an exception to be thrown when a \'HAVING\' clause is set without a \'GROUP BY\' clause.' );
        } catch( fflib.InvalidImplementationException ex ){
            // Then - validate
            System.Assert.isTrue( ex.getMessage()
                .contains( 'A \'HAVING\' clause was set on this query without a \'GROUP BY\' clause. Please set a \'GROUP BY\' clause for the \'HAVING\' clause to be valid.' ),
                'Expected error message about \'HAVING\' clause set without a \'GROUP BY\' clause.' );
        }
    }

    @IsTest
    private static void setForView_testSettingSOQLClause(){
        // Given - create data
        fflib_QueryFactory qf = new fflib_QueryFactory( Contact.SObjectType );

        // Then - validate that FOR VIEW is not included by default
        String query = qf.toSOQL();
        System.Assert.isTrue( !query.endsWith( 'FOR VIEW' ), 'The query string should not include the FOR VIEW clause.' );

        // When - perform test
        qf.setForView( true );
        query = qf.toSOQL();

        // Then - validate
        System.Assert.isTrue( query.endsWith( 'FOR VIEW' ), 'The query string must end with the FOR VIEW clause.' );
    }

    @IsTest
    private static void setForReference_testSettingSOQLClause(){
        // Given - create data
        fflib_QueryFactory qf = new fflib_QueryFactory( Contact.SObjectType );

        // Then - validate that FOR REFERENCE is not included by default
        String query = qf.toSOQL();
        System.Assert.isTrue( !query.endsWith( 'FOR REFERENCE' ), 'The query string should not include the FOR REFERENCE clause.' );

        // When - perform test
        qf.setForReference( true );
        query = qf.toSOQL();

        // Then - validate
        System.Assert.isTrue( query.endsWith( 'FOR REFERENCE' ), 'The query string must end with the FOR REFERENCE clause.' );
    }

    @IsTest
    private static void setForUpdate_testSettingSOQLClause(){
        // Given - create data
        fflib_QueryFactory qf = new fflib_QueryFactory( Contact.SObjectType );

        // Then - validate that FOR VIEW is not included by default
        String query = qf.toSOQL();
        System.Assert.isTrue( !query.endsWith( 'FOR UPDATE' ), 'The query string should not include the FOR UPDATE clause.' );

        // When - perform test
        qf.setForUpdate( true );
        query = qf.toSOQL();

        // Then - validate
        System.Assert.isTrue( query.endsWith( 'FOR UPDATE' ), 'The query string must end with the FOR UPDATE clause.' );
    }

    @IsTest
    private static void setForClause_exceptionThrownBothFORClausesSet(){
        // Given - create data
        fflib_QueryFactory qf = new fflib_QueryFactory( Contact.SObjectType );

        // When - perform test
        qf.setForReference( true ).setForView( true );

        try{
            qf.toSOQL();
            System.Assert.fail( 'Expected an exception to be thrown when both FOR VIEW and FOR REFERENCE clauses are set.' );
        } catch( fflib.InvalidImplementationException ex ){
            // Then - validate
            System.Assert.isTrue( ex.getMessage()
                .contains( 'A query cannot be set to use both FOR VIEW and FOR REFERENCE clauses. Please choose one or the other.' ), 'Expected error message about mutually exclusive FOR clauses.' );
        }
    }

    @IsTest
    private static void setForClause_testToSOQLClauseOrdering(){
        // Given - Test to ensure specific SOQL syntax order (LIMIT -> ALL ROWS -> FOR- clauses)
        fflib_QueryFactory qf = new fflib_QueryFactory( Contact.SObjectType );
        qf.setLimit( 1 ).setAllRowsRequired( true ).setForReference( true ).setForUpdate( true );

        // When - perform test
        String query = qf.toSOQL();

        // Verify sequence using string index positions
        Integer limitPos = query.indexOf( 'LIMIT' );
        Integer allRowsPos = query.indexOf( 'ALL ROWS' );
        Integer forReferencePos = query.indexOf( 'FOR REFERENCE' );
        Integer forUpdatePos = query.indexOf( 'FOR UPDATE' );

        System.Assert.isTrue( limitPos < allRowsPos, 'LIMIT must precede ALL ROWS' );
        System.Assert.isTrue( allRowsPos < forReferencePos, 'ALL ROWS must precede FOR REFERENCE' );
        System.Assert.isTrue( forReferencePos < forUpdatePos, 'FOR REFERENCE must precede FOR UPDATE' );
    }

    /**
     * Utility test methods
     */

    /**
     * @return  Returns test user record without access.
     */
    private static User createTestUser_noAccess(){
        User usr;
        try{
            // Look for a profile that does not have access to the Account object
            PermissionSet ps = [
                SELECT Profile.Id, Profile.Name
                FROM PermissionSet
                WHERE IsOwnedByProfile = TRUE
                AND Profile.UserType = 'Standard'
                AND Id NOT IN (
                    SELECT ParentId
                    FROM ObjectPermissions
                    WHERE SobjectType = 'Account'
                    AND PermissionsRead = TRUE
                )
                LIMIT 1
            ];

            if( ps != null ){
                // Create a user with the profile found that doesn't have access to the Account object
                usr = new User(
                    FirstName = 'testUsrF',
                    LastName = 'testUsrL',
                    Alias = 'tstUsr',
                    Email = 'testy.test@test.com',
                    Username = 'test' + Math.random().format() + 'user99@test.com',
                    EmailEncodingKey = 'ISO-8859-1',
                    LanguageLocaleKey = 'en_US',
                    TimeZoneSidKey = 'America/Los_Angeles',
                    LocaleSidKey = 'en_US',
                    ProfileId = ps.Profile.Id,
                    IsActive = true
                );
                insert usr;
            }
        } catch( Exception e ){
            // Nothing to do, just return null, since this test case won't work for this particular org
            return null;
        }
        return usr;
    }
}
