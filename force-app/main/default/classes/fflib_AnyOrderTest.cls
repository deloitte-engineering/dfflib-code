/**
 * Copyright (c), FinancialForce.com, inc
 * Copyright (c), Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
/**
 * Unit test class for fflib_AnyOrder class.
 *
 * @created     July 2020
 */
@IsTest( isParallel = true )
private with sharing class fflib_AnyOrderTest{
    @IsTest
    private static void whenVerifyMultipleCallsWithMatchersShouldReturnCorrectMethodCallCounts(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'bob' );
        mockList.add( 'fred' );

        // Then - validate
        ( ( fflib_MyList.IList ) mocks.verify( mockList, mocks.times( 2 ) ) ).add( fflib_Match.anyString() );
        ( ( fflib_MyList.IList ) mocks.verify( mockList ) ).add( 'fred' );
        ( ( fflib_MyList.IList ) mocks.verify( mockList ) ).add( fflib_Match.stringContains( 'fred' ) );
    }

    @IsTest
    private static void whenVerifyWithCombinedMatchersShouldReturnCorrectMethodCallCounts(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'bob' );
        mockList.add( 'fred' );

        // Then - validate
        ( ( fflib_MyList.IList ) mocks.verify( mockList, mocks.never() ) ).add(
            ( String ) fflib_Match.allOf( fflib_Match.eq( 'bob' ), fflib_Match.stringContains( 're' ) )
        );

        ( ( fflib_MyList.IList ) mocks.verify( mockList ) ).add(
            ( String ) fflib_Match.allOf( fflib_Match.eq( 'fred' ), fflib_Match.stringContains( 're' ) )
        );

        ( ( fflib_MyList.IList ) mocks.verify( mockList, mocks.times( 2 ) ) ).add(
            ( String ) fflib_Match.anyOf( fflib_Match.eq( 'bob' ), fflib_Match.eq( 'fred' ) )
        );

        ( ( fflib_MyList.IList ) mocks.verify( mockList ) ).add(
            ( String ) fflib_Match.anyOf( fflib_Match.eq( 'bob' ), fflib_Match.eq( 'jack' ) )
        );

        ( ( fflib_MyList.IList ) mocks.verify( mockList, mocks.times( 2 ) ) ).add(
            ( String ) fflib_Match.noneOf( fflib_Match.eq( 'jack' ), fflib_Match.eq( 'tim' ) )
        );

        ( ( fflib_MyList.IList ) mocks.verify( mockList, mocks.times( 2 ) ) ).add(
            ( String ) fflib_Match.noneOf(
                fflib_Match.anyOf( fflib_Match.eq( 'jack' ), fflib_Match.eq( 'jill' ) ),
                fflib_Match.allOf( fflib_Match.eq( 'tim' ), fflib_Match.stringContains( 'i' ) )
            )
        );

        ( ( fflib_MyList.IList ) mocks.verify( mockList, mocks.times( 2 ) ) ).add(
            ( String ) fflib_Match.isNot( fflib_Match.eq( 'jack' ) )
        );
    }

    @IsTest
    private static void whenVerifyCustomMatchersCanBeUsed(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.get( 1 );
        mockList.get( 2 );
        mockList.get( 3 );
        mockList.get( 4 );
        mockList.get( 5 );

        // Then - validate
        ( ( fflib_MyList.IList ) mocks.verify( mockList, mocks.times( 3 ) ) ).get( ( Integer ) fflib_Match.matches( new isOdd() ) );
        ( ( fflib_MyList.IList ) mocks.verify( mockList, mocks.times( 2 ) ) ).get( ( Integer ) fflib_Match.matches( new isEven() ) );
    }

    @IsTest
    private static void verifyMultipleMethodCallsWithSameSingleArgument(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'bob' );
        mockList.add( 'bob' );

        // Then - validate
        ( ( fflib_MyList.IList ) mocks.verify( mockList, mocks.times( 2 ) ) ).add( 'bob' );
    }

    @IsTest
    private static void verifyMethodNotCalled(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.get( 0 );

        // Then - validate
        ( ( fflib_MyList.IList ) mocks.verify( mockList, mocks.never() ) ).add( 'bob' );
        ( ( fflib_MyList.IList ) mocks.verify( mockList ) ).get( 0 );
    }

    @IsTest
    private static void verifySingleMethodCallWithMultipleArguments(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.set( 0, 'bob' );

        // Then - validate
        ( ( fflib_MyList.IList ) mocks.verify( mockList ) ).set( 0, 'bob' );
        ( ( fflib_MyList.IList ) mocks.verify( mockList, mocks.never() ) ).set( 0, 'fred' );
    }

    @IsTest
    private static void verifyMethodCallWhenNoCallsBeenMadeForType(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // Then - validate
        ( ( fflib_MyList.IList ) mocks.verify( mockList, mocks.never() ) ).add( 'bob' );
    }

    @IsTest
    private static void whenVerifyMethodNeverCalledMatchersAreReset(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'bob' );

        // Then - validate
        ( ( fflib_MyList.IList ) mocks.verify( mockList, mocks.never() ) ).get( fflib_Match.anyInteger() );
        ( ( fflib_MyList.IList ) mocks.verify( mockList ) ).add( fflib_Match.anyString() );
    }

    @IsTest
    private static void verifyTimesMethodHasBeenCalled(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'bob' );
        mockList.add( 'bob' );
        mockList.add( 'bob' );

        // Then - validate
        ( ( fflib_MyList.IList ) mocks.verify( mockList, mocks.times( 3 ) ) ).add( 'bob' );
    }

    @IsTest
    private static void verifyTimesMethodHasBeenCalledWithMatchers(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'bob1' );
        mockList.add( 'bob2' );
        mockList.add( 'bob3' );

        // Then - validate
        ( ( fflib_MyList.IList ) mocks.verify( mockList, mocks.times( 3 ) ) ).add( fflib_Match.anyString() );
    }

    @IsTest
    private static void thatVerifyTimesMethodFailsWhenCalledLessTimes(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'bob' );
        mockList.add( 'bob' );
        mockList.add( 'bob' );

        // Then - validate
        try{
            ( ( fflib_MyList.IList ) mocks.verify( mockList, mocks.times( 4 ) ) ).add( 'bob' );
            System.Assert.fail( 'Expected an exception to be thrown. This assertion should never be triggered' );
        } catch( Exception exc ){
            assertFailMessage( exc.getMessage(), 4, 3 );
        }
    }

    @IsTest
    private static void thatVerifyTimesMethodFailsWhenCalledMoreTimes(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'bob' );
        mockList.add( 'bob' );
        mockList.add( 'bob' );

        // Then - validate
        try{
            ( ( fflib_MyList.IList ) mocks.verify( mockList, mocks.times( 2 ) ) ).add( 'bob' );
            System.Assert.fail( 'Expected an exception to be thrown. This assertion should never be triggered' );
        } catch( Exception exc ){
            assertFailMessage( exc.getMessage(), 2, 3 );
        }
    }

    @IsTest
    private static void thatVerifyTimesMethodFailsWhenCalledLessTimesWithMatchers(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'bob' );
        mockList.add( 'bob' );
        mockList.add( 'bob' );

        // Then - validate
        try{
            ( ( fflib_MyList.IList ) mocks.verify( mockList, mocks.times( 4 ) ) ).add( fflib_Match.anyString() );
            System.Assert.fail( 'Expected an exception to be thrown. This assertion should never be triggered' );
        } catch( Exception exc ){
            assertFailMessage( exc.getMessage(), 4, 3 );
        }
    }

    @IsTest
    private static void thatVerifyTimesMethodFailsWhenCalledMoreTimesWithMatchers(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'bob' );
        mockList.add( 'bob' );
        mockList.add( 'bob' );

        // Then - validate
        try{
            ( ( fflib_MyList.IList ) mocks.verify( mockList, mocks.times( 2 ) ) ).add( fflib_Match.anyString() );
            System.Assert.fail( 'Expected an exception to be thrown. This assertion should never be triggered' );
        } catch( Exception exc ){
            assertFailMessage( exc.getMessage(), 2, 3 );
        }
    }

    @IsTest
    private static void thatCustomMessageIsAdded(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'bob' );
        mockList.add( 'bob' );
        mockList.add( 'bob' );

        String customAssertMessage = 'Custom message to explain the reason of the verification';

        // Then - validate
        try{
            ( ( fflib_MyList.IList ) mocks.verify( mockList, mocks.times( 2 ).description( customAssertMessage ) ) ).add( fflib_Match.anyString() );
            System.Assert.fail( 'Expected an exception to be thrown. This assertion should never be triggered' );
        } catch( Exception exc ){
            System.Assert.areEqual( 'EXPECTED COUNT: 2'
                + '\nACTUAL COUNT: 3'
                + '\nMETHOD: fflib_MyList__sfdc_ApexStub.add(String)'
                + '\nCustom message to explain the reason of the verification'
                + '\n---'
                + '\nACTUAL ARGS: ("bob"), ("bob"), ("bob")'
                + '\n---'
                + '\nEXPECTED ARGS: [any String]',
                exc.getMessage(),
                'Unexpected verify fail message' );
        }
    }

    @IsTest
    private static void thatVerifiesAtLeastNumberOfTimes(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'bob' );
        mockList.add( 'fred' );
        mockList.add( 'bob' );
        mockList.add( 'bob' );

        // Then - validate
        ( ( fflib_MyList.IList ) mocks.verify( mockList, mocks.atLeast( 2 ) ) ).add( 'bob' );
    }

    @IsTest
    private static void thatVerifiesAtLeastNumberOfTimesWhenIsCalledMoreTimes(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'bob' );
        mockList.add( 'fred' );
        mockList.add( 'bob' );
        mockList.add( 'fred' );
        mockList.add( 'bob' );
        mockList.add( 'fred' );

        // Then - validate
        ( ( fflib_MyList.IList ) mocks.verify( mockList, mocks.atLeast( 2 ) ) ).add( 'bob' );
    }

    @IsTest
    private static void thatThrownExceptionIfCalledLessThanAtLeastNumberOfTimes(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'bob' );
        mockList.add( 'fred' );
        mockList.add( 'bob' );

        // Then - validate
        try{
            ( ( fflib_MyList.IList ) mocks.verify( mockList, mocks.atLeast( 3 ) ) ).add( 'bob' );
            System.Assert.fail( 'Expected fflib_ApexMocks.ApexMocksException exception to be thrown. This assertion should never be triggered' );
        } catch( fflib_ApexMocks.ApexMocksException ex ){
            System.Assert.areEqual( 'EXPECTED COUNT: 3 or more times'
                + '\nACTUAL COUNT: 2'
                + '\nMETHOD: fflib_MyList__sfdc_ApexStub.add(String)'
                + '\n---'
                + '\nACTUAL ARGS: ("bob"), ("fred"), ("bob")'
                + '\n---'
                + '\nEXPECTED ARGS: "bob"',
                ex.getMessage(),
                'Unexpected verify fail message' );
        }
    }

    @IsTest
    private static void thatVerifiesAtLeastNumberOfTimesWithMatchers(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'bob' );
        mockList.add( 'fred' );

        // Then - validate
        ( ( fflib_MyList.IList ) mocks.verify( mockList, mocks.atLeast( 2 ) ) ).add( fflib_Match.anyString() );
    }

    @IsTest
    private static void thatVerifiesAtLeastNumberOfTimesWhenIsCalledMoreTimesWithMatchers(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'bob' );
        mockList.add( 'fred' );
        mockList.add( 'fred' );
        mockList.add( 'fred' );

        // Then - validate
        ( ( fflib_MyList.IList ) mocks.verify( mockList, mocks.atLeast( 2 ) ) ).add( fflib_Match.anyString() );
    }

    @IsTest
    private static void thatThrownExceptionIfCalledLessThanAtLeastNumberOfTimesWithMatchers(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'bob' );
        mockList.add( 'fred' );

        // Then - validate
        try{
            ( ( fflib_MyList.IList ) mocks.verify( mockList, mocks.atLeast( 3 ) ) ).add( fflib_Match.anyString() );
            System.Assert.fail( 'Expected fflib_ApexMocks.ApexMocksException exception to be thrown. This assertion should never be triggered' );
        } catch( fflib_ApexMocks.ApexMocksException ex ){
            System.Assert.areEqual( 'EXPECTED COUNT: 3 or more times'
                + '\nACTUAL COUNT: 2'
                + '\nMETHOD: fflib_MyList__sfdc_ApexStub.add(String)'
                + '\n---'
                + '\nACTUAL ARGS: ("bob"), ("fred")'
                + '\n---'
                + '\nEXPECTED ARGS: [any String]',
                ex.getMessage(),
                'Unexpected verify fail message' );
        }
    }

    @IsTest
    private static void thatVerifiesAtMostNumberOfTimes(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'bob' );
        mockList.add( 'fred' );
        mockList.add( 'bob' );
        mockList.add( 'bob' );
        mockList.add( 'fred' );

        // Then - validate
        ( ( fflib_MyList.IList ) mocks.verify( mockList, mocks.atMost( 5 ) ) ).add( 'bob' );
    }

    @IsTest
    private static void thatVerifiesAtMostSameNumberOfTimes(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'bob' );
        mockList.add( 'fred' );
        mockList.add( 'bob' );
        mockList.add( 'bob' );
        mockList.add( 'fred' );

        // Then - validate
        ( ( fflib_MyList.IList ) mocks.verify( mockList, mocks.atMost( 3 ) ) ).add( 'bob' );
    }

    @IsTest
    private static void thatThrownExceptionIfCalledMoreThanAtMostNumberOfTimes(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'bob' );
        mockList.add( 'fred' );
        mockList.add( 'fred' );
        mockList.add( 'bob' );
        mockList.add( 'bob' );
        mockList.add( 'bob' );
        mockList.add( 'fred' );

        // Then - validate
        try{
            ( ( fflib_MyList.IList ) mocks.verify( mockList, mocks.atMost( 3 ) ) ).add( 'bob' );
            System.Assert.fail( 'Expected fflib_ApexMocks.ApexMocksException exception to be thrown. This assertion should never be triggered' );
        } catch( fflib_ApexMocks.ApexMocksException ex ){
            System.Assert.areEqual( 'EXPECTED COUNT: 3 or fewer times'
                + '\nACTUAL COUNT: 4'
                + '\nMETHOD: fflib_MyList__sfdc_ApexStub.add(String)'
                + '\n---'
                + '\nACTUAL ARGS: ("bob"), ("fred"), ("fred"), ("bob"), ("bob"), ("bob"), ("fred")'
                + '\n---'
                + '\nEXPECTED ARGS: "bob"',
                ex.getMessage(),
                'Unexpected verify fail message' );
        }
    }

    @IsTest
    private static void thatVerifiesAtMostNumberOfTimesWithMatchers(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'bob' );
        mockList.add( 'fred' );
        mockList.add( 'fred' );

        // Then - validate
        ( ( fflib_MyList.IList ) mocks.verify( mockList, mocks.atMost( 5 ) ) ).add( fflib_Match.anyString() );
    }

    @IsTest
    private static void thatVerifiesAtMostSameNumberOfTimesWithMatchers(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'bob' );
        mockList.add( 'fred' );
        mockList.add( 'fred' );

        // Then - validate
        ( ( fflib_MyList.IList ) mocks.verify( mockList, mocks.atMost( 3 ) ) ).add( fflib_Match.anyString() );
    }

    @IsTest
    private static void thatThrownExceptionIfCalledMoreThanAtMostNumberOfTimesWithMatchers(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'bob' );
        mockList.add( 'fred' );
        mockList.add( 'fred' );
        mockList.add( 'fred' );

        // Then - validate
        try{
            ( ( fflib_MyList.IList ) mocks.verify( mockList, mocks.atMost( 3 ) ) ).add( fflib_Match.anyString() );
            System.Assert.fail( 'Expected fflib_ApexMocks.ApexMocksException exception to be thrown. This assertion should never be triggered' );
        } catch( fflib_ApexMocks.ApexMocksException ex ){
            System.Assert.areEqual( 'EXPECTED COUNT: 3 or fewer times'
                + '\nACTUAL COUNT: 4'
                + '\nMETHOD: fflib_MyList__sfdc_ApexStub.add(String)'
                + '\n---'
                + '\nACTUAL ARGS: ("bob"), ("fred"), ("fred"), ("fred")'
                + '\n---'
                + '\nEXPECTED ARGS: [any String]'
                , ex.getMessage(),
                'Unexpected verify fail message' );
        }
    }

    @IsTest
    private static void thatVerifiesAtLeastOnceNumberOfTimes(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'bob' );
        mockList.add( 'fred' );
        mockList.add( 'fred' );

        // Then - validate
        ( ( fflib_MyList.IList ) mocks.verify( mockList, mocks.atLeastOnce() ) ).add( 'bob' );
    }

    @IsTest
    private static void thatVerifiesAtLeastOnceNumberOfTimesWhenIsCalledMoreTimes(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'bob' );
        mockList.add( 'fred' );
        mockList.add( 'bob' );
        mockList.add( 'fred' );

        // Then - validate
        ( ( fflib_MyList.IList ) mocks.verify( mockList, mocks.atLeastOnce() ) ).add( 'bob' );
    }

    @IsTest
    private static void thatThrownExceptionIfCalledLessThanAtLeastOnceNumberOfTimes(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'rob' );
        mockList.add( 'fred' );

        // Then - validate
        try{
            ( ( fflib_MyList.IList ) mocks.verify( mockList, mocks.atLeastOnce() ) ).add( 'bob' );
            System.Assert.fail( 'Expected fflib_ApexMocks.ApexMocksException exception to be thrown. This assertion should never be triggered' );
        } catch( fflib_ApexMocks.ApexMocksException ex ){
            System.Assert.areEqual( 'EXPECTED COUNT: 1 or more times'
                + '\nACTUAL COUNT: 0'
                + '\nMETHOD: fflib_MyList__sfdc_ApexStub.add(String)'
                + '\n---'
                + '\nACTUAL ARGS: ("rob"), ("fred")'
                + '\n---'
                + '\nEXPECTED ARGS: "bob"',
                ex.getMessage(),
                'Unexpected verify fail message' );
        }
    }

    @IsTest
    private static void thatVerifiesAtLeastOnceNumberOfTimesWithMatchers(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'bob' );
        mockList.add( 'fred', 'fred', 'fred', 'fred' );

        // Then - validate
        ( ( fflib_MyList.IList ) mocks.verify( mockList, mocks.atLeastOnce() ) ).add( fflib_Match.anyString() );
    }

    @IsTest
    private static void thatVerifiesAtLeastOnceNumberOfTimesWhenIsCalledMoreTimesWithMatchers(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'bob' );
        mockList.add( 'fred', 'fred', 'fred', 'fred' );
        mockList.add( 'bob' );
        mockList.add( 'fred', 'fred', 'fred', 'fred' );
        mockList.add( 'bob' );
        mockList.add( 'fred', 'fred', 'fred', 'fred' );

        // Then - validate
        ( ( fflib_MyList.IList ) mocks.verify( mockList, mocks.atLeastOnce() ) ).add( fflib_Match.anyString() );
    }

    @IsTest
    private static void thatThrownExceptionIfCalledLessThanAtLeastOnceNumberOfTimesWithMatchers(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'fred', 'fred', 'fred', 'fred' );
        mockList.add( 'fred', 'fred', 'fred', 'fred' );
        mockList.add( 'fred', 'fred', 'fred', 'fred' );

        // Then - validate
        try{
            ( ( fflib_MyList.IList ) mocks.verify( mockList, mocks.atLeastOnce() ) ).add( fflib_Match.anyString() );
            System.Assert.fail( 'Expected fflib_ApexMocks.ApexMocksException exception to be thrown. This assertion should never be triggered' );
        } catch( fflib_ApexMocks.ApexMocksException ex ){
            System.Assert.areEqual( 'EXPECTED COUNT: 1 or more times'
                + '\nACTUAL COUNT: 0'
                + '\nMETHOD: fflib_MyList__sfdc_ApexStub.add(String)'
                + '\n---'
                + '\nACTUAL ARGS: ()'
                + '\n---'
                + '\nEXPECTED ARGS: [any String]',
                ex.getMessage(),
                'Unexpected verify fail message' );
        }
    }

    @IsTest
    private static void thatVerifiesBetweenNumberOfTimes(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'bob' );
        mockList.add( 'fred' );
        mockList.add( 'bob' );
        mockList.add( 'fred' );
        mockList.add( 'bob' );
        mockList.add( 'fred' );
        mockList.add( 'bob' );
        mockList.add( 'fred' );

        // Then - validate
        ( ( fflib_MyList.IList ) mocks.verify( mockList, mocks.between( 3, 5 ) ) ).add( 'bob' );
    }

    @IsTest
    private static void thatBetweenThrownExceptionIfCalledLessThanAtLeastNumberOfTimes(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'bob' );
        mockList.add( 'fred' );
        mockList.add( 'bob' );

        // Then - validate
        try{
            ( ( fflib_MyList.IList ) mocks.verify( mockList, mocks.between( 3, 5 ) ) ).add( 'bob' );
            System.Assert.fail( 'Expected fflib_ApexMocks.ApexMocksException exception to be thrown. This assertion should never be triggered' );
        } catch( fflib_ApexMocks.ApexMocksException ex ){
            System.Assert.areEqual( 'EXPECTED COUNT: 3 or more times'
                + '\nACTUAL COUNT: 2'
                + '\nMETHOD: fflib_MyList__sfdc_ApexStub.add(String)'
                + '\n---'
                + '\nACTUAL ARGS: ("bob"), ("fred"), ("bob")'
                + '\n---'
                + '\nEXPECTED ARGS: "bob"',
                ex.getMessage()
            );
        }
    }

    @IsTest
    private static void thatVerifiesBetweenNumberOfTimesWithMatchers(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'bob' );
        mockList.add( 'fred' );
        mockList.add( 'fred' );
        mockList.add( 'bob' );

        // Then - validate
        ( ( fflib_MyList.IList ) mocks.verify( mockList, mocks.between( 3, 5 ) ) ).add( fflib_Match.anyString() );
    }

    @IsTest
    private static void thatBetweenThrownExceptionIfCalledLessThanAtLeastNumberOfTimesWithMatchers(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'bob' );
        mockList.add( 'fred' );

        // Then - validate
        try{
            ( ( fflib_MyList.IList ) mocks.verify( mockList, mocks.between( 3, 5 ) ) ).add( fflib_Match.anyString() );
            System.Assert.fail( 'Expected fflib_ApexMocks.ApexMocksException exception to be thrown. This assertion should never be triggered' );
        } catch( fflib_ApexMocks.ApexMocksException ex ){
            System.Assert.areEqual( 'EXPECTED COUNT: 3 or more times'
                + '\nACTUAL COUNT: 2'
                + '\nMETHOD: fflib_MyList__sfdc_ApexStub.add(String)'
                + '\n---'
                + '\nACTUAL ARGS: ("bob"), ("fred")'
                + '\n---'
                + '\nEXPECTED ARGS: [any String]',
                ex.getMessage()
            );
        }
    }

    @IsTest
    private static void thatBetweenThrownExceptionIfCalledMoreThanAtMostNumberOfTimes(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'bob' );
        mockList.add( 'fred' );
        mockList.add( 'fred' );
        mockList.add( 'bob' );
        mockList.add( 'bob' );
        mockList.add( 'bob' );
        mockList.add( 'bob' );
        mockList.add( 'bob' );
        mockList.add( 'fred' );

        // Then - validate
        try{
            ( ( fflib_MyList.IList ) mocks.verify( mockList, mocks.between( 3, 5 ) ) ).add( 'bob' );
            System.Assert.fail( 'Expected fflib_ApexMocks.ApexMocksException exception to be thrown. This assertion should never be triggered' );
        } catch( fflib_ApexMocks.ApexMocksException ex ){
            System.Assert.areEqual( 'EXPECTED COUNT: 5 or fewer times'
                + '\nACTUAL COUNT: 6'
                + '\nMETHOD: fflib_MyList__sfdc_ApexStub.add(String)'
                + '\n---'
                + '\nACTUAL ARGS: ("bob"), ("fred"), ("fred"), ("bob"), ("bob"), ("bob"), ("bob"), ("bob"), ("fred")'
                + '\n---'
                + '\nEXPECTED ARGS: "bob"',
                ex.getMessage()
            );
        }
    }

    @IsTest
    private static void thatBetweenThrownExceptionIfCalledMoreThanAtMostNumberOfTimesWithMatchers(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'bob' );
        mockList.add( 'fred' );
        mockList.add( 'bob' );
        mockList.add( 'fred' );
        mockList.add( 'fred' );
        mockList.add( 'fred' );

        // Then - validate
        try{
            ( ( fflib_MyList.IList ) mocks.verify( mockList, mocks.between( 3, 5 ) ) ).add( fflib_Match.anyString() );
            System.Assert.fail( 'Expected fflib_ApexMocks.ApexMocksException exception to be thrown. This assertion should never be triggered' );
        } catch( fflib_ApexMocks.ApexMocksException ex ){
            System.Assert.areEqual( 'EXPECTED COUNT: 5 or fewer times'
                + '\nACTUAL COUNT: 6'
                + '\nMETHOD: fflib_MyList__sfdc_ApexStub.add(String)'
                + '\n---'
                + '\nACTUAL ARGS: ("bob"), ("fred"), ("bob"), ("fred"), ("fred"), ("fred")'
                + '\n---'
                + '\nEXPECTED ARGS: [any String]',
                ex.getMessage(),
                'Unexpected verify fail message' );
        }
    }

    @IsTest
    private static void verifyNeverMethodHasNotBeenCalled(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'bob1' );
        mockList.add( 'bob2' );
        mockList.add( 'bob3' );

        // Then - validate
        ( ( fflib_MyList.IList ) mocks.verify( mockList, mocks.never() ) ).add( 'bob' );
    }

    @IsTest
    private static void verifyNeverMethodHasBeenNotCalledWithMatchers(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'fred', 'fred', 'fred', 'fred' );
        mockList.add( 'fred', 'fred', 'fred', 'fred' );
        mockList.add( 'fred', 'fred', 'fred', 'fred' );

        // Then - validate
        ( ( fflib_MyList.IList ) mocks.verify( mockList, mocks.never() ) ).add( fflib_Match.anyString() );
    }

    @IsTest
    private static void thatVerifyNeverFailsWhenCalledMoreTimes(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'bob' );
        mockList.add( 'bob' );

        // Then - validate
        try{
            ( ( fflib_MyList.IList ) mocks.verify( mockList, mocks.never() ) ).add( 'bob' );
            System.Assert.fail( 'Expected an exception to be thrown. This assertion should never be triggered' );
        } catch( Exception exc ){
            assertFailMessage( exc.getMessage(), 0, 2 );
        }
    }

    @IsTest
    private static void thatVerifyNeverFailsWhenCalledMoreTimesWithMatchers(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'bob' );
        mockList.add( 'bob' );
        mockList.add( 'bob' );

        // Then - validate
        try{
            ( ( fflib_MyList.IList ) mocks.verify( mockList, mocks.never() ) ).add( fflib_Match.anyString() );
            System.Assert.fail( 'Expected an exception to be thrown. This assertion should never be triggered' );
        } catch( Exception exc ){
            assertFailMessage( exc.getMessage(), 0, 3 );
        }
    }

    @IsTest
    private static void thatVerifiesAtLeastOnce(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'bob' );
        mockList.add( 'fred' );
        mockList.add( 'bob' );
        mockList.add( 'bob' );

        // Then - validate
        ( ( fflib_MyList.IList ) mocks.verify( mockList, mocks.atLeastOnce() ) ).add( 'bob' );
    }

    @IsTest
    private static void thatVerifiesAtLeastOnceWhenIsCalledMoreTimes(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'bob' );
        mockList.add( 'fred' );
        mockList.add( 'bob' );
        mockList.add( 'fred' );
        mockList.add( 'bob' );
        mockList.add( 'fred' );

        // Then - validate
        ( ( fflib_MyList.IList ) mocks.verify( mockList, mocks.atLeastOnce() ) ).add( 'bob' );
    }

    @IsTest
    private static void thatThrownExceptionIfCalledLessThanAtLeastOnce(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'bob' );
        mockList.add( 'fred' );
        mockList.add( 'bob' );

        // Then - validate
        try{
            ( ( fflib_MyList.IList ) mocks.verify( mockList, mocks.atLeastOnce() ) ).add( 'rob' );
            System.Assert.fail( 'Expected fflib_ApexMocks.ApexMocksException exception to be thrown. This assertion should never be triggered' );
        } catch( fflib_ApexMocks.ApexMocksException ex ){
            System.Assert.areEqual( 'EXPECTED COUNT: 1 or more times'
                + '\nACTUAL COUNT: 0'
                + '\nMETHOD: fflib_MyList__sfdc_ApexStub.add(String)'
                + '\n---'
                + '\nACTUAL ARGS: ("bob"), ("fred"), ("bob")'
                + '\n---'
                + '\nEXPECTED ARGS: "rob"',
                ex.getMessage(),
                'Unexpected verify fail message' );
        }
    }

    @IsTest
    private static void thatVerifiesAtLeastOnceWithMatchers(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'bob' );
        mockList.add( 'fred' );

        // Then - validate
        ( ( fflib_MyList.IList ) mocks.verify( mockList, mocks.atLeastOnce() ) ).add( fflib_Match.anyString() );
    }

    @IsTest
    private static void thatVerifiesAtLeastOnceWhenIsCalledMoreTimesWithMatchers(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'bob' );
        mockList.add( 'fred' );
        mockList.add( 'fred' );
        mockList.add( 'fred' );

        // Then - validate
        ( ( fflib_MyList.IList ) mocks.verify( mockList, mocks.atLeastOnce() ) ).add( fflib_Match.anyString() );
    }

    @IsTest
    private static void thatThrownExceptionIfCalledLessThanAtLeastOnceWithMatchers(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'bob' );
        mockList.add( 'fred' );

        // Then - validate
        try{
            ( ( fflib_MyList.IList ) mocks.verify( mockList, mocks.atLeastOnce() ) ).add( fflib_Match.stringStartsWith( 'rob' ) );
            System.Assert.fail( 'Expected fflib_ApexMocks.ApexMocksException exception to be thrown. This assertion should never be triggered' );
        } catch( fflib_ApexMocks.ApexMocksException ex ){
            System.Assert.areEqual( 'EXPECTED COUNT: 1 or more times'
                + '\nACTUAL COUNT: 0'
                + '\nMETHOD: fflib_MyList__sfdc_ApexStub.add(String)'
                + '\n---'
                + '\nACTUAL ARGS: ("bob"), ("fred")'
                + '\n---'
                + '\nEXPECTED ARGS: [starts with "rob"]',
                ex.getMessage(),
                'Unexpected verify fail message' );
        }
    }

    @IsTest
    private static void validateMode_shouldThrowExceptionWhenModeMismatches(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );
        fflib_VerificationMode verificationMode = new fflib_VerificationMode();

        // This will trigger an exception in the validateMode() in the actual verifier, since the calls() method
        // is available only in the InOrder verification.
        verificationMode.method = fflib_VerificationMode.modeName.CALLS;

        // When - perform test
        mockList.add( 'bob' );

        // When, Then
        try{
            ( ( fflib_MyList.IList ) mocks.verify( mockList, verificationMode ) ).add( fflib_Match.anyString() );
            System.Assert.fail( 'Expected fflib_ApexMocks.ApexMocksException exception to be thrown. This assertion should never be triggered' );
        } catch( fflib_ApexMocks.ApexMocksException ex ){
            String expectedMessage = 'The calls() method is available only in the InOrder Verification.';
            String actualMessage = ex.getMessage();
            System.Assert.areEqual( expectedMessage, actualMessage,
                'The exception has been caught as expected, however the message is not as expected' );
        }
    }

    /**
     * Helper methods.
     */
    private static void assertFailMessage( String exceptionMessage, Integer expectedInvocations, Integer actualsInvocations ){
        System.Assert.isTrue(
            exceptionMessage.startsWith( 'EXPECTED COUNT: ' + expectedInvocations + '\nACTUAL COUNT: ' + actualsInvocations ),
            'Unexpected verify fail message: ' + exceptionMessage
        );
    }

    /**
     * Helper classes.
     */
    private class isOdd implements fflib_IMatcher{
        public Boolean matches( Object arg ){
            return arg instanceof Integer ? Math.mod( ( Integer ) arg, 2 ) == 1 : false;
        }
    }

    private class isEven implements fflib_IMatcher{
        public Boolean matches( Object arg ){
            return arg instanceof Integer ? Math.mod( ( Integer ) arg, 2 ) == 0 : false;
        }
    }
}
