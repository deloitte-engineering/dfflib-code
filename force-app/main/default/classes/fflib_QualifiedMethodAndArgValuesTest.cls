/**
 * Copyright (c), FinancialForce.com, inc
 * Copyright (c), Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
/**
 * Unit test class for fflib_QualifiedMethodAndArgValues class.
 */
@IsTest( isParallel = true )
private with sharing class fflib_QualifiedMethodAndArgValuesTest{

    @IsTest
    private static void constructor_shouldInitializeClassCorrectly(){
        // Given - create data
        fflib_QualifiedMethod qualifiedMethod = new fflib_QualifiedMethod( 'Type1', 'Method1', new List<Type>{ Integer.class } );
        fflib_MethodArgValues argValues = new fflib_MethodArgValues( new List<Object>() );
        fflib_MyList mockList = ( fflib_MyList ) new fflib_ApexMocks().mock( fflib_MyList.class );

        // When, Then
        fflib_QualifiedMethodAndArgValues instance = new fflib_QualifiedMethodAndArgValues( qualifiedMethod, argValues, mockList );
        System.Assert.isNotNull( instance, 'Expected instantiated variable' );
    }

    @IsTest
    private static void getQualifiedMethod_shouldReturnQualifiedMethodCorrectly(){
        // Given - create data
        fflib_QualifiedMethod qualifiedMethod = new fflib_QualifiedMethod( 'Type1', 'Method1', new List<Type>{ Integer.class } );
        fflib_MethodArgValues argValues = new fflib_MethodArgValues( new List<Object>() );
        fflib_MyList mockList = ( fflib_MyList ) new fflib_ApexMocks().mock( fflib_MyList.class );

        // When - perform test
        fflib_QualifiedMethod retQualifiedMethod = new fflib_QualifiedMethodAndArgValues( qualifiedMethod, argValues, mockList ).getQualifiedMethod();

        // Then - validate
        System.Assert.areEqual( qualifiedMethod, retQualifiedMethod, 'The qualifiedMethod returned should be the same used in constructor.' );
    }

    @IsTest
    private static void getMethodArgValues_shouldReturnMethodArgValuesCorrectly(){
        // Given - create data
        fflib_QualifiedMethod qualifiedMethod = new fflib_QualifiedMethod( 'Type1', 'Method1', new List<Type>{ Integer.class } );
        fflib_MethodArgValues argValues = new fflib_MethodArgValues( new List<Object>() );
        fflib_MyList mockList = ( fflib_MyList ) new fflib_ApexMocks().mock( fflib_MyList.class );

        // When - perform test
        fflib_MethodArgValues retArgValues = new fflib_QualifiedMethodAndArgValues( qualifiedMethod, argValues, mockList ).getMethodArgValues();

        // Then - validate
        System.Assert.areEqual( argValues, retArgValues, 'The argValues returned should be the same used in constructor.' );
    }

    @IsTest
    private static void getMockInstance_shouldReturnMockObjectCorrectly(){
        // Given - create data
        fflib_QualifiedMethod qualifiedMethod = new fflib_QualifiedMethod( 'Type1', 'Method1', new List<Type>{ Integer.class } );
        fflib_MethodArgValues argValues = new fflib_MethodArgValues( new List<Object>() );
        fflib_MyList mockList = ( fflib_MyList ) new fflib_ApexMocks().mock( fflib_MyList.class );

        // When - perform test
        fflib_MyList retMockList = ( fflib_MyList ) new fflib_QualifiedMethodAndArgValues( qualifiedMethod, argValues, mockList ).getMockInstance();

        // Then - validate
        System.Assert.areEqual( mockList, retMockList, 'The mockList returned should be the same used in constructor.' );
    }

    @IsTest
    private static void toString_shouldReturnToStringCorrectly(){
        // Given - create data
        fflib_QualifiedMethod qualifiedMethod = new fflib_QualifiedMethod( 'Type1', 'Method1', new List<Type>{ Integer.class } );
        fflib_MethodArgValues argValues = new fflib_MethodArgValues( new List<Object>() );
        fflib_MyList mockList = ( fflib_MyList ) new fflib_ApexMocks().mock( fflib_MyList.class );
        String toString = qualifiedMethod + ' with args: [' + String.join( argValues.argValues, '],[' ) + ']';

        // When - perform test
        String retToString = new fflib_QualifiedMethodAndArgValues( qualifiedMethod, argValues, mockList ).toString();

        // Then - validate
        System.Assert.areEqual( toString, retToString, 'The string returned should be the same used in constructor.' );
    }
}
