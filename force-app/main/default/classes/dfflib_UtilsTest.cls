/**
 * Copyright (c), Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
/**
 *  Unit test module for the dfflib_Utils class
 *
 *  @author     Rafael Fernandes dos Santos (rfernandesdossantos@deloitte.nl)
 *  @created    October 2025
 */
@IsTest( isParallel = true )
private with sharing class dfflib_UtilsTest{
    private static final String VERIFY_NO_EXCEPTION_THROWN_MESSAGE = 'No Exception expect, so this one is thrown';

    @IsTest
    private static void verifyNotNull_notNullShouldNotThrowException(){
        try{
            dfflib_Utils.verifyNotNull( '', 'test' );
            throw new fflib_ApexMocks.ApexMocksException( VERIFY_NO_EXCEPTION_THROWN_MESSAGE );
        } catch( Exception ex ){
            System.Assert.areEqual( VERIFY_NO_EXCEPTION_THROWN_MESSAGE, ex.getMessage() );
        }
    }

    @IsTest
    private static void verifyNotNull_nullShouldThrowException(){
        try{
            dfflib_Utils.verifyNotNull( null, 'test' );
            System.Assert.fail( 'Expected an exception to be thrown. This assertion should never be triggered, as input was null' );
        } catch( Exception ex ){
            System.Assert.areEqual( 'test cannot be null', ex.getMessage() );
        }
    }

    @IsTest
    private static void verifyNotNull_notBlankShouldNotThrowException(){
        try{
            dfflib_Utils.verifyNotNull( 'blank', 'test' );
            throw new fflib_ApexMocks.ApexMocksException( VERIFY_NO_EXCEPTION_THROWN_MESSAGE );
        } catch( Exception ex ){
            System.Assert.areEqual( VERIFY_NO_EXCEPTION_THROWN_MESSAGE, ex.getMessage() );
        }
    }

    @IsTest
    private static void verifyNotBlank_blankShouldThrowException(){
        try{
            dfflib_Utils.verifyNotBlank( '', 'test' );
            System.Assert.fail( 'Expected an exception to be thrown. This assertion should never be triggered, as input was blank' );
        } catch( Exception ex ){
            System.Assert.areEqual( 'test cannot be blank', ex.getMessage() );
        }
    }

    @IsTest
    private static void verifyNotEmpty_nullValueShouldThrowException(){
        try{
            dfflib_Utils.verifyNotEmpty( new List<Object>{}, 'test' );
            System.Assert.fail( 'Expected an exception to be thrown. This assertion should never be triggered, as list contains null value' );
        } catch( Exception ex ){
            System.Assert.areEqual( 'test cannot be empty', ex.getMessage() );
        }
    }

    @IsTest
    private static void verifyNotEmpty_noNullValueShouldNotThrowException(){
        try{
            dfflib_Utils.verifyNotEmpty( new List<Object>{ 'hello' }, 'test' );
            throw new fflib_ApexMocks.ApexMocksException( VERIFY_NO_EXCEPTION_THROWN_MESSAGE );
        } catch( Exception ex ){
            System.Assert.areEqual( VERIFY_NO_EXCEPTION_THROWN_MESSAGE, ex.getMessage() );
        }
    }
}