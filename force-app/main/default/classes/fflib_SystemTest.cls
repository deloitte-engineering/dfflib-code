/**
 * Copyright (c), FinancialForce.com, inc
 * Copyright (c) 2019, Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
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
            System.Assert.areEqual( 'fflib_System.assertEquals expects you to register exactly 1 fflib_IMatcher (typically through the helpers in fflib_Match).', e.getMessage() );
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
            System.Assert.areEqual( 'fflib_System.assertEquals expects you to register exactly 1 fflib_IMatcher (typically through the helpers in fflib_Match).', e.getMessage() );
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
            System.Assert.areEqual( 'fflib_System.assertEquals expects you to register exactly 1 fflib_IMatcher (typically through the helpers in fflib_Match).', e.getMessage() );
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
            System.Assert.areEqual( 'fflib_System.assertEquals expects you to register exactly 1 fflib_IMatcher (typically through the helpers in fflib_Match).', e.getMessage() );
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
