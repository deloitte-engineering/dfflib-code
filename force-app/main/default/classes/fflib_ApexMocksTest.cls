/**
 * Copyright (c), FinancialForce.com, inc
 * Copyright (c), Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
@SuppressWarnings( 'PMD.ApexUnitTestClassShouldHaveAsserts' ) // to avoid warnings due to inner assert methods
@IsTest( isParallel = true )
private with sharing class fflib_ApexMocksTest{
    private static final fflib_ApexMocks MY_MOCKS = new fflib_ApexMocks();
    private static final fflib_MyList MY_MOCK_LIST = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
    private static fflib_InvocationOnMock actualInvocation = null;

    @IsTest
    private static void whenStubMultipleCallsWithMatchersShouldReturnExpectedValues(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // Set mocks
        mocks.startStubbing();
        mocks.when( mockList.get2( fflib_Match.anyInteger(), fflib_Match.anyString() ) ).thenReturn( 'any' );
        mocks.when( mockList.get2( fflib_Match.anyInteger(), fflib_Match.stringContains( 'Hello' ) ) ).thenReturn( 'hello' );
        mocks.stopStubbing();

        // When - perform test
        String actualValue = mockList.get2( 0, 'Hi hi Hello Hi hi' );

        // Then - validate
        System.Assert.areEqual( 'hello', actualValue );
    }

    @IsTest
    private static void whenVerifyMultipleCallsWithMatchersShouldReturnCorrectMethodCallCounts(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'bob' );
        mockList.add( 'fred' );

        // Then - validate
        ( ( fflib_MyList.IList ) mocks.verify( mockList, 2 ) ).add( fflib_Match.anyString() );
        ( ( fflib_MyList.IList ) mocks.verify( mockList ) ).add( 'fred' );
        ( ( fflib_MyList.IList ) mocks.verify( mockList ) ).add( fflib_Match.stringContains( 'fred' ) );
    }

    @IsTest
    private static void whenStubExceptionWithMatchersShouldThrowException(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // Set mocks
        mocks.startStubbing();
        ( ( fflib_MyList.IList ) mocks.doThrowWhen( new MyException( 'Matcher Exception' ), mockList ) )
            .add( fflib_Match.stringContains( 'Hello' ) );
        mocks.stopStubbing();

        // When - perform test
        mockList.add( 'Hi' );

        try{
            mockList.add( 'Hi Hello Hi' );
            System.Assert.fail( 'Expected MyException exception to be thrown. This assertion should never be triggered' );
        } catch( MyException e ){
            // Then - validate
            System.Assert.areEqual( 'Matcher Exception', e.getMessage() );
        }
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
        ( ( fflib_MyList.IList ) mocks.verify( mockList, 0 ) ).add(
            ( String ) fflib_Match.allOf( fflib_Match.eq( 'bob' ), fflib_Match.stringContains( 're' ) )
        );

        ( ( fflib_MyList.IList ) mocks.verify( mockList ) ).add(
            ( String ) fflib_Match.allOf( fflib_Match.eq( 'fred' ), fflib_Match.stringContains( 're' ) )
        );

        ( ( fflib_MyList.IList ) mocks.verify( mockList, 2 ) ).add(
            ( String ) fflib_Match.anyOf( fflib_Match.eq( 'bob' ), fflib_Match.eq( 'fred' ) )
        );

        ( ( fflib_MyList.IList ) mocks.verify( mockList, 1 ) ).add(
            ( String ) fflib_Match.anyOf( fflib_Match.eq( 'bob' ), fflib_Match.eq( 'jack' ) )
        );

        ( ( fflib_MyList.IList ) mocks.verify( mockList, 2 ) ).add(
            ( String ) fflib_Match.noneOf( fflib_Match.eq( 'jack' ), fflib_Match.eq( 'tim' ) )
        );

        ( ( fflib_MyList.IList ) mocks.verify( mockList, 2 ) ).add(
            ( String ) fflib_Match.noneOf(
                fflib_Match.anyOf( fflib_Match.eq( 'jack' ), fflib_Match.eq( 'jill' ) ),
                fflib_Match.allOf( fflib_Match.eq( 'tim' ), fflib_Match.stringContains( 'i' ) )
            )
        );

        ( ( fflib_MyList.IList ) mocks.verify( mockList, 2 ) ).add(
            ( String ) fflib_Match.isNot( fflib_Match.eq( 'jack' ) )
        );
    }

    @IsTest
    private static void whenStubCustomMatchersCanBeUsed(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // Set mocks
        mocks.startStubbing();
        mocks.when( mockList.get( ( Integer ) fflib_Match.matches( new isOdd() ) ) ).thenReturn( 'Odd' );
        mocks.when( mockList.get( ( Integer ) fflib_Match.matches( new isEven() ) ) ).thenReturn( 'Even' );
        mocks.stopStubbing();

        // When - perform test
        String s1 = mockList.get( 1 );
        String s2 = mockList.get( 2 );
        String s3 = mockList.get( 3 );
        String s4 = mockList.get( 4 );
        String s5 = mockList.get( 5 );

        // Then - validate
        System.Assert.areEqual( 'Odd', s1 );
        System.Assert.areEqual( 'Even', s2 );
        System.Assert.areEqual( 'Odd', s3 );
        System.Assert.areEqual( 'Even', s4 );
        System.Assert.areEqual( 'Odd', s5 );
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
        ( ( fflib_MyList.IList ) mocks.verify( mockList, 3 ) ).get( ( Integer ) fflib_Match.matches( new isOdd() ) );
        ( ( fflib_MyList.IList ) mocks.verify( mockList, 2 ) ).get( ( Integer ) fflib_Match.matches( new isEven() ) );
    }

    @IsTest
    private static void whenStubWithMatcherAndNonMatcherArgumentsShouldThrowException(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        String expectedError = 'The number of matchers defined (1) '
            + 'does not match the number expected (2).\n'
            + 'If you are using matchers all arguments must be passed in as matchers.\n'
            + 'For example myList.add(fflib_Match.anyInteger(), \'String\') should be defined as '
            + 'myList.add(fflib_Match.anyInteger(), fflib_Match.eq(\'String\')).';

        // Then - validate
        try{
            // Set mocks
            mocks.startStubbing();
            mocks.when( mockList.get2( fflib_Match.anyInteger(), 'String literal' ) ).thenReturn( 'fail' );
            System.Assert.fail( 'Expected fflib_ApexMocks.ApexMocksException exception to be thrown. This assertion should never be triggered' );
        } catch( fflib_ApexMocks.ApexMocksException e ){
            System.Assert.areEqual( expectedError, e.getMessage() );
        }
    }

    @IsTest
    private static void whenVerifyWithMatcherAndNonMatcherArgumentsShouldThrowException(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        String expectedError = 'The number of matchers defined (1) '
            + 'does not match the number expected (2).\n'
            + 'If you are using matchers all arguments must be passed in as matchers.\n'
            + 'For example myList.add(fflib_Match.anyInteger(), \'String\') should be defined as '
            + 'myList.add(fflib_Match.anyInteger(), fflib_Match.eq(\'String\')).';

        mockList.get2( 1, 'String literal' );

        // Then - validate
        try{
            ( ( fflib_MyList.IList ) mocks.verify( mockList ) ).get2( fflib_Match.anyInteger(), 'String literal' );
            System.Assert.fail( 'Expected fflib_ApexMocks.ApexMocksException exception to be thrown. This assertion should never be triggered' );
        } catch( fflib_ApexMocks.ApexMocksException e ){
            System.Assert.areEqual( expectedError, e.getMessage() );
        }
    }

    @IsTest
    private static void whenStubSameMethodWithMatchersAndNonMatchersShouldStubInOrder(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // Set mocks
        mocks.startStubbing();

        mocks.when( mockList.get2( 1, 'Non-matcher first' ) ).thenReturn( 'Bad' ); //Set the return value using the non-matcher arguments
        mocks.when( mockList.get2( fflib_Match.eqInteger( 1 ), fflib_Match.stringContains( 'Non-matcher first' ) ) )
            .thenReturn( 'Good' ); // Override the return value using matcher arguments

        mocks.when( mockList.get2( fflib_Match.eqInteger( 1 ), fflib_Match.stringContains( 'Matcher first' ) ) )
            .thenReturn( 'Bad' ); // Set the return value using the matcher arguments
        mocks.when( mockList.get2( 1, 'Matcher first' ) ).thenReturn( 'Good' ); //Override the return value using non-matcher arguments

        mocks.stopStubbing();

        // When, Then
        System.Assert.areEqual( 'Good', mockList.get2( 1, 'Non-matcher first' ) );
        System.Assert.areEqual( 'Good', mockList.get2( 1, 'Matcher first' ) );
    }

    @IsTest
    private static void whenStubExceptionSameMethodWithMatchersAndNonMatchersShouldStubInOrder(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // Set mocks
        mocks.startStubbing();

        ( ( fflib_MyList.IList ) mocks.doThrowWhen( new fflib_ApexMocks.ApexMocksException( 'Bad' ), mockList ) ).add( 'Non-matcher first' ); //Set the exception value using the non-matcher arguments
        ( ( fflib_MyList.IList ) mocks.doThrowWhen( new fflib_ApexMocks.ApexMocksException( 'Good' ), mockList ) ).add( fflib_Match.stringContains( 'Non-matcher first' ) ); //Override the exception value using matcher arguments

        ( ( fflib_MyList.IList ) mocks.doThrowWhen( new fflib_ApexMocks.ApexMocksException( 'Bad' ), mockList ) ).add( fflib_Match.stringContains( 'Matcher first' ) ); //Set the exception value using the matcher arguments
        ( ( fflib_MyList.IList ) mocks.doThrowWhen( new fflib_ApexMocks.ApexMocksException( 'Good' ), mockList ) ).add( 'Matcher first' ); //Override the exception value using non-matcher arguments

        mocks.stopStubbing();

        // When, Then
        try{
            mockList.add( 'Non-matcher first' );
            System.Assert.fail( 'Expected fflib_ApexMocks.ApexMocksException exception to be thrown. This assertion should never be triggered' );
        } catch( fflib_ApexMocks.ApexMocksException e ){
            System.Assert.areEqual( 'Good', e.getMessage() );
        }

        try{
            mockList.add( 'Matcher first' );
            System.Assert.fail( 'Expected fflib_ApexMocks.ApexMocksException exception to be thrown. This assertion should never be triggered' );
        } catch( fflib_ApexMocks.ApexMocksException e ){
            System.Assert.areEqual( 'Good', e.getMessage() );
        }
    }

    @IsTest
    private static void whenStubSingleCallWithSingleArgumentShouldReturnStubbedValue(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // Set mocks
        mocks.startStubbing();
        mocks.when( mockList.get( 0 ) ).thenReturn( 'bob' );
        mocks.stopStubbing();

        // When - perform test
        String actualValue = mockList.get( 0 );

        // Then - validate
        System.Assert.areEqual( 'bob', actualValue );
    }

    @IsTest
    private static void whenStubSingleCallWithNullReturnValueItShouldReturnNull(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // Set mocks
        mocks.startStubbing();
        mocks.when( mockList.get( 0 ) ).thenReturn( null );
        mocks.stopStubbing();

        // When - perform test
        String actualValue = mockList.get( 0 );

        // Then - validate
        System.Assert.isNull( actualValue );
    }

    @IsTest
    private static void whenStubMultipleCallsWithSingleArgumentShouldReturnStubbedValues(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // Set mocks
        mocks.startStubbing();
        mocks.when( mockList.get( 0 ) ).thenReturn( 'bob' );
        mocks.when( mockList.get( 1 ) ).thenReturn( 'fred' );
        mocks.stopStubbing();

        // When - perform test
        String actualValueArg0 = mockList.get( 0 );
        String actualValueArg1 = mockList.get( 1 );
        String actualValueArg2 = mockList.get( 2 );

        // Then - validate
        System.Assert.areEqual( 'bob', actualValueArg0 );
        System.Assert.areEqual( 'fred', actualValueArg1 );
        System.Assert.isNull( actualValueArg2 );
    }

    @IsTest
    private static void whenStubSameCallWithDifferentArgumentValueShouldReturnLastStubbedValue(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // Set mocks
        mocks.startStubbing();
        mocks.when( mockList.get( 0 ) ).thenReturn( 'bob1' );
        mocks.when( mockList.get( 0 ) ).thenReturn( 'bob2' );
        mocks.stopStubbing();

        // When - perform test
        String actualValue = mockList.get( 0 );

        // Then - validate
        System.Assert.areEqual( 'bob2', actualValue );
    }

    @IsTest
    private static void whenStubCallWithNoArgumentsShouldReturnStubbedValue(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // Set mocks
        mocks.startStubbing();
        mocks.when( mockList.isEmpty() ).thenReturn( false );
        mocks.stopStubbing();

        // When - perform test
        Boolean actualValue = mockList.isEmpty();

        // Then - validate
        System.Assert.isFalse( actualValue );
    }

    @IsTest
    private static void verifySingleMethodCallWithNoArguments(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.isEmpty();

        // Then - validate
        ( ( fflib_MyList.IList ) mocks.verify( mockList ) ).isEmpty();
    }

    @IsTest
    private static void verifySingleMethodCallWithSingleArgument(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'bob' );

        // Then - validate
        ( ( fflib_MyList.IList ) mocks.verify( mockList ) ).add( 'bob' );
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
        ( ( fflib_MyList.IList ) mocks.verify( mockList, 2 ) ).add( 'bob' );
    }

    @IsTest
    private static void verifyMultipleMethodCallsWithDifferentSingleArgument(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'bob' );
        mockList.add( 'fred' );

        // Then - validate
        ( ( fflib_MyList.IList ) mocks.verify( mockList ) ).add( 'bob' );
        ( ( fflib_MyList.IList ) mocks.verify( mockList ) ).add( 'fred' );
    }

    @IsTest
    private static void verifyMethodCallsWithSameNameButDifferentArgumentTypes(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'bob' );
        mockList.add( new List<String>{ 'bob' } );
        mockList.add( ( String ) null );
        mockList.add( ( String[] ) null );

        // Then - validate
        ( ( fflib_MyList.IList ) mocks.verify( mockList ) ).add( 'bob' );
        ( ( fflib_MyList.IList ) mocks.verify( mockList ) ).add( new List<String>{ 'bob' } );
        ( ( fflib_MyList.IList ) mocks.verify( mockList ) ).add( ( String ) null );
        ( ( fflib_MyList.IList ) mocks.verify( mockList ) ).add( ( String[] ) null );
    }

    @IsTest
    private static void verifyMethodNotCalled(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.get( 0 );

        // Then - validate
        ( ( fflib_MyList.IList ) mocks.verify( mockList, fflib_ApexMocks.NEVER ) ).add( 'bob' );
        ( ( fflib_MyList.IList ) mocks.verify( mockList ) ).get( 0 );
    }

    @IsTest
    private static void stubAndVerifyMethodCallsWithNoArguments(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // Set mocks
        mocks.startStubbing();
        mocks.when( mockList.isEmpty() ).thenReturn( false );
        mocks.stopStubbing();

        mockList.clear();

        // When - perform test
        Boolean actualValue = mockList.isEmpty();

        // Then - validate
        System.Assert.isFalse( actualValue );
        ( ( fflib_MyList.IList ) mocks.verify( mockList ) ).clear();
    }

    @IsTest
    private static void setOrderedVerifier_shouldSetOrderVerifierCorrectly(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList firstMock = ( fflib_MyList ) mocks.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( mocks, new List<Object>{ firstMock } );

        // When - perform test
        mocks.setOrderedVerifier( inOrder1 );

        firstMock.add( '1-1' );
        firstMock.add( '1-2' );
        firstMock.add( '1-2' );
        firstMock.add( '1-2' );
        firstMock.add( '1-3' );
        firstMock.add( '1-4' );

        // Then - validate
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, mocks.calls( 2 ) ) ).add( '1-2' );
    }

    @IsTest
    private static void between_shouldSetExpectedRangeCorrectly(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();

        // Given - create data
        Integer atLeastTimes = 1;
        Integer atMostTimes = 4;

        // When - perform test
        fflib_VerificationMode verificationMode = mocks.between( atLeastTimes, atMostTimes );

        // Then - validate
        System.Assert.areEqual( fflib_VerificationMode.modeName.BETWEEN, verificationMode.method );
        System.Assert.areEqual( atLeastTimes, verificationMode.verifyMin );
        System.Assert.areEqual( atMostTimes, verificationMode.verifyMax );
    }

    @IsTest
    private static void atLeastOnce_shouldSetMinimumCorrectly(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();

        // When - perform test
        fflib_VerificationMode verificationMode = mocks.atLeastOnce();

        // Then - validate
        System.Assert.areEqual( fflib_VerificationMode.modeName.ATLEASTONCE, verificationMode.method );
        System.Assert.areEqual( 1, verificationMode.verifyMin );
    }

    @IsTest
    private static void atMost_shouldSetMaximumCorrectly(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();

        // Given - create data
        Integer atMostTimes = 4;

        // When - perform test
        fflib_VerificationMode verificationMode = mocks.atMost( atMostTimes );

        // Then - validate
        System.Assert.areEqual( fflib_VerificationMode.modeName.ATMOST, verificationMode.method );
        System.Assert.areEqual( atMostTimes, verificationMode.verifyMax );
    }

    @IsTest
    private static void atLeast_shouldSetMinimumCorrectly(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();

        // Given - create data
        Integer atLeastTimes = 1;

        // When - perform test
        fflib_VerificationMode verificationMode = mocks.atLeast( atLeastTimes );

        // Then - validate
        System.Assert.areEqual( fflib_VerificationMode.modeName.ATLEAST, verificationMode.method );
        System.Assert.areEqual( atLeastTimes, verificationMode.verifyMin );
    }

    @IsTest
    private static void description_shouldSetCustomAssertMessageCorrectly(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();

        // Given - create data
        String customAssertMessage = 'A random description message.';

        // When - perform test
        fflib_VerificationMode verificationMode = mocks.description( customAssertMessage );

        // Then - validate
        System.Assert.areEqual( 1, verificationMode.verifyMin );
        System.Assert.areEqual( customAssertMessage, verificationMode.customAssertMessage );
    }

    @IsTest
    private static void doAnswer_shouldSetMockAnswerCorrectly(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ApexMocksTest.BasicAnswer basicAnswer = new fflib_ApexMocksTest.BasicAnswer();
        fflib_MyList.IList mockList = new fflib_Mocks.Mockfflib_MyList( mocks );

        // When - perform test
        mocks.startStubbing();
        mocks.doAnswer( basicAnswer, mockList );
        // This call will trigger the mockNonVoidMethod() to check for the answer set in the mock instance, thus verifying the correctness of the test.
        mockList.isEmpty();
        mocks.stopStubbing();
    }

    @IsTest
    private static void whenStubExceptionTheExceptionShouldBeThrown(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // Set mocks
        mocks.startStubbing();
        mocks.when( mockList.get( 0 ) ).thenThrow( new MyException( 'Stubbed exception.' ) );
        mocks.stopStubbing();

        // When - perform test
        try{
            mockList.get( 0 );
            System.Assert.fail( 'Expected Stubbed Exception (MyException) to be thrown. This assertion should never be triggered' );
        } catch( Exception e ){
            // Then - validate
            System.Assert.areEqual( 'fflib_ApexMocksTest.MyException', e.getTypeName() );
            System.Assert.areEqual( 'Stubbed exception.', e.getMessage() );
        }
    }

    @IsTest
    private static void whenStubVoidMethodWithExceptionThenExceptionShouldBeThrown(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // Set mocks
        mocks.startStubbing();
        ( ( fflib_MyList.IList ) mocks.doThrowWhen( new MyException( 'Stubbed exception.' ), mockList ) ).clear();
        mocks.stopStubbing();

        // When - perform test
        try{
            mockList.clear();
            System.Assert.fail( 'Expected Stubbed Exception (MyException) to be thrown. This assertion should never be triggered' );
        } catch( Exception e ){
            // Then - validate
            System.Assert.areEqual( 'fflib_ApexMocksTest.MyException', e.getTypeName() );
            System.Assert.areEqual( 'Stubbed exception.', e.getMessage() );
        }
    }

    @IsTest
    private static void whenStubMultipleVoidMethodsWithExceptionsThenExceptionsShouldBeThrown(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // Set mocks
        mocks.startStubbing();
        ( ( fflib_MyList.IList ) mocks.doThrowWhen( new MyException( 'clear stubbed exception.' ), mockList ) ).clear();
        ( ( fflib_MyList.IList ) mocks.doThrowWhen( new MyException( 'add stubbed exception.' ), mockList ) ).add( 'bob' );
        mocks.stopStubbing();

        // When - perform test
        try{
            mockList.clear();
            System.Assert.fail( 'Expected Stubbed Exception (MyException) to be thrown. This assertion should never be triggered' );
        } catch( Exception e ){
            // Then - validate
            System.Assert.areEqual( 'fflib_ApexMocksTest.MyException', e.getTypeName() );
            System.Assert.areEqual( 'clear stubbed exception.', e.getMessage() );
        }

        // When - perform test
        try{
            mockList.add( 'bob' );
            System.Assert.fail( 'Expected Stubbed Exception (MyException) to be thrown. This assertion should never be triggered' );
        } catch( Exception e ){
            // Then - validate
            System.Assert.areEqual( 'fflib_ApexMocksTest.MyException', e.getTypeName() );
            System.Assert.areEqual( 'add stubbed exception.', e.getMessage() );
        }
    }

    @IsTest
    private static void whenStubVoidMethodWithExceptionAndCallMethodTwiceThenExceptionShouldBeThrownTwice(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // Set mocks
        mocks.startStubbing();
        ( ( fflib_MyList.IList ) mocks.doThrowWhen( new MyException( 'clear stubbed exception.' ), mockList ) ).clear();
        mocks.stopStubbing();

        // When - perform test
        try{
            mockList.clear();
            System.Assert.fail( 'Expected Stubbed Exception (MyException) to be thrown. This assertion should never be triggered' );
        } catch( Exception e ){
            // Then - validate
            System.Assert.areEqual( 'fflib_ApexMocksTest.MyException', e.getTypeName() );
            System.Assert.areEqual( 'clear stubbed exception.', e.getMessage() );
        }

        // When - perform test
        try{
            mockList.clear();
            System.Assert.fail( 'Expected Stubbed Exception (MyException) to be thrown. This assertion should never be triggered' );
        } catch( Exception e ){
            // Then - validate
            System.Assert.areEqual( 'fflib_ApexMocksTest.MyException', e.getTypeName() );
            System.Assert.areEqual( 'clear stubbed exception.', e.getMessage() );
        }
    }

    @IsTest
    private static void verifyMethodCallWhenNoCallsBeenMadeForType(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // Then - validate
        ( ( fflib_MyList.IList ) mocks.verify( mockList, fflib_ApexMocks.NEVER ) ).add( 'bob' );
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
        ( ( fflib_MyList.IList ) mocks.verify( mockList, fflib_ApexMocks.NEVER ) ).set( 0, 'fred' );
    }

    @IsTest
    private static void whenStubMultipleCallsWithMultipleArgumentShouldReturnStubbedValues(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // Set mocks
        mocks.startStubbing();
        mocks.when( mockList.get2( 0, 'zero' ) ).thenReturn( 'bob' );
        mocks.when( mockList.get2( 1, 'one' ) ).thenReturn( 'fred' );
        mocks.when( mockList.get2( 0, 'two' ) ).thenReturn( 'bob' );
        mocks.when( mockList.get2( 1, 'three' ) ).thenReturn( 'bub' );
        mocks.stopStubbing();

        // When - perform test
        String actualValueArg0 = mockList.get2( 0, 'zero' );
        String actualValueArg1 = mockList.get2( 1, 'one' );
        String actualValueArg2 = mockList.get2( 0, 'two' );
        String actualValueArg3 = mockList.get2( 1, 'three' );
        String actualValueArg4 = mockList.get2( 0, 'three' );

        // Then - validate
        System.Assert.areEqual( 'bob', actualValueArg0 );
        System.Assert.areEqual( 'fred', actualValueArg1 );
        System.Assert.areEqual( 'bob', actualValueArg2 );
        System.Assert.areEqual( 'bub', actualValueArg3 );
        System.Assert.isNull( actualValueArg4 );
    }

    @IsTest
    private static void whenStubNullConcreteArgValueCorrectValueIsReturned(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        String expected = 'hello';

        // Set mocks
        mocks.startStubbing();
        mocks.when( mockList.get( null ) ).thenReturn( expected );
        mocks.stopStubbing();

        // When - perform test
        String actual = mockList.get( null );

        // Then - validate
        System.Assert.areEqual( expected, actual );
    }

    @IsTest
    private static void whenSetDoThrowWhenExceptionsValuesAreSet(){
        //Given
        MyException e = new MyException( 'Test' );
        fflib_ApexMocks mocks = new fflib_ApexMocks();

        List<Exception> expsList = new List<Exception>{ e };

        //When
        mocks.DoThrowWhenExceptions = expsList;

        // Then - validate
        System.Assert.areEqual( expsList, mocks.DoThrowWhenExceptions );
    }

    @IsTest
    private static void whenVerifyMethodNeverCalledMatchersAreReset(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList mockList = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // When - perform test
        mockList.add( 'bob' );

        // Then - validate
        ( ( fflib_MyList.IList ) mocks.verify( mockList, fflib_ApexMocks.NEVER ) ).get( fflib_Match.anyInteger() );
        ( ( fflib_MyList.IList ) mocks.verify( mockList ) ).add( fflib_Match.anyString() );
    }

    @IsTest
    private static void whenMockIsGeneratedCanVerify(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList.IList mockList = new fflib_Mocks.Mockfflib_MyList( mocks );

        // When - perform test
        mockList.add( 'bob' );

        // Then - validate
        ( ( fflib_MyList.IList ) mocks.verify( mockList, fflib_ApexMocks.NEVER ) ).get( fflib_Match.anyInteger() );
        ( ( fflib_MyList.IList ) mocks.verify( mockList ) ).add( 'bob' );
    }

    @IsTest
    private static void whenMockIsGeneratedCanStubVerify(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList.IList mockList = new fflib_Mocks.Mockfflib_MyList( mocks );

        // Set mocks
        mocks.startStubbing();
        mocks.when( mockList.get( 1 ) ).thenReturn( 'One' );
        mocks.when( mockList.get( fflib_Match.integerMoreThan( 2 ) ) ).thenReturn( '>Two' );
        mocks.stopStubbing();

        // Then - validate
        System.Assert.isNull( mockList.get( 0 ) );
        System.Assert.areEqual( 'One', mockList.get( 1 ) );
        System.Assert.isNull( mockList.get( 2 ) );
        System.Assert.areEqual( '>Two', mockList.get( 3 ) );
    }

    @IsTest
    private static void thatMultipleInstancesCanBeMockedIndependently(){
        fflib_ApexMocksConfig.HasIndependentMocks = true;

        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList first = ( fflib_MyList ) mocks.mock( fflib_MyList.class );
        fflib_MyList second = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // Set mocks
        mocks.startStubbing();
        mocks.when( first.get( 0 ) ).thenReturn( 'First' );
        mocks.when( second.get( 0 ) ).thenReturn( 'Second' );
        mocks.stopStubbing();

        // When - perform test
        String actual = first.get( 0 );

        // Then - validate
        System.Assert.areEqual( 'First', actual, 'Should have returned stubbed value' );
        ( ( fflib_MyList ) mocks.verify( first ) ).get( 0 );
        ( ( fflib_MyList ) mocks.verify( second, mocks.never() ) ).get( 0 );
    }

    @IsTest
    private static void thatMultipleInstancesCanBeMockedDependently(){
        fflib_ApexMocksConfig.HasIndependentMocks = false;

        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_MyList first = ( fflib_MyList ) mocks.mock( fflib_MyList.class );
        fflib_MyList second = ( fflib_MyList ) mocks.mock( fflib_MyList.class );

        // Set mocks
        mocks.startStubbing();
        mocks.when( first.get( 0 ) ).thenReturn( 'First' );
        mocks.when( second.get( 0 ) ).thenReturn( 'Second' );
        mocks.stopStubbing();

        // When - perform test
        String actual = first.get( 0 );

        // Then - validate
        System.Assert.areEqual( 'Second', actual, 'Should have returned stubbed value' );
        ( ( fflib_MyList ) mocks.verify( first ) ).get( 0 );
        ( ( fflib_MyList ) mocks.verify( second ) ).get( 0 );
    }

    private static void thatStubbingCanBeChainedFirstExceptionThenValue(){
        // Set mocks
        MY_MOCKS.startStubbing();
        MY_MOCKS.when( MY_MOCK_LIST.get( 1 ) ).thenThrow( new MyException( 'Stubbed exception.' ) ).thenReturn( 'One' );
        MY_MOCKS.stopStubbing();

        // Then - validate
        assertExceptionMessage( 'Stubbed exception.' );
        assertReturnedValue( 'One' );
    }

    @IsTest
    private static void thatStubbingCanBeChainedFirstValueThenException(){
        // Set mocks
        MY_MOCKS.startStubbing();
        MY_MOCKS.when( MY_MOCK_LIST.get( 1 ) ).thenReturn( 'One' ).thenThrow( new MyException( 'Stubbed exception.' ) );
        MY_MOCKS.stopStubbing();

        // Then - validate
        assertReturnedValue( 'One' );
        assertExceptionMessage( 'Stubbed exception.' );
    }

    @IsTest
    private static void thatStubbingMultipleMethodsCanBeChainedFirstExceptionThenValue(){
        // Set mocks
        MY_MOCKS.startStubbing();
        MY_MOCKS.when( MY_MOCK_LIST.get( 1 ) ).thenThrow( new MyException( 'Stubbed exception.' ) ).thenReturn( 'One' );
        MY_MOCKS.when( MY_MOCK_LIST.get2( 2, 'Hello.' ) ).thenThrow( new MyException( 'Stubbed exception2.' ) ).thenReturn( 'One2' );
        MY_MOCKS.stopStubbing();

        // Then - validate
        assertExceptionMessage( 'Stubbed exception.' );
        assertReturnedValue( 'One' );
        assertExceptionMessageForGet2( 'Stubbed exception2.' );
        assertReturnedValueForGet2( 'One2' );
    }

    @IsTest
    private static void thatStubbingMultipleMethodsCanBeChainedFirstValueThenException(){
        // Set mocks
        MY_MOCKS.startStubbing();
        MY_MOCKS.when( MY_MOCK_LIST.get( 1 ) ).thenReturn( 'One' ).thenThrow( new MyException( 'Stubbed exception.' ) );
        MY_MOCKS.when( MY_MOCK_LIST.get2( 2, 'Hello.' ) ).thenReturn( 'One2' ).thenThrow( new MyException( 'Stubbed exception2.' ) );
        MY_MOCKS.stopStubbing();

        // Then - validate
        assertReturnedValue( 'One' );
        assertExceptionMessage( 'Stubbed exception.' );
        assertReturnedValueForGet2( 'One2' );
        assertExceptionMessageForGet2( 'Stubbed exception2.' );
    }

    @IsTest
    private static void thatStubbingReturnsDifferentValuesForDifferentCalls(){
        // Set mocks
        MY_MOCKS.startStubbing();
        MY_MOCKS.when( MY_MOCK_LIST.get( 1 ) ).thenReturnMulti( new List<String>{ 'One', 'Two', 'Three' } );
        MY_MOCKS.stopStubbing();

        // Then - validate
        assertReturnedValue( 'One' );
        assertReturnedValue( 'Two' );
        assertReturnedValue( 'Three' );
    }

    @IsTest
    private static void thatStubbingReturnsDifferentValuesForDifferentCallsAndRepeatLastValuesForFurtherCalls(){
        // Set mocks
        MY_MOCKS.startStubbing();
        MY_MOCKS.when( MY_MOCK_LIST.get( 1 ) ).thenReturnMulti( new List<String>{ 'One', 'Two', 'Three' } );
        MY_MOCKS.stopStubbing();

        // Then - validate
        assertReturnedValue( 'One' );
        assertReturnedValue( 'Two' );
        assertReturnedValue( 'Three' );

        assertReturnedValue( 'Three' );
        assertReturnedValue( 'Three' );
    }

    @IsTest
    private static void thatStubbingThrowsDifferentExceptionsForDifferentCalls(){
        // Create mocks
        MyException first = new MyException( 'first.' );
        MyException second = new MyException( 'second.' );
        MyException third = new MyException( 'third.' );

        // Set mocks
        MY_MOCKS.startStubbing();
        MY_MOCKS.when( MY_MOCK_LIST.get( 1 ) ).thenThrowMulti( new List<Exception>{ first, second, third } );
        MY_MOCKS.stopStubbing();

        // Then - validate
        assertExceptionMessage( 'first.' );
        assertExceptionMessage( 'second.' );
        assertExceptionMessage( 'third.' );
    }

    @IsTest
    private static void thatStubbingThrowsDifferentExceptionsForDifferentCallsAndRepeatLastExceptionForFurtherCalls(){
        // Create mocks
        MyException first = new MyException( 'first.' );
        MyException second = new MyException( 'second.' );
        MyException third = new MyException( 'third.' );

        // Set mocks
        MY_MOCKS.startStubbing();
        MY_MOCKS.when( MY_MOCK_LIST.get( 1 ) ).thenThrowMulti( new List<Exception>{ first, second, third } );
        MY_MOCKS.stopStubbing();

        // Then - validate
        assertExceptionMessage( 'first.' );
        assertExceptionMessage( 'second.' );
        assertExceptionMessage( 'third.' );

        assertExceptionMessage( 'third.' );
        assertExceptionMessage( 'third.' );
    }

    @IsTest
    private static void thatStubbingThrowsAndReturnsDifferentExceptionsAndValuesForDifferentCalls(){
        // Create mocks
        MyException first = new MyException( 'first.' );
        MyException second = new MyException( 'second.' );
        MyException third = new MyException( 'third.' );

        // Set mocks
        MY_MOCKS.startStubbing();
        MY_MOCKS.when( MY_MOCK_LIST.get( 1 ) ).
            thenThrowMulti( new List<Exception>{ first, second, third } ).
            thenReturnMulti( new List<String>{ 'One', 'Two', 'Three' } );
        MY_MOCKS.stopStubbing();

        // Then - validate
        assertExceptionMessage( 'first.' );
        assertExceptionMessage( 'second.' );
        assertExceptionMessage( 'third.' );

        assertReturnedValue( 'One' );
        assertReturnedValue( 'Two' );
        assertReturnedValue( 'Three' );

        assertReturnedValue( 'Three' );
        assertReturnedValue( 'Three' );
    }

    @IsTest
    private static void thatStubbingReturnsAndThrowsDifferentValuesAndExceptionsForDifferentCalls(){
        // Create mocks
        MyException first = new MyException( 'first.' );
        MyException second = new MyException( 'second.' );
        MyException third = new MyException( 'third.' );

        // Set mocks
        MY_MOCKS.startStubbing();
        MY_MOCKS.when( MY_MOCK_LIST.get( 1 ) ).
            thenReturnMulti( new List<String>{ 'One', 'Two', 'Three' } ).
            thenThrowMulti( new List<Exception>{ first, second, third } );
        MY_MOCKS.stopStubbing();

        // Then - validate
        assertReturnedValue( 'One' );
        assertReturnedValue( 'Two' );
        assertReturnedValue( 'Three' );

        assertExceptionMessage( 'first.' );
        assertExceptionMessage( 'second.' );
        assertExceptionMessage( 'third.' );

        assertExceptionMessage( 'third.' );
        assertExceptionMessage( 'third.' );
    }

    @IsTest
    private static void thatStubbingMultipleTimesOverridePreviousThenReturnWithSingleValue(){
        // Set mocks
        MY_MOCKS.startStubbing();
        MY_MOCKS.when( MY_MOCK_LIST.get( 1 ) ).thenReturn( 'One' );
        MY_MOCKS.when( MY_MOCK_LIST.get( 1 ) ).thenReturn( 'Two' );
        MY_MOCKS.stopStubbing();

        // Then - validate
        assertReturnedValue( 'Two' );
        assertReturnedValue( 'Two' );
    }

    @IsTest
    private static void thatStubbingMultipleTimesOverridePreviousThenReturnMultiWithSingleValue(){
        // Create mocks
        // When - perform test
        MY_MOCKS.startStubbing();
        MY_MOCKS.when( MY_MOCK_LIST.get( 1 ) ).thenReturnMulti( new List<String>{ 'One', 'Two', 'Three' } );
        MY_MOCKS.when( MY_MOCK_LIST.get( 1 ) ).thenReturn( 'Two' );
        MY_MOCKS.stopStubbing();

        // Then - validate
        assertReturnedValue( 'Two' );
        assertReturnedValue( 'Two' );
    }

    @IsTest
    private static void thatStubbingMultipleTimesOverridePreviousThenReturnMultiWithMultiValue(){
        // Set mocks
        MY_MOCKS.startStubbing();
        MY_MOCKS.when( MY_MOCK_LIST.get( 1 ) ).thenReturnMulti( new List<String>{ 'One', 'Two', 'Three' } );
        MY_MOCKS.when( MY_MOCK_LIST.get( 1 ) ).thenReturnMulti( new List<String>{ 'Four', 'Five', 'Six' } );
        MY_MOCKS.stopStubbing();

        // Then - validate
        assertReturnedValue( 'Four' );
        assertReturnedValue( 'Five' );
        assertReturnedValue( 'Six' );

        assertReturnedValue( 'Six' );
        assertReturnedValue( 'Six' );
    }

    @IsTest
    private static void thatStubbingMultipleTimesOverridePreviousThenReturnWithMultiValues(){
        // Set mocks
        MY_MOCKS.startStubbing();
        MY_MOCKS.when( MY_MOCK_LIST.get( 1 ) ).thenReturn( 'Two' );
        MY_MOCKS.when( MY_MOCK_LIST.get( 1 ) ).thenReturnMulti( new List<String>{ 'One', 'Two', 'Three' } );
        MY_MOCKS.stopStubbing();

        // Then - validate
        assertReturnedValue( 'One' );
        assertReturnedValue( 'Two' );
        assertReturnedValue( 'Three' );

        assertReturnedValue( 'Three' );
        assertReturnedValue( 'Three' );
    }

    @IsTest
    private static void thatStubbingMultipleTimesOverridePreviousThenReturnMultiWithSingleException(){
        // Create mocks
        MyException first = new MyException( 'first.' );

        // Set mocks
        MY_MOCKS.startStubbing();
        MY_MOCKS.when( MY_MOCK_LIST.get( 1 ) ).thenReturnMulti( new List<String>{ 'One', 'Two', 'Three' } );
        MY_MOCKS.when( MY_MOCK_LIST.get( 1 ) ).thenThrow( first );
        MY_MOCKS.stopStubbing();

        // Then - validate
        assertExceptionMessage( 'first.' );
        assertExceptionMessage( 'first.' );
    }

    @IsTest
    private static void thatStubbingMultipleTimesOverridePreviousThenReturnMultiWithMultiExceptions(){
        // Create mocks
        MyException first = new MyException( 'first.' );
        MyException second = new MyException( 'second.' );
        MyException third = new MyException( 'third.' );

        // Set mocks
        MY_MOCKS.startStubbing();
        MY_MOCKS.when( MY_MOCK_LIST.get( 1 ) ).thenReturnMulti( new List<String>{ 'One', 'Two', 'Three' } );
        MY_MOCKS.when( MY_MOCK_LIST.get( 1 ) ).thenThrowMulti( new List<Exception>{ first, second, third } );
        MY_MOCKS.stopStubbing();

        // Then - validate
        assertExceptionMessage( 'first.' );
        assertExceptionMessage( 'second.' );
        assertExceptionMessage( 'third.' );

        assertExceptionMessage( 'third.' );
        assertExceptionMessage( 'third.' );
    }

    @IsTest
    private static void thatStubbingMultipleTimesOverridePreviousThenReturnWithMultiExceptions(){
        // Create mocks
        MyException first = new MyException( 'first.' );
        MyException second = new MyException( 'second.' );
        MyException third = new MyException( 'third.' );

        // Set mocks
        MY_MOCKS.startStubbing();
        MY_MOCKS.when( MY_MOCK_LIST.get( 1 ) ).thenReturn( 'Two' );
        MY_MOCKS.when( MY_MOCK_LIST.get( 1 ) ).thenThrowMulti( new List<Exception>{ first, second, third } );
        MY_MOCKS.stopStubbing();

        // Then - validate
        assertExceptionMessage( 'first.' );
        assertExceptionMessage( 'second.' );
        assertExceptionMessage( 'third.' );

        assertExceptionMessage( 'third.' );
        assertExceptionMessage( 'third.' );
    }

    @IsTest
    private static void thatStubbingMultipleTimesOverridePreviousThenReturnWithSingleException(){
        // Create mocks
        MyException first = new MyException( 'first.' );

        // Set mocks
        MY_MOCKS.startStubbing();
        MY_MOCKS.when( MY_MOCK_LIST.get( 1 ) ).thenReturn( 'Two' );
        MY_MOCKS.when( MY_MOCK_LIST.get( 1 ) ).thenThrow( first );
        MY_MOCKS.stopStubbing();

        // Then - validate
        assertExceptionMessage( 'first.' );
        assertExceptionMessage( 'first.' );
    }

    @IsTest
    private static void thatStubbingMultipleTimesOverridePreviousThenThrowWithSingleValue(){
        // Create mocks
        MyException first = new MyException( 'first.' );

        // Set mocks
        MY_MOCKS.startStubbing();
        MY_MOCKS.when( MY_MOCK_LIST.get( 1 ) ).thenThrow( first );
        MY_MOCKS.when( MY_MOCK_LIST.get( 1 ) ).thenReturn( 'Two' );
        MY_MOCKS.stopStubbing();

        // Then - validate
        assertReturnedValue( 'Two' );
        assertReturnedValue( 'Two' );
    }

    @IsTest
    private static void thatStubbingMultipleTimesOverridePreviousThenThrowMultiWithSingleValue(){
        // Create mocks
        MyException first = new MyException( 'first.' );
        MyException second = new MyException( 'second.' );
        MyException third = new MyException( 'third.' );

        // Set mocks
        MY_MOCKS.startStubbing();
        MY_MOCKS.when( MY_MOCK_LIST.get( 1 ) ).thenThrowMulti( new List<Exception>{ first, second, third } );
        MY_MOCKS.when( MY_MOCK_LIST.get( 1 ) ).thenReturn( 'Two' );
        MY_MOCKS.stopStubbing();

        // Then - validate
        assertReturnedValue( 'Two' );
        assertReturnedValue( 'Two' );
    }

    @IsTest
    private static void thatStubbingMultipleTimesOverridePreviousThenThrowMultiWithMultiValue(){
        // Create mocks
        MyException first = new MyException( 'first.' );
        MyException second = new MyException( 'second.' );
        MyException third = new MyException( 'third.' );

        // Set mocks
        MY_MOCKS.startStubbing();
        MY_MOCKS.when( MY_MOCK_LIST.get( 1 ) ).thenThrowMulti( new List<Exception>{ first, second, third } );
        MY_MOCKS.when( MY_MOCK_LIST.get( 1 ) ).thenReturnMulti( new List<String>{ 'Four', 'Five', 'Six' } );
        MY_MOCKS.stopStubbing();

        // Then - validate
        assertReturnedValue( 'Four' );
        assertReturnedValue( 'Five' );
        assertReturnedValue( 'Six' );

        assertReturnedValue( 'Six' );
        assertReturnedValue( 'Six' );
    }

    @IsTest
    private static void thatStubbingMultipleTimesOverridePreviousThenThrowWithMultiValues(){
        // Create mocks
        MyException first = new MyException( 'first.' );

        // Set mocks
        MY_MOCKS.startStubbing();
        MY_MOCKS.when( MY_MOCK_LIST.get( 1 ) ).thenThrow( first );
        MY_MOCKS.when( MY_MOCK_LIST.get( 1 ) ).thenReturnMulti( new List<String>{ 'One', 'Two', 'Three' } );
        MY_MOCKS.stopStubbing();

        // Then - validate
        assertReturnedValue( 'One' );
        assertReturnedValue( 'Two' );
        assertReturnedValue( 'Three' );

        assertReturnedValue( 'Three' );
        assertReturnedValue( 'Three' );
    }

    @IsTest
    private static void thatStubbingMultipleTimesOverridePreviousThenThrowMultiWithSingleException(){
        // Create mocks
        MyException first = new MyException( 'first.' );
        MyException second = new MyException( 'second.' );
        MyException third = new MyException( 'third.' );
        MyException fourth = new MyException( 'fourth.' );

        // Set mocks
        MY_MOCKS.startStubbing();
        MY_MOCKS.when( MY_MOCK_LIST.get( 1 ) ).thenThrowMulti( new List<Exception>{ first, second, third } );
        MY_MOCKS.when( MY_MOCK_LIST.get( 1 ) ).thenThrow( fourth );
        MY_MOCKS.stopStubbing();

        // Then - validate
        assertExceptionMessage( 'fourth.' );
        assertExceptionMessage( 'fourth.' );
    }

    @IsTest
    private static void thatStubbingMultipleTimesOverridePreviousThenThrowMultiWithMultiExceptions(){
        // Create mocks
        MyException first = new MyException( 'first.' );
        MyException second = new MyException( 'second.' );
        MyException third = new MyException( 'third.' );

        MyException fourth = new MyException( 'fourth.' );
        MyException fifth = new MyException( 'fifth.' );
        MyException sixth = new MyException( 'sixth.' );

        // Set mocks
        MY_MOCKS.startStubbing();
        MY_MOCKS.when( MY_MOCK_LIST.get( 1 ) ).thenThrowMulti( new List<Exception>{ first, second, third } );
        MY_MOCKS.when( MY_MOCK_LIST.get( 1 ) ).thenThrowMulti( new List<Exception>{ fourth, fifth, sixth } );
        MY_MOCKS.stopStubbing();

        // Then - validate
        assertExceptionMessage( 'fourth.' );
        assertExceptionMessage( 'fifth.' );
        assertExceptionMessage( 'sixth.' );

        assertExceptionMessage( 'sixth.' );
        assertExceptionMessage( 'sixth.' );
    }

    @IsTest
    private static void thatStubbingMultipleTimesOverridePreviousThenThrowWithMultiExceptions(){
        // Create mocks
        MyException beforeFirst = new MyException( 'before first.' );

        MyException first = new MyException( 'first.' );
        MyException second = new MyException( 'second.' );
        MyException third = new MyException( 'third.' );

        // Set mocks
        MY_MOCKS.startStubbing();
        MY_MOCKS.when( MY_MOCK_LIST.get( 1 ) ).thenThrow( beforeFirst );
        MY_MOCKS.when( MY_MOCK_LIST.get( 1 ) ).thenThrowMulti( new List<Exception>{ first, second, third } );
        MY_MOCKS.stopStubbing();

        // Then - validate
        assertExceptionMessage( 'first.' );
        assertExceptionMessage( 'second.' );
        assertExceptionMessage( 'third.' );

        assertExceptionMessage( 'third.' );
        assertExceptionMessage( 'third.' );
    }

    @IsTest
    private static void thatStubbingMultipleTimesOverridePreviousThenThrowWithSingleException(){
        // Create mocks
        MyException beforeFirst = new MyException( 'before first.' );
        MyException first = new MyException( 'first.' );

        // Set mocks
        MY_MOCKS.startStubbing();
        MY_MOCKS.when( MY_MOCK_LIST.get( 1 ) ).thenThrow( beforeFirst );
        MY_MOCKS.when( MY_MOCK_LIST.get( 1 ) ).thenThrow( first );
        MY_MOCKS.stopStubbing();

        // Then - validate
        assertExceptionMessage( 'first.' );
        assertExceptionMessage( 'first.' );
    }

    @IsTest
    private static void thatVoidMethodThrowsMultipleExceptions(){
        // Create mocks
        MyException beforeFirst = new MyException( 'before first.' );

        MyException first = new MyException( 'first.' );
        MyException second = new MyException( 'second.' );
        MyException third = new MyException( 'third.' );

        // Set mocks
        MY_MOCKS.startStubbing();
        ( ( fflib_MyList.IList ) MY_MOCKS.doThrowWhen( new List<Exception>{ first, second, third }, MY_MOCK_LIST ) ).add( 'Hello' );
        MY_MOCKS.stopStubbing();

        // Then - validate
        assertExceptionMessageOnVoidMethod( 'first.' );
        assertExceptionMessageOnVoidMethod( 'second.' );
        assertExceptionMessageOnVoidMethod( 'third.' );

        assertExceptionMessageOnVoidMethod( 'third.' );
        assertExceptionMessageOnVoidMethod( 'third.' );
    }

    @IsTest
    private static void thatMultipleVoidMethodsThrowsMultipleExceptions(){
        // Create mocks
        MyException first = new MyException( 'first.' );
        MyException second = new MyException( 'second.' );
        MyException third = new MyException( 'third.' );

        MyException first2 = new MyException( 'first2.' );
        MyException second2 = new MyException( 'second2.' );
        MyException third2 = new MyException( 'third2.' );

        // Set mocks
        MY_MOCKS.startStubbing();
        ( ( fflib_MyList.IList ) MY_MOCKS.doThrowWhen( new List<Exception>{ first2, second2, third2 }, MY_MOCK_LIST ) ).addMore( 'Hello' );
        ( ( fflib_MyList.IList ) MY_MOCKS.doThrowWhen( new List<Exception>{ first, second, third }, MY_MOCK_LIST ) ).add( 'Hello' );
        MY_MOCKS.stopStubbing();

        // Then - validate
        assertExceptionMessageOnVoidMethod( 'first.' );
        assertExceptionMessageOnVoidMethod( 'second.' );
        assertExceptionMessageOnVoidMethod( 'third.' );

        assertExceptionMessageOnVoidMethod( 'third.' );
        assertExceptionMessageOnVoidMethod( 'third.' );


        assertExceptionMessageOnAddMoreVoidMethod( 'first2.' );
        assertExceptionMessageOnAddMoreVoidMethod( 'second2.' );
        assertExceptionMessageOnAddMoreVoidMethod( 'third2.' );

        assertExceptionMessageOnAddMoreVoidMethod( 'third2.' );
        assertExceptionMessageOnAddMoreVoidMethod( 'third2.' );
    }

    @IsTest
    private static void thatStubbingMutipleTimesVoidMethodThrowsMultipleExceptionsOverride(){
        // Create mocks
        MyException beforeFirst = new MyException( 'before first.' );

        MyException first = new MyException( 'first.' );
        MyException second = new MyException( 'second.' );
        MyException third = new MyException( 'third.' );

        MyException fourth = new MyException( 'fourth.' );
        MyException fifth = new MyException( 'fifth.' );
        MyException sixth = new MyException( 'sixth.' );

        // Set mocks
        MY_MOCKS.startStubbing();
        ( ( fflib_MyList.IList ) MY_MOCKS.doThrowWhen( new List<Exception>{ first, second, third }, MY_MOCK_LIST ) ).add( 'Hello' );
        ( ( fflib_MyList.IList ) MY_MOCKS.doThrowWhen( new List<Exception>{ fourth, fifth, sixth }, MY_MOCK_LIST ) ).add( 'Hello' );
        MY_MOCKS.stopStubbing();

        // Then - validate
        assertExceptionMessageOnVoidMethod( 'fourth.' );
        assertExceptionMessageOnVoidMethod( 'fifth.' );
        assertExceptionMessageOnVoidMethod( 'sixth.' );

        assertExceptionMessageOnVoidMethod( 'sixth.' );
        assertExceptionMessageOnVoidMethod( 'sixth.' );
    }

    @IsTest
    private static void thatStubbingMutipleTimesVoidMethodThrowsMultipleExceptionsOverrideWithSingleException(){
        // Create mocks
        MyException beforeFirst = new MyException( 'before first.' );

        MyException first = new MyException( 'first.' );
        MyException second = new MyException( 'second.' );
        MyException third = new MyException( 'third.' );

        MyException fourth = new MyException( 'fourth.' );
        MyException fifth = new MyException( 'fifth.' );
        MyException sixth = new MyException( 'sixth.' );

        // Set mocks
        MY_MOCKS.startStubbing();
        ( ( fflib_MyList.IList ) MY_MOCKS.doThrowWhen( new List<Exception>{ first, second, third }, MY_MOCK_LIST ) ).add( 'Hello' );
        ( ( fflib_MyList.IList ) MY_MOCKS.doThrowWhen( fourth, MY_MOCK_LIST ) ).add( 'Hello' );
        MY_MOCKS.stopStubbing();

        // Then - validate
        assertExceptionMessageOnVoidMethod( 'fourth.' );
        assertExceptionMessageOnVoidMethod( 'fourth.' );
    }

    @IsTest
    private static void thatExceptionIsthrownWhenStubbingIsNotDone(){
        // Set mocks
        MY_MOCKS.startStubbing();
        MY_MOCKS.when( MY_MOCK_LIST.get( 1 ) );
        MY_MOCKS.stopStubbing();

        // When - perform test
        try{
            MY_MOCK_LIST.get( 1 );
            System.Assert.fail( 'This Exception should never been thrown' );
        } catch( fflib_ApexMocks.ApexMocksException myex ){
            // Then - validate
            System.Assert.areEqual(
                'The stubbing is not correct, no return values have been set.',
                myex.getMessage(), 'the message reported by the exception is not correct' );
        }
    }

    @IsTest
    private static void thatExceptionIsthrownWhenReturnMultiPassEmptyList(){
        try{
            // Set mocks
            MY_MOCKS.startStubbing();
            MY_MOCKS.when( MY_MOCK_LIST.get( 1 ) ).thenReturnMulti( new List<Object>() );
            MY_MOCKS.stopStubbing();
            System.Assert.fail( 'This Exception should never been thrown' );
        } catch( fflib_ApexMocks.ApexMocksException myex ){
            // Then - validate
            System.Assert.areEqual(
                'The stubbing is not correct, no return values have been set.',
                myex.getMessage(), 'the message reported by the exception is not correct' );
        }
    }

    @IsTest
    private static void thatExceptionIsthrownWhenReturnMultiPassNullList(){
        try{
            // Set mocks
            MY_MOCKS.startStubbing();
            MY_MOCKS.when( MY_MOCK_LIST.get( 1 ) ).thenReturnMulti( null );
            MY_MOCKS.stopStubbing();
            System.Assert.fail( 'This Exception should never been thrown' );
        } catch( fflib_ApexMocks.ApexMocksException myex ){
            // Then - validate
            System.Assert.areEqual(
                'The stubbing is not correct, no return values have been set.',
                myex.getMessage(), 'the message reported by the exception is not correct' );
        }
    }

    @IsTest
    private static void thatExceptionIsthrownWhenThrowMultiPassEmptyList(){
        try{
            // Set mocks
            MY_MOCKS.startStubbing();
            MY_MOCKS.when( MY_MOCK_LIST.get( 1 ) ).thenThrowMulti( new List<Exception>() );
            MY_MOCKS.stopStubbing();
            System.Assert.fail( 'This Exception should never been thrown' );
        } catch( fflib_ApexMocks.ApexMocksException myex ){
            // Then - validate
            System.Assert.areEqual(
                'The stubbing is not correct, no return values have been set.',
                myex.getMessage(), 'the message reported by the exception is not correct' );
        }
    }

    @IsTest
    private static void thatExceptionIsthrownWhenThrowMultiPassNullList(){
        try{
            // Set mocks
            MY_MOCKS.startStubbing();
            MY_MOCKS.when( MY_MOCK_LIST.get( 1 ) ).thenThrowMulti( null );
            MY_MOCKS.stopStubbing();

            System.Assert.fail( 'This Exception should never been thrown' );
        } catch( fflib_ApexMocks.ApexMocksException myex ){
            // Then - validate
            System.Assert.areEqual(
                'The stubbing is not correct, no return values have been set.',
                myex.getMessage(), 'the message reported by the exception is not correct' );
        }
    }

    @IsTest
    private static void thatNullCanBeUsedAsReturnValue(){
        // Set mocks
        MY_MOCKS.startStubbing();
        MY_MOCKS.when( MY_MOCK_LIST.get( 1 ) ).thenReturn( null );
        MY_MOCKS.stopStubbing();

        // Then - validate
        System.Assert.isNull( MY_MOCK_LIST.get( 1 ), 'it should be possible stub using the null value' );
    }

    @IsTest
    private static void thatNullCanBeUsedAsExceptionvalue(){
        // Set mocks
        MY_MOCKS.startStubbing();
        MY_MOCKS.when( MY_MOCK_LIST.get( 1 ) ).thenThrow( null );
        MY_MOCKS.stopStubbing();

        // Then - validate
        System.Assert.isNull( MY_MOCK_LIST.get( 1 ), 'it should be possible stub using the null value' );
    }


    private static void assertExceptionMessage( String expectedMessage ){
        try{
            // Set mocks
            MY_MOCK_LIST.get( 1 );
            System.Assert.fail( 'This Exception should never been thrown' );
        } catch( MyException myex ){
            // Then - validate
            System.Assert.areEqual( expectedMessage, myex.getMessage(), 'the message reported by the exception is not correct' );
        }
    }

    private static void assertExceptionMessageForGet2( String expectedMessage ){
        try{
            // Set mocks
            MY_MOCK_LIST.get2( 2, 'Hello.' );
            System.Assert.fail( 'This Exception should never been thrown' );
        } catch( MyException myex ){
            // Then - validate
            System.Assert.areEqual( expectedMessage, myex.getMessage(), 'the message reported by the exception is not correct' );
        }
    }

    private static void assertExceptionMessageOnVoidMethod( String expectedMessage ){
        try{
            // Set mocks
            MY_MOCK_LIST.add( 'Hello' );
            System.Assert.fail( 'This Exception should never been thrown' );
        } catch( MyException myex ){
            // Then - validate
            System.Assert.areEqual( expectedMessage, myex.getMessage(), 'the message reported by the exception is not correct' );
        }
    }

    private static void assertExceptionMessageOnAddMoreVoidMethod( String expectedMessage ){
        try{
            // Set mocks
            MY_MOCK_LIST.addMore( 'Hello' );
            System.Assert.fail( 'This Exception should never been thrown' );
        } catch( MyException myex ){
            // Then - validate
            System.Assert.areEqual( expectedMessage, myex.getMessage(), 'the message reported by the exception is not correct' );
        }
    }

    private static void assertReturnedValue( String expectedValue ){
        System.Assert.areEqual( expectedValue, MY_MOCK_LIST.get( 1 ), 'the method did not returned the expected value' );
    }

    private static void assertReturnedValueForGet2( String expectedValue ){
        System.Assert.areEqual( expectedValue, MY_MOCK_LIST.get2( 2, 'Hello.' ), 'the method did not returned the expected value' );
    }

    @isTest
    static void thatToStringReturnsSimpleStringValue(){
        System.Assert.areEqual( 'fflib_ApexMocks', '' + new fflib_ApexMocks() );
    }

    private class MyException extends Exception{}

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

    private class BasicAnswer implements fflib_Answer{
        public Object answer( fflib_InvocationOnMock invocation ){
            actualInvocation = invocation;
            return null;
        }
    }
}
