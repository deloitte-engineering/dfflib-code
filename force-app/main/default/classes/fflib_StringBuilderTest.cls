/**
 * Copyright (c), FinancialForce.com, inc
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
 * - Neither the name of the FinancialForce.com, inc nor the names of its contributors 
 *      may be used to endorse or promote products derived from this software without 
 *      specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
 *  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
 *  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL 
 *  THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 *  OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 *  OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
@IsTest( IsParallel = true )
private with sharing class fflib_StringBuilderTest{

    @IsTest
    private static void testfflib_StringBuilderEmptyConstructor(){
        // Given, When
        fflib_StringBuilder sb = new fflib_StringBuilder();
        sb.add( 'this is a string' );
        sb.add( new List<String>{ ', which is made', ' up from\r ', 'a number of smaller strings', '. 5 in this case!' } );

        // Then - validate
        System.Assert.areEqual( sb.getStringValue(), 'this is a string, which is made up from\r a number of smaller strings. 5 in this case!' );
    }

    @IsTest
    private static void testfflib_StringBuilderConstructorWithValues(){
        // Given, When
        fflib_StringBuilder sb = new fflib_StringBuilder( new List<String>{ 'apples', ' and ', 'pears', ': stairs. ' } );
        sb.add( 'this is a string' );
        sb.add( new List<String>{ ', which is made', ' up from\r ', 'a number of smaller strings', '. 5 in this case!' } );

        // Then - validate
        System.Assert.areEqual( sb.getStringValue(), 'apples and pears: stairs. this is a string, which is made up from\r a number of smaller strings. 5 in this case!' );
    }

    @IsTest
    private static void testCommaDelimitedBuilderEmptyConstructor(){
        // Given, When
        fflib_StringBuilder.CommaDelimitedListBuilder sb = new fflib_StringBuilder.CommaDelimitedListBuilder();
        sb.add( 'a' );
        sb.add( new List<String>{ 'b', 'c', 'd' } );

        // Then - validate
        System.Assert.areEqual( sb.getStringValue(), 'a,b,c,d' );
    }

    @IsTest
    private static void testCommaDelimitedBuilderConstructorWithValues(){
        // Given, When
        fflib_StringBuilder.CommaDelimitedListBuilder sb = new fflib_StringBuilder.CommaDelimitedListBuilder( new List<String>{ 'x', 'y' } );
        sb.add( 'a' );
        sb.add( new List<String>{ 'b', 'c', 'd' } );

        // Then - validate
        System.Assert.areEqual( sb.getStringValue(), 'x,y,a,b,c,d' );
    }

    @IsTest
    private static void testCommaDelimitedBuilderWithItemPrefix(){
        // Given, When
        fflib_StringBuilder.CommaDelimitedListBuilder sb = new fflib_StringBuilder.CommaDelimitedListBuilder( new List<String>{ 'x', 'y' } );
        sb.add( 'a' );
        sb.add( new List<String>{ 'b', 'c', 'd' } );

        // Then - validate
        System.Assert.areEqual( sb.getStringValue( '$' ), '$x,$y,$a,$b,$c,$d' );
    }

    @IsTest
    private static void testCommaDelimitedBuilderWithAlternativeDelimiter(){
        // Given, When
        fflib_StringBuilder.CommaDelimitedListBuilder sb = new fflib_StringBuilder.CommaDelimitedListBuilder( new List<String>{ 'x', 'y' } );
        sb.setDelimiter( ';' );
        sb.add( 'a' );
        sb.add( new List<String>{ 'b', 'c', 'd' } );

        // Then - validate
        System.Assert.areEqual( sb.getStringValue(), 'x;y;a;b;c;d' );
    }

    @IsTest
    private static void testCommaDelimitedBuilderWithAlternativeDelimiterAndPrefix(){
        // Given, When
        fflib_StringBuilder.CommaDelimitedListBuilder sb = new fflib_StringBuilder.CommaDelimitedListBuilder(
            new List<String>{ 'x', 'y' }
        );
        sb.setItemPrefix( '#' );
        sb.setDelimiter( ':' );
        sb.add( 'a' );
        sb.add( new List<String>{ 'b', 'c', 'd' } );

        // Then - validate
        System.Assert.areEqual( sb.getStringValue(), '#x:#y:#a:#b:#c:#d' );
    }

    @IsTest
    private static void testFieldListBuilderConstructorWithValues(){
        // Given - create data
        List<Schema.SObjectField> fields = new List<Schema.SObjectField>{
            Account.Name,
            Account.Id,
            Account.AccountNumber,
            Account.AccountNumber,
            Account.AnnualRevenue
        };

        // When - perform test
        fflib_StringBuilder.FieldListBuilder sb = new fflib_StringBuilder.FieldListBuilder( fields );
        List<String> fieldList = sb.getStringValue().split( ',' );
        Set<String> fieldSet = new Set<String>( fieldList );

        // Then - validate
        System.Assert.areEqual( 4, fieldSet.size() );
        System.Assert.isTrue( fieldSet.contains( 'Name' ) );
        System.Assert.isTrue( fieldSet.contains( 'Id' ) );
        System.Assert.isTrue( fieldSet.contains( 'AccountNumber' ) );
        System.Assert.isTrue( fieldSet.contains( 'AnnualRevenue' ) );
    }

    @IsTest
    private static void testMultiCurrencyFieldListBuilderConstructorWithValues(){
        // Given - create data
        List<Schema.SObjectField> fields = new List<Schema.SObjectField>{
            Account.Name,
            Account.Id,
            Account.AccountNumber,
            Account.AnnualRevenue
        };

        // When - perform test
        fflib_StringBuilder.MultiCurrencyFieldListBuilder sb = new fflib_StringBuilder.MultiCurrencyFieldListBuilder( fields );
        List<String> fieldList = sb.getStringValue().split( ',' );
        Set<String> fieldSet = new Set<String>( fieldList );

        // Then - validate
        System.Assert.isTrue( fieldSet.contains( 'Name' ) );
        System.Assert.isTrue( fieldSet.contains( 'Id' ) );
        System.Assert.isTrue( fieldSet.contains( 'AccountNumber' ) );
        System.Assert.isTrue( fieldSet.contains( 'AnnualRevenue' ) );
        if( UserInfo.isMultiCurrencyOrganization() ){
            System.Assert.isTrue( fieldSet.contains( 'CurrencyIsoCode' ) );
        }
    }
}