/**
 * Copyright (c) 2014, FinancialForce.com, inc
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * - Redistributions of source code must retain the above copyright notice,
 *      this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright notice,
 *      this list of conditions and the following disclaimer in the documentation
 *      and/or other materials provided with the distribution.
 * - Neither the name of the FinancialForce.com, inc nor the names of its contributors
 *      may be used to endorse or promote products derived from this software without
 *      specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
@IsTest( isParallel = true )
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
        fflib_ApexMocksConfig.HasIndependentMocks = false;

        System.Assert.areEqual( qm1, qm2 );
        System.Assert.areEqual( qm1, qm3 );
        System.Assert.areEqual( qm1, qm4 );

        fflib_ApexMocksConfig.HasIndependentMocks = true;

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
        fflib_ApexMocksConfig.HasIndependentMocks = false;

        System.Assert.areEqual( qm1.hashCode(), qm2.hashCode() );
        System.Assert.areEqual( qm1.hashCode(), qm3.hashCode() );
        System.Assert.areEqual( qm1.hashCode(), qm4.hashCode() );

        fflib_ApexMocksConfig.HasIndependentMocks = true;

        System.Assert.areNotEqual( qm1.hashCode(), qm2.hashCode() );
        System.Assert.areNotEqual( qm1.hashCode(), qm3.hashCode() );
        System.Assert.areNotEqual( qm1.hashCode(), qm4.hashCode() );

        System.Assert.areEqual( qm2.hashCode(), qm3.hashCode() );
        System.Assert.areNotEqual( qm2.hashCode(), qm4.hashCode() );

        System.Assert.areNotEqual( qm3.hashCode(), qm4.hashCode() );
    }
}