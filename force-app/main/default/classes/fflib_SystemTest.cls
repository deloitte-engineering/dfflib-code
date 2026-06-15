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
private with sharing class fflib_SystemTest{
    @IsTest
    private static void assertEquals_WithNoMatchers_ShouldThrowException(){
        // When, Then
        try{
            fflib_System.assertEquals( 'Test String', 'Test String' );
            System.Assert.fail( 'Expected fflib_ApexMocks.ApexMocksException to be thrown. This assertion should never be triggered' );
        } catch( fflib_ApexMocks.ApexMocksException e ){
            System.Assert.areEqual( 'System.Assert.areEqual() expects you to register exactly 1 fflib_IMatcher (typically through the helpers in fflib_Match).', e.getMessage() );
        }
    }

    @IsTest
    private static void assertEquals_WithTooManyMatchers_ShouldThrowException(){
        // Given - register matchers prematurely
        fflib_Match.stringStartsWith( 'Test S' );
        fflib_Match.stringEndsWith( 't String' );
        fflib_Match.stringIsNotBlank();

        // When, Then
        try{
            fflib_System.assertEquals( fflib_Match.stringStartsWith( 'Test S' ), 'Test String' );
            System.Assert.fail( 'Expected fflib_ApexMocks.ApexMocksException to be thrown. This assertion should never be triggered' );
        } catch( fflib_ApexMocks.ApexMocksException e ){
            System.Assert.areEqual( 'System.Assert.areEqual() expects you to register exactly 1 fflib_IMatcher (typically through the helpers in fflib_Match).', e.getMessage() );
        }
    }

    @IsTest
    private static void assertEquals_WithMismatch_ShouldThrowException(){
        // When, Then
        try{
            fflib_System.assertEquals( fflib_Match.stringStartsWith( 'Test X' ), 'Test String' );
            System.Assert.fail( 'Expected fflib_ApexMocks.ApexMocksException to be thrown. This assertion should never be triggered' );
        } catch( fflib_ApexMocks.ApexMocksException e ){
            String expected = 'Actual: Test String';
            String actual = e.getMessage();
            System.Assert.isTrue( actual.contains( expected ), 'Expected: ' + expected + ', Actual: ' + actual );
        }
    }

    @IsTest
    private static void assertEquals_WithMatch_ShouldPass(){
        // When, Then
        fflib_System.assertEquals( fflib_Match.stringStartsWith( 'Test S' ), 'Test String' );
    }

    @IsTest
    private static void assertEquals_WithCombinedMatcher_ShouldPass(){
        // When, Then
        fflib_System.assertEquals( fflib_Match.allOf(
            fflib_Match.stringStartsWith( 'Test S' ),
            fflib_Match.stringEndsWith( 't String' ),
            fflib_Match.stringIsNotBlank() )
            , 'Test String' );
    }

    @IsTest
    private static void assertEquals_WithCustomMessage_WithNoMatchers_ShouldThrowException(){
        // When, Then
        try{
            fflib_System.assertEquals( 'Test String', 'Test String', 'My Custom Message' );
            System.Assert.fail( 'Expected fflib_ApexMocks.ApexMocksException to be thrown. This assertion should never be triggered' );
        } catch( fflib_ApexMocks.ApexMocksException e ){
            System.Assert.areEqual( 'System.Assert.areEqual() expects you to register exactly 1 fflib_IMatcher (typically through the helpers in fflib_Match).', e.getMessage() );
        }
    }

    @IsTest
    private static void assertEquals_WithCustomMessage_WithTooManyMatchers_ShouldThrowException(){
        // Given - register matchers prematurely
        fflib_Match.stringStartsWith( 'Test S' );
        fflib_Match.stringEndsWith( 't String' );
        fflib_Match.stringIsNotBlank();

        // When, Then
        try{
            fflib_System.assertEquals( fflib_Match.stringStartsWith( 'Test S' ), 'Test String', 'My Custom Message' );
            System.Assert.fail( 'Expected fflib_ApexMocks.ApexMocksException to be thrown. This assertion should never be triggered' );
        } catch( fflib_ApexMocks.ApexMocksException e ){
            System.Assert.areEqual( 'System.Assert.areEqual() expects you to register exactly 1 fflib_IMatcher (typically through the helpers in fflib_Match).', e.getMessage() );
        }
    }

    @IsTest
    private static void assertEquals_WithCustomMessage_WithMismatch_ShouldThrowException(){
        // When, Then
        try{
            fflib_System.assertEquals( fflib_Match.stringStartsWith( 'Test X' ), 'Test String', 'My Custom Message' );
            System.Assert.fail( 'Expected fflib_ApexMocks.ApexMocksException to be thrown. This assertion should never be triggered' );
        } catch( fflib_ApexMocks.ApexMocksException e ){
            String expected = 'Actual: Test String -- My Custom Message';
            String actual = e.getMessage();
            System.Assert.isTrue( actual.contains( expected ), 'Expected: ' + expected + ', Actual: ' + actual );
        }
    }

    @IsTest
    private static void assertEquals_WithCustomMessage_WithMatch_ShouldPass(){
        // When, Then
        fflib_System.assertEquals( fflib_Match.stringStartsWith( 'Test S' ), 'Test String', 'My Custom Message' );
    }

    @IsTest
    private static void assertEquals_WithCustomMessage_WithCombinedMatcher_ShouldPass(){
        // When, Then
        fflib_System.assertEquals( fflib_Match.allOf(
            fflib_Match.stringStartsWith( 'Test S' ),
            fflib_Match.stringEndsWith( 't String' ),
            fflib_Match.stringIsNotBlank() )
            , 'Test String', 'My Custom Message' );
    }
}