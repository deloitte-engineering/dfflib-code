/**
 * Copyright (c), FinancialForce.com, inc
 * Copyright (c), Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
/**
 *  Unit test module for the fflib_Objects class
 * 
 */
@IsTest( isParallel = true )
private with sharing class fflib_ObjectsTest{

    private static final fflib_ObjectsTest.DataTransferObject TRANSFER_OBJECT_A = new DataTransferObject( 'Test A' );
    private static final fflib_ObjectsTest.DataTransferObject TRANSFER_OBJECT_B = new DataTransferObject( 'Test B' );
    private static final fflib_ObjectsTest.DataTransferObject TRANSFER_OBJECT_C = new DataTransferObject( 'Test C' );
    private static final fflib_ObjectsTest.DataTransferObject TRANSFER_OBJECT_D = new DataTransferObject( 'Test D' );

    private static final String VERIFY_NO_EXCEPTION_THROWN_MESSAGE = 'No Exception expect, so this one is thrown';

    @IsTest
    private static void constructor_itShouldReturnTheCorrectType(){
        // Given - create data
        fflib_ObjectsTest.Domain dtoDomain = new Domain(
            new List<DataTransferObject>{
                TRANSFER_OBJECT_A,
                TRANSFER_OBJECT_B
            }
        );
        // When, Then
        System.Assert.areEqual(
            DataTransferObject.class,
            dtoDomain.getType(),
            'Wrong domain type'
        );
    }

    @IsTest
    private static void constructor_itShouldContainTheObject(){
        // Given - create data
        fflib_ObjectsTest.DataTransferObject transferObject = TRANSFER_OBJECT_A;
        fflib_ObjectsTest.Domain dtoDomain = new Domain(
            new List<DataTransferObject>{
                transferObject,
                TRANSFER_OBJECT_B
            }
        );
        // When, Then
        System.Assert.isTrue(
            dtoDomain.contains( transferObject ),
            'The object should have been part of the domain'
        );
    }

    @IsTest
    private static void containsNot_itShouldNotContainTheObject(){
        // Given - create data
        fflib_ObjectsTest.Domain dtoDomain = generateDomain();
        // When, Then
        System.Assert.isTrue(
            dtoDomain.containsNot( TRANSFER_OBJECT_D ),
            'The object should not have been part of the domain'
        );
    }

    @IsTest
    private static void containsNot_itShouldNotContainTheObjects(){
        // Given - create data
        fflib_ObjectsTest.Domain dtoDomain = new Domain(
            new List<Object>{
                TRANSFER_OBJECT_A,
                TRANSFER_OBJECT_B
            } );
        // When, Then
        System.Assert.isTrue(
            dtoDomain.containsNot(
                new Set<Object>{
                    TRANSFER_OBJECT_C,
                    TRANSFER_OBJECT_D
                } ),
            'The set of objects should not have been part of the domain'
        );
        System.Assert.isTrue(
            dtoDomain.containsNot(
                new List<Object>{
                    TRANSFER_OBJECT_C,
                    TRANSFER_OBJECT_D
                } ),
            'The list of objects should not have been part of the domain'
        );
    }

    @IsTest
    private static void constructor_itShouldHaveAnEmptyDomain(){
        // Given - create data
        fflib_ObjectsTest.Domain dtoDomain = new Domain( new List<DataTransferObject>() );
        // When, Then
        System.Assert.isTrue( dtoDomain.isEmpty(), 'Domain should be empty' );
    }

    @IsTest
    private static void constructor_itShouldNotBeAnEmptyDomain(){
        // Given - create data
        fflib_ObjectsTest.Domain dtoDomain = generateDomain();
        // When, Then
        System.Assert.isTrue( dtoDomain.isNotEmpty(), 'Domain should not be empty' );
        System.Assert.areEqual( 3, dtoDomain.size(), 'Incorrect amount of records in the domain' );
    }

    @IsTest
    private static void containsAll_itShouldContainAllTheObjects(){
        // Given - create data
        fflib_ObjectsTest.Domain dtoDomain = generateDomain();
        // When, Then
        System.Assert.isTrue(
            dtoDomain.containsAll(
                new List<DataTransferObject>{
                    TRANSFER_OBJECT_A,
                    TRANSFER_OBJECT_B
                }
            ),
            'Domain should contain the whole List of objects'
        );
        System.Assert.isTrue(
            dtoDomain.containsAll(
                new Set<Object>{
                    TRANSFER_OBJECT_A,
                    TRANSFER_OBJECT_B
                }
            ),
            'Domain should contain the whole Set of objects'
        );
    }

    @IsTest
    private static void containsAll_nullValidation(){
        // Given - create data
        fflib_ObjectsTest.Domain dtoDomain = generateDomain();
        // When, Then
        System.Assert.isFalse(
            dtoDomain.containsAll( ( List<DataTransferObject> ) null ),
            'Upon null-list-input, false should be returned'
        );
        System.Assert.isFalse(
            dtoDomain.containsAll( ( Set<Object> ) null ),
            'Upon null-set-input, false should be returned'
        );
    }

    @IsTest
    private static void defaultConstructor_itShouldGetTheObjectType(){
        // Given - create data
        fflib_Objects domain = new fflib_Objects( new List<Object>() );
        // When, Then
        System.Assert.areEqual( Object.class, domain.getType(), 'Incorrect returned type' );
    }

    @IsTest
    private static void getSetObjects_itShouldSetTheObjectList(){
        // Given - create data
        List<DataTransferObject> domainObjects = new List<DataTransferObject>{
            TRANSFER_OBJECT_A,
            TRANSFER_OBJECT_B
        };
        List<DataTransferObject> newDomainObjects = new List<DataTransferObject>{
            TRANSFER_OBJECT_C,
            TRANSFER_OBJECT_D
        };
        fflib_ObjectsTest.Domain dtoDomain = new Domain( domainObjects );
        // When, Then
        System.Assert.areEqual( domainObjects, dtoDomain.getObjects() );

        dtoDomain.setObjects( newDomainObjects );
        // When, Then
        System.Assert.areEqual( newDomainObjects, dtoDomain.getObjects() );
    }

    @IsTest
    private static void verifyNotNull_notNullShouldNotThrowException(){
        try{
            fflib_Objects.verifyNotNull( '', 'test' );
            throw new fflib_ApexMocks.ApexMocksException( VERIFY_NO_EXCEPTION_THROWN_MESSAGE );
        } catch( Exception ex ){
            System.Assert.areEqual( VERIFY_NO_EXCEPTION_THROWN_MESSAGE, ex.getMessage() );
        }
    }

    @IsTest
    private static void verifyNotNull_nullShouldThrowException(){
        try{
            fflib_Objects.verifyNotNull( null, 'test' );
            System.Assert.fail( 'Expected an exception to be thrown. This assertion should never be triggered, as input was null' );
        } catch( Exception ex ){
            System.Assert.areEqual( 'test cannot be null', ex.getMessage() );
        }
    }

    @IsTest
    private static void verifyNotNull_notBlankShouldNotThrowException(){
        try{
            fflib_Objects.verifyNotNull( 'blank', 'test' );
            throw new fflib_ApexMocks.ApexMocksException( VERIFY_NO_EXCEPTION_THROWN_MESSAGE );
        } catch( Exception ex ){
            System.Assert.areEqual( VERIFY_NO_EXCEPTION_THROWN_MESSAGE, ex.getMessage() );
        }
    }

    @IsTest
    private static void verifyNotBlank_blankShouldThrowException(){
        try{
            fflib_Objects.verifyNotBlank( '', 'test' );
            System.Assert.fail( 'Expected an exception to be thrown. This assertion should never be triggered, as input was blank' );
        } catch( Exception ex ){
            System.Assert.areEqual( 'test cannot be blank', ex.getMessage() );
        }
    }

    @IsTest
    private static void verifyNotEmpty_nullValueShouldThrowException(){
        try{
            fflib_Objects.verifyNotEmpty( new List<Object>{}, 'test' );
            System.Assert.fail( 'Expected an exception to be thrown. This assertion should never be triggered, as list contains null value' );
        } catch( Exception ex ){
            System.Assert.areEqual( 'test cannot be empty', ex.getMessage() );
        }
    }

    @IsTest
    private static void verifyNotEmpty_noNullValueShouldNotThrowException(){
        try{
            fflib_Objects.verifyNotEmpty( new List<Object>{ 'hello' }, 'test' );
            throw new fflib_ApexMocks.ApexMocksException( VERIFY_NO_EXCEPTION_THROWN_MESSAGE );
        } catch( Exception ex ){
            System.Assert.areEqual( VERIFY_NO_EXCEPTION_THROWN_MESSAGE, ex.getMessage() );
        }
    }

    private static Domain generateDomain(){
        return new Domain( generateDataTransferObjects() );
    }

    private static List<DataTransferObject> generateDataTransferObjects(){
        return new List<DataTransferObject>{
            TRANSFER_OBJECT_A,
            TRANSFER_OBJECT_B,
            TRANSFER_OBJECT_C
        };
    }

    private class Domain extends fflib_Objects{
        public Domain( List<Object> objects ){
            super( objects );
        }

        public override Object getType(){
            return DataTransferObject.class;
        }
    }

    private class DataTransferObject{
        public String MyProperty{ get; set; }

        public DataTransferObject( String property ){
            this.MyProperty = property;
        }
    }
}
