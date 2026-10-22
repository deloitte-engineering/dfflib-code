/**
 * Copyright (c), FinancialForce.com, inc
 * Copyright (c) 2019, Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
@IsTest( isParallel = true )
private with sharing class fflib_MethodArgValuesTest{
    @IsTest
    private static void equalsReturnsExpectedResults(){
        // Given - create data
        fflib_MethodArgValues qm1 = new fflib_MethodArgValues( new List<Object>{ 'hello' } );
        fflib_MethodArgValues qm2 = new fflib_MethodArgValues( new List<Object>{ 'hello' } );
        fflib_MethodArgValues qm3 = new fflib_MethodArgValues( new List<Object>{ 'hi' } );
        fflib_MethodArgValues qm4 = new fflib_MethodArgValues( new List<Object>{ 'hello', 'hello', 'hello' } );
        fflib_MethodArgValues qm5 = new fflib_MethodArgValues( new List<Object>() );
        fflib_MethodArgValues qm6 = new fflib_MethodArgValues( null );

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
        fflib_MethodArgValues qm1 = new fflib_MethodArgValues( new List<Object>{ 'hello' } );
        fflib_MethodArgValues qm2 = new fflib_MethodArgValues( new List<Object>{ 'hello' } );
        fflib_MethodArgValues qm3 = new fflib_MethodArgValues( new List<Object>{ 'hi' } );
        fflib_MethodArgValues qm4 = new fflib_MethodArgValues( new List<Object>{ 'hello', 'hello', 'hello' } );
        fflib_MethodArgValues qm5 = new fflib_MethodArgValues( new List<Object>() );
        fflib_MethodArgValues qm6 = new fflib_MethodArgValues( null );

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
}
