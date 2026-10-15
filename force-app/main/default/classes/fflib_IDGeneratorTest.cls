/**
 * Copyright (c), FinancialForce.com, inc
 * Copyright (c), Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
@IsTest( isParallel = true )
@SuppressWarnings( 'PMD.AvoidHardcodingId, PMD.ClassNamingConventions, PMD.ApexUnitTestClassShouldHaveRunAs' )
private with sharing class fflib_IDGeneratorTest{

    @IsTest
    private static void itShouldGenerateValidIDs(){
        // Given, When
        String id1 = fflib_IDGenerator.generate( Account.SObjectType );
        String id2 = fflib_IDGenerator.generate( Account.SObjectType );
        String id3 = fflib_IDGenerator.generate( Account.SObjectType );
        String id4 = fflib_IDGenerator.generate( Account.SObjectType );
        String id5 = fflib_IDGenerator.generate( Account.SObjectType );
        String id6 = fflib_IDGenerator.generate( Account.SObjectType );
        String id7 = fflib_IDGenerator.generate( Account.SObjectType );
        String id8 = fflib_IDGenerator.generate( Account.SObjectType );
        String id9 = fflib_IDGenerator.generate( Account.SObjectType );
        String id10 = fflib_IDGenerator.generate( Account.SObjectType );
        String id11 = fflib_IDGenerator.generate( Account.SObjectType );

        // Then - validate
        System.Assert.areEqual( '001000000000001AAA', id1 );
        System.Assert.areEqual( '001000000000002AAA', id2 );
        System.Assert.areEqual( '001000000000003AAA', id3 );
        System.Assert.areEqual( '001000000000004AAA', id4 );
        System.Assert.areEqual( '001000000000005AAA', id5 );
        System.Assert.areEqual( '001000000000006AAA', id6 );
        System.Assert.areEqual( '001000000000007AAA', id7 );
        System.Assert.areEqual( '001000000000008AAA', id8 );
        System.Assert.areEqual( '001000000000009AAA', id9 );
        System.Assert.areEqual( '001000000000010AAA', id10 );
        System.Assert.areEqual( '001000000000011AAA', id11 );
    }
}
