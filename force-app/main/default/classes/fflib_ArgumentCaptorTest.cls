/**
 * Copyright (c), FinancialForce.com, inc
 * Copyright (c) 2019, Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
@IsTest( isParallel = true )
@SuppressWarnings('PMD.ClassNamingConventions, PMD.ApexUnitTestClassShouldHaveRunAs')
private with sharing class fflib_ArgumentCaptorTest{

    @IsTest
    private static void thatArgumentValueIsCaptured(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'Fred' );

        // Then - validate
        fflib_ArgumentCaptor argument = fflib_ArgumentCaptor.forClass( String.class );
        ( ( fflib_MyList.IList ) mocks.verify( mockList ) ).add( ( String ) argument.capture() );

        System.Assert.areEqual( 'Fred', ( String ) argument.getValue(), 'the argument captured is not as expected' );
    }

    @IsTest
    private static void thatCanPerformFurtherAssertionsOnCapturedArgumentValue(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        TestInnerClass testValue = new TestInnerClass();
        testValue.i = 4;
        testValue.s = '5';

        mockList.set( 1, testValue );

        // Then - validate
        fflib_ArgumentCaptor argument = fflib_ArgumentCaptor.forClass( TestInnerClass.class );

        ( ( fflib_MyList.IList ) mocks.verify( mockList ) ).set( fflib_Match.anyInteger(), argument.capture() );

        Object capturedArg = argument.getValue();
        System.Assert.isNotNull( capturedArg, 'CapturedArg should not be null' );

        System.Assert.isInstanceOfType( capturedArg, TestInnerClass.class, 'CapturedArg should be SObject, instead was ' + capturedArg );

        TestInnerClass testValueCaptured = ( TestInnerClass ) capturedArg;

        System.Assert.areEqual( 4, testValueCaptured.i, 'the values inside the argument captured should be the same of the original one' );
        System.Assert.areEqual( '5', testValueCaptured.s, 'the values inside the argument captured should be the same of the original one' );
    }

    @IsTest
    private static void thatCaptureArgumentOnlyFromVerifiedMethod(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'Fred' );
        // The next call should be ignored because is not the method that has under verify,
        // Even if have the same type specified in the captor.
        mockList.addMore( 'Barney' );

        // Then - validate
        fflib_ArgumentCaptor argument = fflib_ArgumentCaptor.forClass( String.class );
        ( ( fflib_MyList.IList ) mocks.verify( mockList ) ).add( ( String ) argument.capture() );

        System.Assert.areEqual( 'Fred', ( String ) argument.getValue(), 'the argument captured is not as expected' );
        System.Assert.areEqual( 1, argument.getAllValues().size(), 'the argument captured should be only one' );
    }

    @IsTest
    private static void thatCaptureAllArgumentsForTheVerifiedMethods(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        List<String> stringList = new List<String>{ '3' };

        // When - perform test
        mockList.add( 'Fred' );
        mockList.add( stringList );

        mockList.clear();

        // Then - validate
        fflib_ArgumentCaptor argument = fflib_ArgumentCaptor.forClass( String.class );

        ( ( fflib_MyList.IList ) mocks.verify( mockList ) ).add( ( String ) argument.capture() );
        ( ( fflib_MyList.IList ) mocks.verify( mockList ) ).add( ( List<String> ) argument.capture() );

        System.Assert.areEqual( stringList, ( List<String> ) argument.getValue(), 'the argument captured is not as expected' );

        List<Object> argsCaptured = argument.getAllValues();

        System.Assert.areEqual( 2, argsCaptured.size(), 'expected 2 argument to be captured' );
        System.Assert.areEqual( 'Fred', ( String ) argsCaptured[ 0 ], 'the first value is not as expected' );
    }

    @IsTest
    private static void thatCaptureArgumentFromRequestedParameter(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'Fred', 'Barney', 'Wilma', 'Betty' );

        // Then - validate
        fflib_ArgumentCaptor argument = fflib_ArgumentCaptor.forClass( String.class );

        ( ( fflib_MyList.IList ) mocks.verify( mockList ) )
            .add(
                ( String ) fflib_Match.eq( 'Fred' ),
                ( String ) fflib_Match.eq( 'Barney' ),
                ( String ) argument.capture(),
                ( String ) fflib_Match.eq( 'Betty' ) );

        System.Assert.areEqual( 'Wilma', ( String ) argument.getValue(), 'the argument captured is not as expected, should be Wilma because is the 3rd parameter in the call' );
    }

    @IsTest
    private static void thatCaptureLastArgument(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'Barney' );
        mockList.add( 'Fred' );

        // Then - validate
        fflib_ArgumentCaptor argument = fflib_ArgumentCaptor.forClass( String.class );

        ( ( fflib_MyList.IList ) mocks.verify( mockList, 2 ) ).add( ( String ) argument.capture() );

        System.Assert.areEqual( 'Fred', ( String ) argument.getValue(), 'the argument captured is not as expected' );
    }

    @IsTest
    private static void thatCaptureAllArguments(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'Fred' );
        mockList.add( 'Barney' );
        mockList.add( 'Wilma' );
        mockList.add( 'Betty' );

        // Then - validate
        fflib_ArgumentCaptor argument = fflib_ArgumentCaptor.forClass( String.class );

        ( ( fflib_MyList.IList ) mocks.verify( mockList, 4 ) ).add( ( String ) argument.capture() );

        List<Object> argsCaptured = argument.getAllValues();

        System.Assert.areEqual( 4, argsCaptured.size(), 'expected 4 argument to be captured' );
        System.Assert.areEqual( 'Fred', ( String ) argsCaptured[ 0 ], 'the first value is not as expected' );
        System.Assert.areEqual( 'Barney', ( String ) argsCaptured[ 1 ], 'the second value is not as expected' );
        System.Assert.areEqual( 'Wilma', ( String ) argsCaptured[ 2 ], 'the third value is not as expected' );
        System.Assert.areEqual( 'Betty', ( String ) argsCaptured[ 3 ], 'the forth value is not as expected' );
    }

    @IsTest
    private static void thatCaptureAllArgumentsFromMultipleMethods(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'Fred' );
        mockList.add( 'Barney' );
        mockList.get2( 3, 'pebble' );

        // Then - validate
        fflib_ArgumentCaptor argument = fflib_ArgumentCaptor.forClass( String.class );

        ( ( fflib_MyList.IList ) mocks.verify( mockList, 2 ) ).add( ( String ) argument.capture() );

        ( ( fflib_MyList.IList ) mocks.verify( mockList ) )
            .get2(
                ( Integer ) fflib_Match.eq( 3 ),
                ( String ) argument.capture() );

        List<Object> argsCaptured = argument.getAllValues();

        System.Assert.areEqual( 3, argsCaptured.size(), 'expected 3 argument to be captured' );
        System.Assert.areEqual( 'Fred', ( String ) argsCaptured[ 0 ], 'the first value is not as expected' );
        System.Assert.areEqual( 'Barney', ( String ) argsCaptured[ 1 ], 'the second value is not as expected' );
        System.Assert.areEqual( 'pebble', ( String ) argsCaptured[ 2 ], 'the third value is not as expected' );
    }

    @IsTest
    private static void thatCanHandleMultipleCapturesInOneMethodCall(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'Fred', 'Barney', 'Wilma', 'Betty' );

        // Then - validate
        fflib_ArgumentCaptor argument = fflib_ArgumentCaptor.forClass( String.class );

        ( ( fflib_MyList.IList ) mocks.verify( mockList ) )
            .add(
                ( String ) fflib_Match.eq( 'Fred' ),
                ( String ) argument.capture(),
                ( String ) argument.capture(),
                ( String ) fflib_Match.eq( 'Betty' ) );

        List<Object> argsCaptured = argument.getAllValues();

        System.Assert.areEqual( 2, argsCaptured.size(), 'expected 2 argument to be captured' );
        System.Assert.areEqual( 'Barney', ( String ) argsCaptured[ 0 ], 'the first value is not as expected' );
        System.Assert.areEqual( 'Wilma', ( String ) argsCaptured[ 1 ], 'the second value is not as expected' );
    }

    @IsTest
    private static void thatDoesNotCaptureIfNotVerified(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( '3' );

        // Then - validate
        fflib_ArgumentCaptor argument = fflib_ArgumentCaptor.forClass( List<String>.class );

        ( ( fflib_MyList.IList ) mocks.verify( mockList, fflib_ApexMocks.NEVER ) )
            .add( ( List<String> ) argument.capture() );

        List<Object> argsCaptured = argument.getAllValues();

        System.Assert.areEqual( 0, argsCaptured.size(), 'expected 0 argument to be captured' );
        System.Assert.isNull( argument.getValue(), 'no value should be captured, so must return null' );
    }

    @IsTest
    private static void thatCaptureOnlyMethodsThatMatchesWithOtherMatcherAsWell(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'Same', 'Same', 'First call', 'First call' );
        mockList.add( 'Same', 'Same', 'Second call', 'Second call' );

        // Then - validate
        fflib_ArgumentCaptor argument = fflib_ArgumentCaptor.forClass( String.class );

        ( ( fflib_MyList.IList ) mocks.verify( mockList ) ).add(
            fflib_Match.eqString( 'Same' ),
            fflib_Match.eqString( 'Same' ),
            ( String ) argument.capture(),
            fflib_Match.eqString( 'First call' ) );

        System.Assert.areEqual( 'First call', ( String ) argument.getValue() );
    }

    @IsTest
    private static void thatDoesNotCaptureAnythingWhenCaptorIsWrappedInAMatcher(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'Same', 'Same', 'First call', 'First call' );
        mockList.add( 'Same', 'Same', 'Second call', 'Second call' );

        // Then - validate
        fflib_ArgumentCaptor argument = fflib_ArgumentCaptor.forClass( String.class );

        ( ( fflib_MyList.IList ) mocks.verify( mockList ) ).add(
            ( String ) fflib_Match.allOf(
                fflib_Match.eqString( 'Same' ),
                fflib_Match.eqString( 'Same' ),
                argument.capture() ),
            ( String ) fflib_Match.allOf(
                fflib_Match.eqString( 'Same' ),
                fflib_Match.eqString( 'Same' ),
                argument.capture() ),
            ( String ) fflib_Match.allOf(
                argument.capture(),
                fflib_Match.eqString( 'First call' ) ),
            ( String ) fflib_Match.allOf(
                argument.capture(),
                fflib_Match.eqString( 'First call' ) )
        );

        List<Object> capturedValues = argument.getAllValues();

        System.Assert.areEqual( 0, capturedValues.size(), 'nothing should have been capture because the matcher it not really a capture type, but a allOf()' );
        System.Assert.isNull( ( String ) argument.getValue(), 'nothing should have been capture because the matcher it not really a capture type, but a allOf()' );
    }

    @IsTest
    private static void thatArgumentValueIsCapturedWithInOrderVerification(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( mocks, new List<Object>{ mockList } );

        // When - perform test
        mockList.add( 'Fred' );

        // Then - validate
        fflib_ArgumentCaptor argument = fflib_ArgumentCaptor.forClass( String.class );

        ( ( fflib_MyList.IList ) inOrder1.verify( mockList, mocks.calls( 1 ) ) ).add( ( String ) argument.capture() );

        System.Assert.areEqual( 'Fred', ( String ) argument.getValue(), 'the argument captured is not as expected' );
    }

    @IsTest
    private static void thatCanPerformFurtherAssertionsOnCapturedArgumentValueWithInOrderVerification(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( mocks, new List<Object>{ mockList } );

        // When - perform test
        TestInnerClass testValue = new TestInnerClass();
        testValue.i = 4;
        testValue.s = '5';

        mockList.set( 1, testValue );

        // Then - validate
        fflib_ArgumentCaptor argument = fflib_ArgumentCaptor.forClass( TestInnerClass.class );

        ( ( fflib_MyList.IList ) inOrder1.verify( mockList, mocks.calls( 1 ) ) ).set( fflib_Match.anyInteger(), argument.capture() );

        Object capturedArg = argument.getValue();
        System.Assert.isNotNull( capturedArg, 'CapturedArg should not be null' );

        System.Assert.isInstanceOfType( capturedArg, TestInnerClass.class, 'CapturedArg should be SObject, instead was ' + capturedArg );

        TestInnerClass testValueCaptured = ( TestInnerClass ) capturedArg;

        System.Assert.areEqual( 4, testValueCaptured.i, 'the values inside the argument captured should be the same of the original one' );
        System.Assert.areEqual( '5', testValueCaptured.s, 'the values inside the argument captured should be the same of the original one' );
    }

    @IsTest
    private static void thatCaptureArgumentOnlyFromVerifiedMethodWithInOrderVerification(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( mocks, new List<Object>{ mockList } );

        // When - perform test
        mockList.add( 'Fred' );
        // The next call should be ignored because is not the method that has under verify,
        // even if have the same type specified in the captor.
        mockList.addMore( 'Barney' );

        // Then - validate

        fflib_ArgumentCaptor argument = fflib_ArgumentCaptor.forClass( String.class );
        ( ( fflib_MyList.IList ) inOrder1.verify( mockList, mocks.calls( 1 ) ) ).add( ( String ) argument.capture() );

        System.Assert.areEqual( 'Fred', ( String ) argument.getValue(), 'the argument captured is not as expected' );
        System.Assert.areEqual( 1, argument.getAllValues().size(), 'the argument captured should be only one' );
    }

    @IsTest
    private static void thatCaptureAllArgumentsForTheVerifiedMethodsWithInOrderVerification(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( mocks, new List<Object>{ mockList } );

        List<String> stringList = new List<String>{ '3' };
        // When - perform test
        mockList.add( 'Fred' );
        mockList.add( stringList );

        mockList.clear();

        // Then - validate
        fflib_ArgumentCaptor argument = fflib_ArgumentCaptor.forClass( String.class );

        ( ( fflib_MyList.IList ) inOrder1.verify( mockList, mocks.calls( 1 ) ) ).add( ( String ) argument.capture() );
        ( ( fflib_MyList.IList ) inOrder1.verify( mockList, mocks.calls( 1 ) ) ).add( ( List<String> ) argument.capture() );

        System.Assert.areEqual( stringList, ( List<String> ) argument.getValue(), 'the argument captured is not as expected' );

        List<Object> argsCaptured = argument.getAllValues();

        System.Assert.areEqual( 2, argsCaptured.size(), 'expected 2 argument to be captured' );
        System.Assert.areEqual( 'Fred', ( String ) argsCaptured[ 0 ], 'the first value is not as expected' );
    }

    @IsTest
    private static void thatCaptureArgumentFromRequestedParameterWithInOrderVerification(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( mocks, new List<Object>{ mockList } );

        // When - perform test
        mockList.add( 'Fred', 'Barney', 'Wilma', 'Betty' );

        // Then - validate
        fflib_ArgumentCaptor argument = fflib_ArgumentCaptor.forClass( String.class );

        ( ( fflib_MyList.IList ) inOrder1.verify( mockList, mocks.calls( 1 ) ) )
            .add(
                ( String ) fflib_Match.eq( 'Fred' ),
                ( String ) fflib_Match.eq( 'Barney' ),
                ( String ) argument.capture(),
                ( String ) fflib_Match.eq( 'Betty' ) );

        System.Assert.areEqual( 'Wilma', ( String ) argument.getValue(),
            'the argument captured is not as expected, should be Wilma because is the 3rd parameter in the call' );
    }

    @IsTest
    private static void thatCaptureLastArgumentWithInOrderVerification(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( mocks, new List<Object>{ mockList } );

        // When - perform test
        mockList.add( 'Barney' );
        mockList.add( 'Fred' );

        // Then - validate
        fflib_ArgumentCaptor argument = fflib_ArgumentCaptor.forClass( String.class );

        ( ( fflib_MyList.IList ) inOrder1.verify( mockList, mocks.calls( 2 ) ) ).add( ( String ) argument.capture() );

        System.Assert.areEqual( 'Fred', ( String ) argument.getValue(), 'the argument captured is not as expected' );
    }

    @IsTest
    private static void thatCaptureAllArgumentsWithInOrderVerification(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( mocks, new List<Object>{ mockList } );

        // When - perform test
        mockList.add( 'Fred' );
        mockList.add( 'Barney' );
        mockList.add( 'Wilma' );
        mockList.add( 'Betty' );

        // Then - validate
        fflib_ArgumentCaptor argument = fflib_ArgumentCaptor.forClass( String.class );

        ( ( fflib_MyList.IList ) inOrder1.verify( mockList, mocks.calls( 4 ) ) ).add( ( String ) argument.capture() );

        List<Object> argsCaptured = argument.getAllValues();

        System.Assert.areEqual( 4, argsCaptured.size(), 'expected 4 argument to be captured' );
        System.Assert.areEqual( 'Fred', ( String ) argsCaptured[ 0 ], 'the first value is not as expected' );
        System.Assert.areEqual( 'Barney', ( String ) argsCaptured[ 1 ], 'the second value is not as expected' );
        System.Assert.areEqual( 'Wilma', ( String ) argsCaptured[ 2 ], 'the third value is not as expected' );
        System.Assert.areEqual( 'Betty', ( String ) argsCaptured[ 3 ], 'the forth value is not as expected' );
    }

    @IsTest
    private static void thatCaptureAllArgumentsFromMultipleMethodsWithInOrderVerification(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( mocks, new List<Object>{ mockList } );

        // When - perform test
        mockList.add( 'Fred' );
        mockList.add( 'Barney' );
        mockList.get2( 3, 'pebble' );

        // Then - validate
        fflib_ArgumentCaptor argument = fflib_ArgumentCaptor.forClass( String.class );

        ( ( fflib_MyList.IList ) inOrder1.verify( mockList, mocks.calls( 2 ) ) ).add( ( String ) argument.capture() );

        ( ( fflib_MyList.IList ) inOrder1.verify( mockList, mocks.calls( 1 ) ) )
            .get2(
                ( Integer ) fflib_Match.eq( 3 ),
                ( String ) argument.capture() );

        List<Object> argsCaptured = argument.getAllValues();

        System.Assert.areEqual( 3, argsCaptured.size(), 'expected 3 argument to be captured' );
        System.Assert.areEqual( 'Fred', ( String ) argsCaptured[ 0 ], 'the first value is not as expected' );
        System.Assert.areEqual( 'Barney', ( String ) argsCaptured[ 1 ], 'the second value is not as expected' );
        System.Assert.areEqual( 'pebble', ( String ) argsCaptured[ 2 ], 'the third value is not as expected' );
    }

    @IsTest
    private static void thatCanHandleMultipleCapturesInOneMethodCallWithInOrderVerification(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( mocks, new List<Object>{ mockList } );


        // When - perform test
        mockList.add( 'Fred', 'Barney', 'Wilma', 'Betty' );

        // Then - validate
        fflib_ArgumentCaptor argument = fflib_ArgumentCaptor.forClass( String.class );

        ( ( fflib_MyList.IList ) inOrder1.verify( mockList, mocks.calls( 1 ) ) )
            .add(
                ( String ) fflib_Match.eq( 'Fred' ),
                ( String ) argument.capture(),
                ( String ) argument.capture(),
                ( String ) fflib_Match.eq( 'Betty' ) );

        List<Object> argsCaptured = argument.getAllValues();

        System.Assert.areEqual( 2, argsCaptured.size(), 'expected 2 argument to be captured' );
        System.Assert.areEqual( 'Barney', ( String ) argsCaptured[ 0 ], 'the first value is not as expected' );
        System.Assert.areEqual( 'Wilma', ( String ) argsCaptured[ 1 ], 'the second value is not as expected' );
    }

    @IsTest
    private static void thatDoesNotCaptureIfNotVerifiedWithInOrderVerification(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( mocks, new List<Object>{ mockList } );

        // When - perform test
        mockList.add( '3' );

        // Then - validate
        fflib_ArgumentCaptor argument = fflib_ArgumentCaptor.forClass( List<String>.class );

        ( ( fflib_MyList.IList ) inOrder1.verify( mockList, mocks.never() ) )
            .add( ( List<String> ) argument.capture() );

        List<Object> argsCaptured = argument.getAllValues();

        System.Assert.areEqual( 0, argsCaptured.size(), 'expected 0 argument to be captured' );
        System.Assert.isNull( argument.getValue(), 'no value should be captured, so must return null' );
    }

    @IsTest
    private static void thatCaptureOnlyMethodsThatMatchesWithOtherMatcherAsWellWithInOrderVerification(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( mocks, new List<Object>{ mockList } );

        // When - perform test
        mockList.add( 'Same', 'Same', 'First call', 'First call' );
        mockList.add( 'Same', 'Same', 'Second call', 'Second call' );

        // Then - validate
        fflib_ArgumentCaptor argument = fflib_ArgumentCaptor.forClass( String.class );

        ( ( fflib_MyList.IList ) inOrder1.verify( mockList, mocks.calls( 1 ) ) ).add(
            fflib_Match.eqString( 'Same' ),
            fflib_Match.eqString( 'Same' ),
            ( String ) argument.capture(),
            fflib_Match.eqString( 'First call' ) );

        System.Assert.areEqual( 'First call', ( String ) argument.getValue() );
    }

    @IsTest
    private static void thatDoesNotCaptureAnythingWhenCaptorIsWrappedInAMatcherWithInOrderVerification(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( mocks, new List<Object>{ mockList } );

        // When - perform test
        mockList.add( 'Same', 'Same', 'First call', 'First call' );
        mockList.add( 'Same', 'Same', 'Second call', 'Second call' );

        // Then - validate
        fflib_ArgumentCaptor argument = fflib_ArgumentCaptor.forClass( String.class );

        ( ( fflib_MyList.IList ) inOrder1.verify( mockList, mocks.calls( 1 ) ) ).add(
            ( String ) fflib_Match.allOf(
                fflib_Match.eqString( 'Same' ),
                fflib_Match.eqString( 'Same' ),
                argument.capture() ),
            ( String ) fflib_Match.allOf(
                fflib_Match.eqString( 'Same' ),
                fflib_Match.eqString( 'Same' ),
                argument.capture() ),
            ( String ) fflib_Match.allOf(
                argument.capture(),
                fflib_Match.eqString( 'First call' ) ),
            ( String ) fflib_Match.allOf(
                argument.capture(),
                fflib_Match.eqString( 'First call' ) )
        );

        List<Object> capturedValues = argument.getAllValues();

        System.Assert.areEqual( 0, capturedValues.size(), 'nothing should have been capture because the matcher it not really a capture type, but a allOf()' );
        System.Assert.isNull( ( String ) argument.getValue(), 'nothing should have been capture because the matcher it not really a capture type, but a allOf()' );
    }

    @IsTest
    private static void thatCaptureAllArgumentswhenMethodIsCalledWithTheSameArgument(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'Fred' );
        mockList.add( 'Barney' );
        mockList.add( 'Wilma' );
        mockList.add( 'Barney' );
        mockList.add( 'Barney' );
        mockList.add( 'Betty' );

        // Then - validate
        fflib_ArgumentCaptor argument = fflib_ArgumentCaptor.forClass( String.class );

        ( ( fflib_MyList.IList ) mocks.verify( mockList, 6 ) ).add( ( String ) argument.capture() );

        List<Object> argsCaptured = argument.getAllValues();

        System.Assert.areEqual( 6, argsCaptured.size(), 'expected 6 arguments to be captured' );

        System.Assert.areEqual( 'Fred', ( String ) argsCaptured[ 0 ], 'the first value is not as expected' );
        System.Assert.areEqual( 'Barney', ( String ) argsCaptured[ 1 ], 'the second value is not as expected' );
        System.Assert.areEqual( 'Wilma', ( String ) argsCaptured[ 2 ], 'the third value is not as expected' );
        System.Assert.areEqual( 'Barney', ( String ) argsCaptured[ 3 ], 'the fourth value is not as expected' );
        System.Assert.areEqual( 'Barney', ( String ) argsCaptured[ 4 ], 'the fifth value is not as expected' );
        System.Assert.areEqual( 'Betty', ( String ) argsCaptured[ 5 ], 'the sixth value is not as expected' );
    }

    private class TestInnerClass{
        public Integer i;
        public String s;
    }
}
