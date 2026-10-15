/**
 * Copyright (c), FinancialForce.com, inc
 * Copyright (c), Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
@IsTest( isParallel = true )
@SuppressWarnings('PMD.ClassNamingConventions, PMD.ApexUnitTestClassShouldHaveRunAs')
private with sharing class fflib_QualifiedMethodTest{
    @IsTest
    private static void equalsReturnsExpectedResults(){
        // Given - create data
        fflib_QualifiedMethod qm1 = new fflib_QualifiedMethod( 'Type1', 'Method1', new List<Type>{ Integer.class } );
        fflib_QualifiedMethod qm2 = new fflib_QualifiedMethod( 'Type1', 'Method1', new List<Type>{ Integer.class } );
        fflib_QualifiedMethod qm3 = new fflib_QualifiedMethod( 'Type1', 'Method1', new List<Type>{ String.class } );
        fflib_QualifiedMethod qm4 = new fflib_QualifiedMethod( 'Type2', 'Method2', new List<Type>{ Integer.class, String.class, fflib_QualifiedMethodTest.class } );
        fflib_QualifiedMethod qm5 = new fflib_QualifiedMethod( '', '', new List<Type>{} );
        fflib_QualifiedMethod qm6 = new fflib_QualifiedMethod( null, null, null );

        // When, Then
        System.Assert.areEqual( qm1, qm1 );
        System.Assert.areEqual( qm1, qm2 );
        System.Assert.areNotEqual( qm1, qm3 );
        System.Assert.areNotEqual( qm1, qm4 );
        System.Assert.areNotEqual( qm1, qm5 );
        System.Assert.areNotEqual( qm1, qm6 );

        System.Assert.areEqual( qm2, qm2 );
        System.Assert.areNotEqual( qm2, qm3 );
        System.Assert.areNotEqual( qm2, qm4 );
        System.Assert.areNotEqual( qm2, qm5 );
        System.Assert.areNotEqual( qm2, qm6 );

        System.Assert.areEqual( qm3, qm3 );
        System.Assert.areNotEqual( qm3, qm4 );
        System.Assert.areNotEqual( qm3, qm5 );
        System.Assert.areNotEqual( qm3, qm6 );

        System.Assert.areEqual( qm4, qm4 );
        System.Assert.areNotEqual( qm4, qm5 );
        System.Assert.areNotEqual( qm4, qm6 );

        System.Assert.areEqual( qm5, qm5 );
        System.Assert.areNotEqual( qm5, qm6 );

        System.Assert.areEqual( qm6, qm6 );
    }

    @IsTest
    private static void hashCodeReturnsExpectedResults(){
        // Given - create data
        fflib_QualifiedMethod qm1 = new fflib_QualifiedMethod( 'Type1', 'Method1', new List<Type>{ Integer.class } );
        fflib_QualifiedMethod qm2 = new fflib_QualifiedMethod( 'Type1', 'Method1', new List<Type>{ Integer.class } );
        fflib_QualifiedMethod qm3 = new fflib_QualifiedMethod( 'Type1', 'Method1', new List<Type>{ String.class } );
        fflib_QualifiedMethod qm4 = new fflib_QualifiedMethod( 'Type2', 'Method2', new List<Type>{ Integer.class, String.class, fflib_QualifiedMethodTest.class } );
        fflib_QualifiedMethod qm5 = new fflib_QualifiedMethod( '', '', new List<Type>{} );
        fflib_QualifiedMethod qm6 = new fflib_QualifiedMethod( null, null, null );

        // When, Then
        System.Assert.areEqual( qm1.hashCode(), qm1.hashCode() );
        System.Assert.areEqual( qm1.hashCode(), qm2.hashCode() );
        System.Assert.areNotEqual( qm1.hashCode(), qm3.hashCode() );
        System.Assert.areNotEqual( qm1.hashCode(), qm4.hashCode() );
        System.Assert.areNotEqual( qm1.hashCode(), qm5.hashCode() );
        System.Assert.areNotEqual( qm1.hashCode(), qm6.hashCode() );

        System.Assert.areEqual( qm2.hashCode(), qm2.hashCode() );
        System.Assert.areNotEqual( qm2.hashCode(), qm3.hashCode() );
        System.Assert.areNotEqual( qm2.hashCode(), qm4.hashCode() );
        System.Assert.areNotEqual( qm2.hashCode(), qm5.hashCode() );
        System.Assert.areNotEqual( qm2.hashCode(), qm6.hashCode() );

        System.Assert.areEqual( qm3.hashCode(), qm3.hashCode() );
        System.Assert.areNotEqual( qm3.hashCode(), qm4.hashCode() );
        System.Assert.areNotEqual( qm3.hashCode(), qm5.hashCode() );
        System.Assert.areNotEqual( qm3.hashCode(), qm6.hashCode() );

        System.Assert.areEqual( qm4.hashCode(), qm4.hashCode() );
        System.Assert.areNotEqual( qm4.hashCode(), qm5.hashCode() );
        System.Assert.areNotEqual( qm4.hashCode(), qm6.hashCode() );

        System.Assert.areEqual( qm5.hashCode(), qm5.hashCode() );
        System.Assert.areNotEqual( qm5.hashCode(), qm6.hashCode() );

        System.Assert.areEqual( qm6.hashCode(), qm6.hashCode() );
    }

    @IsTest
    private static void toStringReturnsExpectedResult(){
        System.Assert.areEqual( 'MyClass.MyMethod(Integer)', new fflib_QualifiedMethod( 'MyClass', 'MyMethod', new List<Type>{ Integer.class } ).toString() );
    }

    @IsTest
    private static void equalsReturnsExpectedResultsForHasDependentMocks(){
        // Given - create data
        String instance = 'My object instance';
        String instance2 = 'My other object instance';
        fflib_QualifiedMethod qm1 = new fflib_QualifiedMethod( 'Type1', 'Method1', new List<Type>{ Integer.class } );
        fflib_QualifiedMethod qm2 = new fflib_QualifiedMethod( 'Type1', 'Method1', new List<Type>{ Integer.class }, instance );
        fflib_QualifiedMethod qm3 = new fflib_QualifiedMethod( 'Type1', 'Method1', new List<Type>{ Integer.class }, instance );
        fflib_QualifiedMethod qm4 = new fflib_QualifiedMethod( 'Type1', 'Method1', new List<Type>{ Integer.class }, instance2 );

        // When, Then
        fflib_ApexMocksConfig.hasIndependentMocks = false;

        System.Assert.areEqual( qm1, qm2 );
        System.Assert.areEqual( qm1, qm3 );
        System.Assert.areEqual( qm1, qm4 );

        fflib_ApexMocksConfig.hasIndependentMocks = true;

        System.Assert.areNotEqual( qm1, qm2 );
        System.Assert.areNotEqual( qm1, qm3 );
        System.Assert.areNotEqual( qm1, qm4 );

        System.Assert.areEqual( qm2, qm3 );
        System.Assert.areNotEqual( qm2, qm4 );

        System.Assert.areNotEqual( qm3, qm4 );
    }

    @IsTest
    private static void hashCodeReturnsExpectedResultsForHasDependentMocks(){
        // Given - create data
        String instance = 'My object instance';
        String instance2 = 'My other object instance';
        fflib_QualifiedMethod qm1 = new fflib_QualifiedMethod( 'Type1', 'Method1', new List<Type>{ Integer.class } );
        fflib_QualifiedMethod qm2 = new fflib_QualifiedMethod( 'Type1', 'Method1', new List<Type>{ Integer.class }, instance );
        fflib_QualifiedMethod qm3 = new fflib_QualifiedMethod( 'Type1', 'Method1', new List<Type>{ Integer.class }, instance );
        fflib_QualifiedMethod qm4 = new fflib_QualifiedMethod( 'Type1', 'Method1', new List<Type>{ Integer.class }, instance2 );

        // When, Then
        fflib_ApexMocksConfig.hasIndependentMocks = false;

        System.Assert.areEqual( qm1.hashCode(), qm2.hashCode() );
        System.Assert.areEqual( qm1.hashCode(), qm3.hashCode() );
        System.Assert.areEqual( qm1.hashCode(), qm4.hashCode() );

        fflib_ApexMocksConfig.hasIndependentMocks = true;

        System.Assert.areNotEqual( qm1.hashCode(), qm2.hashCode() );
        System.Assert.areNotEqual( qm1.hashCode(), qm3.hashCode() );
        System.Assert.areNotEqual( qm1.hashCode(), qm4.hashCode() );

        System.Assert.areEqual( qm2.hashCode(), qm3.hashCode() );
        System.Assert.areNotEqual( qm2.hashCode(), qm4.hashCode() );

        System.Assert.areNotEqual( qm3.hashCode(), qm4.hashCode() );
    }
}