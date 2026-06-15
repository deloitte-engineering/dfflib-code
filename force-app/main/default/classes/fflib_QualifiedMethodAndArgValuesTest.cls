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
 *//**
 * Unit test class for fflib_QualifiedMethodAndArgValues class.
 *
 * @created 	January 2020
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