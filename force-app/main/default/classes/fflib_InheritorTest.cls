/**
 * Copyright (c), FinancialForce.com, inc
 * Copyright (c), Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
@IsTest( isParallel = true )
private with sharing class fflib_InheritorTest{

    @IsTest
    private static void canInstantiateMultipleInterfaceInheritor(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();

        // When - perform test
        Object inheritor = mocks.mock( fflib_Inheritor.class );

        // Then - validate
        System.Assert.isInstanceOfType( inheritor, fflib_Inheritor.IA.class );
        System.Assert.isInstanceOfType( inheritor, fflib_Inheritor.IB.class );
        System.Assert.isInstanceOfType( inheritor, fflib_Inheritor.IC.class );
    }

    @IsTest
    private static void canStubMultipleInterfaceInheritor(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_Inheritor inheritor = ( fflib_Inheritor ) mocks.mock( fflib_Inheritor.class );

        // Set mocks
        mocks.startStubbing();
        mocks.when( inheritor.doA() ).thenReturn( 'Did not do A' );
        mocks.when( inheritor.doB() ).thenReturn( 'Did not do B' );
        mocks.when( inheritor.doC() ).thenReturn( 'Did not do C' );
        mocks.stopStubbing();

        // When, Then
        System.Assert.areEqual( 'Did not do A', inheritor.doA() );
        System.Assert.areEqual( 'Did not do B', inheritor.doB() );
        System.Assert.areEqual( 'Did not do C', inheritor.doC() );
    }
}
