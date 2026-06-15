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
        } catch( fflib_SObjectDescribe.InvalidDescribeException e ){
            System.Assert.areEqual( 'Invalid SObject type: null', e.getMessage(), 'Expected other Exception message' );
        }
        try{
            new fflib_SObjectDescribe( Account.SObjectType );
            new fflib_SObjectDescribe( Account.SObjectType );
            System.Assert.fail( 'Expected DuplicateDescribeException for duplicate Token initiation' );
        } catch( fflib_SObjectDescribe.DuplicateDescribeException e ){
            System.Assert.areEqual( 'Account is already in the describe cache', e.getMessage(), 'Expected other Exception message' );
        }
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
        System.Assert.areEqual( 'Account', d.getDescribe().getName() );
        System.Assert.isTrue( ( d === d2 && d2 === d3 ), 'All three getDescribe calls should return the same cached instance.' );
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
    private static void getDescribeName(){
        String objDescribeName = fflib_SObjectDescribe.getDescribe( Account.SObjectType ).getDescribeName();
        System.Assert.areEqual( 'Account', objDescribeName, 'Expected Object Describe Name' );
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
    private static void getDescribe_NativeDescribe(){
        // Test method to test the nativeDescribe initiator
        fflib_SObjectDescribe d = fflib_SObjectDescribe.getDescribe( Account.SObjectType.getDescribe() );
        System.Assert.areEqual( 'Account', d.getDescribeName(), 'Expected Account to be described' );
    }

    @IsTest
    private static void getDescribe_ByInstance(){
        // Test method to test the nativeDescribe initiator
        fflib_SObjectDescribe d = fflib_SObjectDescribe.getDescribe( new Account() );
        System.Assert.areEqual( 'Account', d.getDescribeName(), 'Expected Account to be described' );
    }
}