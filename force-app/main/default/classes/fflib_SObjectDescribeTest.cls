/**
 * Copyright (c), FinancialForce.com, inc
 * Copyright (c), Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
/**
 * This class adapted from https://github.com/capeterson/Apex-Util
 * Used under a BSD license: https://github.com/capeterson/Apex-Util/blob/master/LICENSE
 */
@IsTest( isParallel = true )
private with sharing class fflib_SObjectDescribeTest{
    @IsTest
    private static void constructor(){
        try{
            new fflib_SObjectDescribe( null );
            System.Assert.fail( 'Expected InvalidDescribeException for null SObjectType' );
        } catch( fflib_SObjectDescribe.InvalidDescribeException ex ){
            System.Assert.areEqual( 'Invalid SObject type: null', ex.getMessage(), 'Expected other Exception message' );
        }

        fflib_SObjectDescribe descr = new fflib_SObjectDescribe( Account.SObjectType );
        System.Assert.areEqual( Account.SObjectType, descr.token, 'Expected token to be set by constructor' );
    }

    /**
     * Verify that the different ways of getting your hands on an fflib_SObjectDescribe instance all handle null inputs
     * (and blank/empty strings, why not?) by returning null - since there's no possible way to resolve it.
     */
    @IsTest
    private static void getDescribe_badInput(){
        String nullStr = null; // Having it as a string var makes for unambiguous selection of overloads
        Schema.SObjectType nullType = null;
        Schema.DescribeSObjectResult nullDescribe = null;
        SObject nullSObject = null;
        System.Assert.isNull( fflib_SObjectDescribe.getDescribe( nullStr ) );
        System.Assert.isNull( fflib_SObjectDescribe.getDescribe( '' ) );
        System.Assert.isNull( fflib_SObjectDescribe.getDescribe( ' ' ) );
        System.Assert.isNull( fflib_SObjectDescribe.getDescribe( nullType ) );
        System.Assert.isNull( fflib_SObjectDescribe.getDescribe( nullDescribe ) );
        System.Assert.isNull( fflib_SObjectDescribe.getDescribe( nullSObject ) );
    }

    @IsTest
    private static void namespacedAttributeMap_implementations(){
        fflib_SObjectDescribe.GlobalDescribeMap gdm = fflib_SObjectDescribe.getGlobalDescribe();
        Schema.SObjectType accountObjType = gdm.get( 'AccOunT' );
        System.Assert.areEqual( accountObjType, Account.SObjectType );
        Map<String, SObjectType> globalDescribe = Schema.getGlobalDescribe();
        System.Assert.isTrue( globalDescribe.keySet().containsAll( gdm.keySet() ) );
        Integer index = Math.min( 3, globalDescribe.size() - 1 ); // Select an index, while satisfying potentially smaller orgs
        System.Assert.areEqual( globalDescribe.values()[ index ], gdm.values()[ index ], 'Expected same order in GlobalDescribeMap' );

        fflib_SObjectDescribe acccountDescribe = fflib_SObjectDescribe.getDescribe( accountObjType );
        fflib_SObjectDescribe.FieldsMap fields = acccountDescribe.getFields();
        System.Assert.isTrue( fields.keySet().containsAll( acccountDescribe.getFieldsMap().keySet() ) );

        System.Assert.areEqual( fields.get( 'name' ), Account.SObjectType.fields.name ); // Behavior of FieldsMap is tested in another method
        System.Assert.areEqual( Schema.SObjectType.Account.fields.getMap().size(), fields.size() );

        System.Assert.isNull( fields.get( null ), 'Null input should result in null ouput.' );
        System.Assert.isNull( fields.get( '' ), 'Invalid fieldname input should result in null ouput.' );
    }

    @IsTest
    private static void fieldsMap(){
        String fakeNamespace = 'fflib_test';
        Map<String, Schema.SObjectField> fakeFieldData = new Map<String, Schema.SObjectField>{
            'name__c' => Contact.SObjectType.fields.name, // Re-use standard field types since we can't mock them
            fakeNamespace + '__name__c' => Account.SObjectType.fields.Name,
            fakeNamespace + '__otherField__c' => Account.SObjectType.fields.Name,
            'createddate' => Contact.SObjectType.fields.CreatedDate
        };
        fflib_SObjectDescribe.FieldsMap fields = new fflib_SObjectDescribe.FieldsMap( fakeFieldData );
        fields.currentNamespace = fakeNamespace;
        System.Assert.isTrue( fields.containsKey( 'name__c' ) );
        System.Assert.isTrue( fields.containsKey( fakeNamespace.toUpperCase() + '__nAMe__c' ) );
        System.Assert.isTrue( fields.get( 'NAme__c' ) === fields.get( fakeNamespace + '__namE__c' ) );

        System.Assert.isFalse( fields.keySet( false ).contains( 'otherField__c' ) );
        System.Assert.isTrue( fields.keySet( false ).contains( fakeNamespace + '__otherField__c' ) );

        System.Assert.isTrue( fields.keySet( true ).contains( 'otherField__c' ) );
        System.Assert.isFalse( fields.keySet( true ).contains( fakeNamespace + '__otherField__c' ) );

        fields.currentNamespace = 'otherNamespace';
        System.Assert.areNotEqual( fields.get( 'name__C' ), fields.get( fakeNamespace.capitalize() + '__nAme__c' ) );
    }

    @IsTest
    private static void globalDescribeMap(){
        String fakeNamespace = 'fflib_test';
        Map<String, Schema.SObjectType> fakeFieldData = new Map<String, Schema.SObjectType>{
            'name__c' => Contact.SObjectType, // Re-use stndard object types since we can't mock them
            fakeNamespace + '__name__c' => Account.SObjectType,
            'createddate' => Lead.SObjectType
        };
        fflib_SObjectDescribe.GlobalDescribeMap gdm = new fflib_SObjectDescribe.GlobalDescribeMap( fakeFieldData );
        gdm.currentNamespace = fakeNamespace;
        System.Assert.isTrue( gdm.containsKey( 'name__c' ) );
        System.Assert.isTrue( gdm.containsKey( fakeNamespace + '__name__c' ) );
        System.Assert.isTrue( gdm.get( 'name__c' ) === gdm.get( fakeNamespace + '__name__c' ) );

        gdm.currentNamespace = 'otherNamespace';
        System.Assert.areNotEqual( gdm.get( 'name__c' ), gdm.get( fakeNamespace + '__name__c' ) );
    }

    @IsTest // Tests all forms of the getDescribe static
    static void getAccountDescribes(){
        fflib_SObjectDescribe d = fflib_SObjectDescribe.getDescribe( 'Account' );
        fflib_SObjectDescribe d2 = fflib_SObjectDescribe.getDescribe( Account.SObjectType );
        fflib_SObjectDescribe d3 = fflib_SObjectDescribe.getDescribe( Schema.SObjectType.Account );
        fflib_SObjectDescribe d4 = fflib_SObjectDescribe.getDescribe( Account.SObjectType.getDescribe() );
        fflib_SObjectDescribe d5 = fflib_SObjectDescribe.getDescribe( new Account() );
        System.Assert.areEqual( 'Account', d.getDescribe().getName() );
        System.Assert.areEqual( d, d2, 'Expected getDescribe by String vs. Account.SObjectType to return the same cached instance.' );
        System.Assert.areEqual( d, d3, 'Expected getDescribe by String vs. Schema.SObjectType.Account to return the same cached instance.' );
        System.Assert.areEqual( d, d4, 'Expected getDescribe by String vs. Account.SObjectType.getDescribe() to return the same cached instance.' );
        System.Assert.areEqual( d, d5, 'Expected getDescribe by String vs. new Account() to return the same cached instance.' );
    }

    @IsTest
    private static void simpleAccountFieldDescribe(){
        fflib_SObjectDescribe d = fflib_SObjectDescribe.getDescribe( Account.SObjectType );
        Map<String, Schema.SObjectField> fields = d.getFieldsMap();

        System.Assert.isFalse( fields.isEmpty(), 'Expected non-empty fields Map' );
        System.Assert.areEqual( Account.SObjectType, d.getSObjectType() );
    }

    @IsTest
    private static void simpleAccountFieldSetDescribe(){
        fflib_SObjectDescribe d = fflib_SObjectDescribe.getDescribe( Account.SObjectType );
        Map<String, Schema.FieldSet> fieldSetsMap = d.getFieldSetsMap();

        // Can't really validate whether fieldset is specified for Account, as concerns a project specific test
        System.Assert.isNotNull( fieldSetsMap, 'Expected an initiated fieldsetMap' );
    }

    @IsTest
    private static void simpleAccountGetNameField(){
        fflib_SObjectDescribe d = fflib_SObjectDescribe.getDescribe( Account.SObjectType );
        Schema.SObjectField nameField = d.getNameField();
        System.Assert.areEqual( 'Name', nameField.getDescribe().getName() );

        Schema.SObjectField nameField2 = d.getField( 'Name' );
        System.Assert.areEqual( 'Name', nameField2.getDescribe().getName() );
        System.Assert.areEqual( nameField, nameField2, 'Expected identical namefields to be retrieved' );
    }

    @IsTest
    private static void getField_invalidLookupField(){
        fflib_SObjectDescribe d = fflib_SObjectDescribe.getDescribe( Account.SObjectType );
        Schema.SObjectField fakeField = d.getField( 'FakeLookup__r' );
        System.Assert.isNull( fakeField, 'Expected no field details to be returned' );
    }

    @IsTest
    private static void flushCache(){
        fflib_SObjectDescribe d = fflib_SObjectDescribe.getDescribe( 'Account' );
        fflib_SObjectDescribe.flushCache();
        fflib_SObjectDescribe d2 = fflib_SObjectDescribe.getDescribe( 'Account' );
        System.Assert.isTrue( d !== d2, 'Second object should be a fresh instance after a cache flush.' );
    }

    @IsTest
    private static void rawGlobalDescribeCheck(){
        Map<String, Schema.SObjectType> systemGd = Schema.getGlobalDescribe();
        Map<String, Schema.SObjectType> cachedGd = fflib_SObjectDescribe.getRawGlobalDescribe();
        System.Assert.isTrue( systemGd.keySet().containsAll( cachedGd.keySet() ) );
    }

    @IsTest
    private static void getFieldDescribe_basicsAndCache(){
        Schema.DescribeFieldResult nameDescribe = fflib_SObjectDescribe.getFieldDescribe( Account.Name );
        System.Assert.areEqual( 'Name', nameDescribe.getName(), 'Expected correct field describe to be returned' );

        Schema.DescribeFieldResult nameDescribeRepeat = fflib_SObjectDescribe.getFieldDescribe( Account.Name );
        System.Assert.isTrue( nameDescribe === nameDescribeRepeat, 'Expected cached DescribeFieldResult instance to be returned on repeat calls for the same field' );

        Schema.DescribeFieldResult idDescribe = fflib_SObjectDescribe.getFieldDescribe( Account.Id );
        System.Assert.areEqual( 'Id', idDescribe.getName(), 'Expected correct field describe for a different field on the same SObjectType' );
        System.Assert.isTrue( nameDescribe !== idDescribe, 'Expected different fields to yield different cached DescribeFieldResult instances' );
    }

    @IsTest
    private static void getFieldDescribe_nullInput(){
        System.Assert.isNull( fflib_SObjectDescribe.getFieldDescribe( null ), 'Expected null input to result in null output' );
    }

    @IsTest
    private static void getPicklistValues_validReturn(){
        // Given - create data
        List<Schema.PicklistEntry> pleForSolutionStatusName = Solution.Status.getDescribe().getPicklistValues();

        // When, Then
        List<Schema.PicklistEntry> ple = fflib_SObjectDescribe.getPicklistValues( Solution.Status );
        System.Assert.areEqual( ple.size(), pleForSolutionStatusName.size() );
        System.Assert.areEqual( ple[ 0 ].getLabel(), pleForSolutionStatusName[ 0 ].getLabel() );
    }

    @IsTest
    private static void getPicklistValues_missingInput(){
        // When - perform test
        try{
            fflib_SObjectDescribe.getPicklistValues( null );
            System.Assert.fail( 'This Exception should not be thrown as field-input was empty' );
        } catch( Exception ex ){
            // Then - validate
            System.Assert.isInstanceOfType( ex, dfflib_Utils.InvalidInputValueException.class, 'Expected an dfflib_Utils.InvalidInputValueException, got ' + ex.getTypeName() );
        }
    }

    @IsTest
    private static void getPicklistValues_nonPicklistField(){
        // When, Then - a non-picklist field returns an empty list rather than throwing
        System.Assert.areEqual( new List<Schema.PicklistEntry>(), fflib_SObjectDescribe.getPicklistValues( Solution.SolutionName ), 'Expected an empty list for a non-picklist field' );
    }

    @IsTest
    private static void getPicklistLabels_returnsLabels(){
        // Given - create data
        List<String> picklistLabels = fflib_SObjectDescribe.getPicklistLabels( Solution.Status );

        // When, Then
        System.Assert.isTrue( picklistLabels.contains( 'Draft' ), 'Expected to contain this picklist LABEL value, unmodified (no upper-casing)' );
        System.Assert.isTrue( picklistLabels.contains( 'Reviewed' ), 'Expected to contain this picklist LABEL value, unmodified (no upper-casing)' );
    }

    @IsTest
    private static void isValidPicklistValue(){
        // When, Then
        // Success
        System.Assert.isTrue( fflib_SObjectDescribe.isValidPicklistValue( Solution.Status, 'Draft' ), 'Expected Draft to be a valid picklist value on Solution.Status field' );

        // Failure
        System.Assert.isFalse( fflib_SObjectDescribe.isValidPicklistValue( Solution.Status, null ), 'Expected false since blank picklist value was provided' );
        System.Assert.isFalse( fflib_SObjectDescribe.isValidPicklistValue( Solution.Status, 'Non existing picklist' ), 'Expected false since picklist value should not exist in Solution.Status' );
    }
}