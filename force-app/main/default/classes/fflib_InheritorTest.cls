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