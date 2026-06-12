/**
 * Copyright (c) 2014-2017 FinancialForce.com, inc.  All rights reserved.
 */
@IsTest( isParallel = true )
private with sharing class fflib_InOrderTest{

    private static fflib_ApexMocks MY_MOCKS = new fflib_ApexMocks();

    @IsTest
    private static void thatVerifyInOrderAllTheMethodsCalled(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test
        firstMock.add( '1-1' );
        firstMock.add( '1-2' );
        firstMock.add( '1-3' );
        firstMock.add( '1-4' );

        // Then - validate
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '1-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '1-2' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '1-3' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '1-4' );

        try{
            ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '1-2' );
            System.Assert.fail( 'Expected fflib_ApexMocks.ApexMocksException to be thrown. This assertion should never be triggered, as try should fail because 1-2 is wrong order' );
        } catch( fflib_ApexMocks.ApexMocksException error ){
            System.Assert.areEqual( 'EXPECTED COUNT: 1 in order'
                + '\nACTUAL COUNT: 0'
                + '\nMETHOD: fflib_MyList__sfdc_ApexStub.add(String)'
                + '\n---'
                + '\nACTUAL ARGS: ("1-1"), ("1-2"), ("1-3"), ("1-4")'
                + '\n---'
                + '\nEXPECTED ARGS: "1-2"',
                error.getMessage(),
                'Unexpected verify fail message' );
        }
    }

    @IsTest
    private static void thatVerifyInOrderDifferentMethodsCalledWithSameArguments(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test
        firstMock.add( '1-1' );
        firstMock.addMore( '1-1' );
        firstMock.add( '1-2' );
        firstMock.addMore( '1-2' );
        firstMock.add( '1-3' );
        firstMock.addMore( '1-3' );
        firstMock.add( '1-4' );
        firstMock.addMore( '1-4' );

        // Then - validate
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '1-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).addMore( '1-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).addMore( '1-3' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '1-4' );
    }

    @IsTest
    private static void thatVerifyInOrderDifferentMethodsCalledWithSameArgumentsOrderFail(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test
        firstMock.add( '1-1' );
        firstMock.addMore( '1-1' );
        firstMock.add( '1-2' );
        firstMock.addMore( '1-2' );

        // Then - validate
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).addMore( '1-1' );

        try{
            ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '1-1' );
            System.Assert.fail( 'Expected fflib_ApexMocks.ApexMocksException to be thrown. This assertion should never be triggered because 1-1 is called before the addMore(1-1)' );
        } catch( fflib_ApexMocks.ApexMocksException error ){
            System.Assert.areEqual( 'EXPECTED COUNT: 1 in order'
                + '\nACTUAL COUNT: 0'
                + '\nMETHOD: fflib_MyList__sfdc_ApexStub.add(String)'
                + '\n---'
                + '\nACTUAL ARGS: ("1-1"), ("1-1"), ("1-2"), ("1-2")'
                + '\n---'
                + '\nEXPECTED ARGS: "1-1"',
                error.getMessage(),
                'Unexpected verify fail message' );
        }
    }

    @IsTest
    private static void thatVerifyInOrderDifferentMethodsCalledWithSameArgumentsDoubleCallFail(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test
        firstMock.add( '1-1' );
        firstMock.addMore( '1-1' );
        firstMock.add( '1-2' );
        firstMock.addMore( '1-2' );

        // Then - validate
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).addMore( '1-1' );

        try{
            ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).addMore( '1-1' );
            System.Assert.fail( 'Expected fflib_ApexMocks.ApexMocksException to be thrown. This assertion should never be triggered because addMore(1-1) is called only Once' );
        } catch( fflib_ApexMocks.ApexMocksException error ){
            System.Assert.areEqual( 'EXPECTED COUNT: 1 in order'
                + '\nACTUAL COUNT: 0'
                + '\nMETHOD: fflib_MyList__sfdc_ApexStub.addMore(String)'
                + '\n---'
                + '\nACTUAL ARGS: ("1-1"), ("1-1"), ("1-2"), ("1-2")'
                + '\n---'
                + '\nEXPECTED ARGS: "1-1"',
                error.getMessage(),
                'Unexpected verify fail message' );
        }
    }

    @IsTest
    private static void thatVerifyInOrderCallMethodWithMatches(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test
        firstMock.add( '1-0' );
        firstMock.add( '1-11' );
        firstMock.add( '1-12' );
        firstMock.add( '1-3' );
        firstMock.add( '1-4' );

        // Then - validate
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 2 ) ) ).add( fflib_Match.stringStartsWith( '1-1' ) );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '1-4' );
    }

    @IsTest
    private static void thatVerifyInOrderCallMethodWithMatchesFailsIfVerifyACallAlreadyInTheMatcher(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test
        firstMock.add( '1-0' );
        firstMock.add( '1-11' );
        firstMock.add( '1-12' );
        firstMock.add( '1-3' );
        firstMock.add( '1-4' );

        // Then - validate
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 2 ) ) ).add( fflib_Match.stringStartsWith( '1-1' ) );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '1-4' );

        try{
            ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '1-11' );
            System.Assert.fail( 'Expected fflib_ApexMocks.ApexMocksException to be thrown. This assertion should never be triggered because addMore(1-11) has been already verified using the matchers' );
        } catch( fflib_ApexMocks.ApexMocksException error ){
            System.Assert.areEqual( 'EXPECTED COUNT: 1 in order'
                + '\nACTUAL COUNT: 0'
                + '\nMETHOD: fflib_MyList__sfdc_ApexStub.add(String)'
                + '\n---'
                + '\nACTUAL ARGS: ("1-0"), ("1-11"), ("1-12"), ("1-3"), ("1-4")'
                + '\n---'
                + '\nEXPECTED ARGS: "1-11"',
                error.getMessage(),
                'Unexpected verify fail message' );
        }
    }

    @IsTest
    private static void thatVerifyInOrderCallMethodWithMultipleMatches(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test

        firstMock.add( '1-0' );
        firstMock.add( '1-1' );
        firstMock.add( '1-3' );
        firstMock.add( '1-4' );


        firstMock.add( '2-0' );
        firstMock.add( '2-1' );
        firstMock.add( '2-3' );
        firstMock.add( '2-4' );

        // Then - validate
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 4 ) ) ).add( fflib_Match.stringStartsWith( '1-' ) );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 4 ) ) ).add( fflib_Match.stringStartsWith( '2-' ) );
    }

    @IsTest
    private static void thatVerifyInOrderCallMethodWithMultipleMatchesMixed(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );
        firstMock.add( '1-2' );
        firstMock.add( '2-2' );
        firstMock.add( '1-3' );
        firstMock.add( '2-3' );
        firstMock.add( '1-4' );
        firstMock.add( '2-4' );

        // Then - validate
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 4 ) ) ).add( fflib_Match.stringStartsWith( '1-' ) );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( fflib_Match.stringStartsWith( '2-' ) );
    }

    @IsTest
    private static void thatVerifyInOrderCallMethodWithMultipleMatchesMixedFailWhenMatcherHaveAlreadyVerifiedMethod(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );
        firstMock.add( '1-2' );
        firstMock.add( '2-2' );
        firstMock.add( '1-3' );
        firstMock.add( '2-3' );
        firstMock.add( '1-4' );
        firstMock.add( '2-4' );

        // Then - validate
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 4 ) ) ).add( fflib_Match.stringStartsWith( '1-' ) );

        try{
            ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 4 ) ) ).add( '1-11' );
            System.Assert.fail( 'Expected fflib_ApexMocks.ApexMocksException to be thrown. This assertion should never be triggered because only one call for the 2- is available to verify' );
        } catch( fflib_ApexMocks.ApexMocksException error ){
            System.Assert.areEqual( 'EXPECTED COUNT: 4 in order'
                + '\nACTUAL COUNT: 0'
                + '\nMETHOD: fflib_MyList__sfdc_ApexStub.add(String)'
                + '\n---'
                + '\nACTUAL ARGS: ("1-1"), ("2-1"), ("1-2"), ("2-2"), ("1-3"), ("2-3"), ("1-4"), ("2-4")'
                + '\n---'
                + '\nEXPECTED ARGS: "1-11"',
                error.getMessage(),
                'Unexpected verify fail message' );
        }
    }

    @IsTest
    private static void thatVerifyInOrderCanSkipMethodsCalledUntilFindTheOneThatNeedsVerify(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test
        firstMock.add( '1-1' );
        firstMock.add( '1-2' );
        firstMock.add( '1-3' );
        firstMock.add( '1-4' );

        // Then - validate
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '1-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '1-4' );

        try{
            ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '1-2' );
            System.Assert.fail( 'Expected fflib_ApexMocks.ApexMocksException to be thrown. This assertion should never be triggered because it is out of order' );
        } catch( fflib_ApexMocks.ApexMocksException error ){
            System.Assert.areEqual( 'EXPECTED COUNT: 1 in order'
                + '\nACTUAL COUNT: 0'
                + '\nMETHOD: fflib_MyList__sfdc_ApexStub.add(String)'
                + '\n---'
                + '\nACTUAL ARGS: ("1-1"), ("1-2"), ("1-3"), ("1-4")'
                + '\n---'
                + '\nEXPECTED ARGS: "1-2"',
                error.getMessage(),
                'Unexpected verify fail message' );
        }
    }

    @IsTest
    private static void thatVerifyInOrderCanHandleMultipleMethodsCalls(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test
        firstMock.add( '1-1' );
        firstMock.add( '1-2' );
        firstMock.add( '1-2' );
        firstMock.add( '1-2' );
        firstMock.add( '1-3' );
        firstMock.add( '1-4' );

        // Then - validate
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 3 ) ) ).add( '1-2' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '1-4' );
    }

    @IsTest
    private static void thatVerifyInOrderCanHandleMultipleMethodsCallsAndNotFailsIfVerifyCountIsGreaterThenExpected(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test
        firstMock.add( '1-1' );
        firstMock.add( '1-2' );
        firstMock.add( '1-2' );
        firstMock.add( '1-2' );
        firstMock.add( '1-3' );
        firstMock.add( '1-4' );

        // Then - validate

        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 2 ) ) ).add( '1-2' );
    }

    @IsTest
    private static void thatVerifyInOrderCanHandleMultipleMethodsCallsButFailsIfVerifyCountIsLessThenExpected(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test
        firstMock.add( '1-1' );
        firstMock.add( '1-2' );
        firstMock.add( '1-2' );
        firstMock.add( '1-2' );
        firstMock.add( '1-3' );
        firstMock.add( '1-4' );

        // Then - validate
        try{
            ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 4 ) ) ).add( '1-2' );
            System.Assert.fail( 'Expected fflib_ApexMocks.ApexMocksException to be thrown. This assertion should never be triggered because it is actually called only 3 times' );
        } catch( fflib_ApexMocks.ApexMocksException e ){
            System.Assert.areEqual( 'EXPECTED COUNT: 4 in order'
                + '\nACTUAL COUNT: 3'
                + '\nMETHOD: fflib_MyList__sfdc_ApexStub.add(String)'
                + '\n---'
                + '\nACTUAL ARGS: ("1-1"), ("1-2"), ("1-2"), ("1-2"), ("1-3"), ("1-4")'
                + '\n---'
                + '\nEXPECTED ARGS: "1-2"',
                e.getMessage(),
                'Unexpected verify fail message' );
        }
    }

    @IsTest
    private static void thatVerifyInOrderCanHandleMultipleMocks(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_MyList secondMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_MyList thirdMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );

        fflib_InOrder inOrder = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock, secondMock } );

        // When - perform test
        firstMock.add( '1-1' );
        secondMock.add( '2-1' );
        thirdMock.add( '3-1' );

        firstMock.add( '1-2' );
        secondMock.add( '2-2' );
        thirdMock.add( '3-2' );

        firstMock.add( '1-1' );
        firstMock.add( '1-3' );
        secondMock.add( '2-3' );
        thirdMock.add( '3-3' );

        // Then - validate
        ( ( fflib_MyList.IList ) inOrder.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '1-1' );
        ( ( fflib_MyList.IList ) inOrder.verify( secondMock, MY_MOCKS.calls( 1 ) ) ).add( '2-1' );
        ( ( fflib_MyList.IList ) inOrder.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '1-2' );
        ( ( fflib_MyList.IList ) inOrder.verify( secondMock, MY_MOCKS.calls( 1 ) ) ).add( '2-2' );
        ( ( fflib_MyList.IList ) inOrder.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '1-3' );
        ( ( fflib_MyList.IList ) inOrder.verify( secondMock, MY_MOCKS.calls( 1 ) ) ).add( '2-3' );

        ( ( fflib_MyList.IList ) MY_MOCKS.verify( thirdMock, MY_MOCKS.times( 3 ) ) ).add( fflib_Match.stringStartsWith( '3-' ) );
    }

    @IsTest
    private static void thatVerifyInOrderCanHandleMixedInOrderInstance(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_MyList secondMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_MyList thirdMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );

        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );
        fflib_InOrder inOrder2 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock, secondMock } );

        // When - perform test
        firstMock.add( '1-1' );
        secondMock.add( '2-1' );
        thirdMock.add( '3-1' );

        firstMock.add( '1-2' );
        secondMock.add( '2-2' );
        thirdMock.add( '3-2' );

        firstMock.add( '1-1' );
        firstMock.add( '1-3' );
        secondMock.add( '2-3' );
        thirdMock.add( '3-3' );

        // Then - validate
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 2 ) ) ).add( '1-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '1-3' );

        ( ( fflib_MyList.IList ) inOrder2.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '1-1' );
        ( ( fflib_MyList.IList ) inOrder2.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '1-2' );
        ( ( fflib_MyList.IList ) inOrder2.verify( secondMock, MY_MOCKS.calls( 1 ) ) ).add( '2-2' );
        ( ( fflib_MyList.IList ) inOrder2.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '1-3' );
        ( ( fflib_MyList.IList ) inOrder2.verify( secondMock, MY_MOCKS.calls( 1 ) ) ).add( '2-3' );

        ( ( fflib_MyList.IList ) MY_MOCKS.verify( thirdMock, MY_MOCKS.times( 3 ) ) ).add( fflib_Match.stringStartsWith( '3-' ) );
    }

    @IsTest
    private static void thatVerifyInOrderThrownExceptionIfVerifyMockInstanceNotInTheSet(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_MyList secondMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );

        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test
        firstMock.add( '1-1' );
        secondMock.add( '2-1' );

        // Then - validate
        try{
            ( ( fflib_MyList.IList ) inOrder1.verify( secondMock, MY_MOCKS.calls( 1 ) ) ).add( '2-1' );
            System.Assert.fail( 'Expected fflib_ApexMocks.ApexMocksException to be thrown. This assertion should never be triggered because this verify is not in the list of mocks to verify' );
        } catch( fflib_ApexMocks.ApexMocksException mockexcep ){
            System.Assert.areEqual( 'EXPECTED COUNT: 1 in order'
                + '\nACTUAL COUNT: 0'
                + '\nMETHOD: fflib_MyList__sfdc_ApexStub.add(String)'
                + '\n---'
                + '\nACTUAL ARGS: ("1-1"), ("2-1")'
                + '\n---'
                + '\nEXPECTED ARGS: "2-1"',
                mockexcep.getMessage(),
                'Unexpected verify fail message' );
        }
    }

    @IsTest
    private static void thatVerifyInOrderThrownExceptionWithCustomMessage(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );

        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        String customErrorMessage = 'Some custom error message';

        // When - perform test
        firstMock.add( '1-1' );
        firstMock.add( '1-2' );

        // Then - validate
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '1-2' );
        try{
            ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.description( customErrorMessage ) ) ).add( '1-1' );
            System.Assert.fail( 'Expected fflib_ApexMocks.ApexMocksException to be thrown. This assertion should never be triggered' );
        } catch( fflib_ApexMocks.ApexMocksException e ){
            System.Assert.areEqual( 'EXPECTED COUNT: 1 in order'
                + '\nACTUAL COUNT: 0'
                + '\nMETHOD: fflib_MyList__sfdc_ApexStub.add(String)'
                + '\nSome custom error message'
                + '\n---'
                + '\nACTUAL ARGS: ("1-1"), ("1-2")'
                + '\n---'
                + '\nEXPECTED ARGS: "1-1"',
                e.getMessage(),
                'Unexpected verify fail message' );
        }
    }

    @IsTest
    private static void thatVerifyAtMostThrowsExceptionBecauseNotImplemented(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );

        // Then - validate
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '1-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '2-1' );
        try{
            ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.atMost( 3 ) ) ).add( '1-1' );
            System.Assert.fail( 'Expected fflib_ApexMocks.ApexMocksException to be thrown. This assertion should never be triggered because this method is not implemented for InOrder class' );
        } catch( fflib_ApexMocks.ApexMocksException mockExcept ){
            String expectedMessage = 'The ATMOST method is not implemented for the fflib_InOrder class';
            System.Assert.areEqual( expectedMessage, mockExcept.getMessage(), ' the error message is not as expected' );
        }
    }

    @IsTest
    private static void thatVerifyBetweenThrowsExceptionBecauseNotImplemented(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );

        // Then - validate
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '1-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '2-1' );
        try{
            ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.between( 3, 5 ) ) ).add( '1-1' );
            System.Assert.fail( 'Expected fflib_ApexMocks.ApexMocksException to be thrown. This assertion should never be triggered because this method is not implemented for InOrder class' );
        } catch( fflib_ApexMocks.ApexMocksException mockExcept ){
            String expectedMessage = 'The BETWEEN method is not implemented for the fflib_InOrder class';
            System.Assert.areEqual( expectedMessage, mockExcept.getMessage(), ' the error message is not as expected' );
        }
    }

    @IsTest
    private static void thatVerifyNever(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );

        // Then - validate
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '1-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '2-1' );

        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.never() ) ).add( '3-1' );
    }

    @IsTest
    private static void thatVerifyNeverWithMatchers(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );

        // Then - validate
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '1-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '2-1' );

        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.never() ) ).add( fflib_Match.stringStartsWith( '3-' ) );
    }

    @IsTest
    private static void thatVerifyNeverFailsWhenCalled(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );

        // Then - validate
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '1-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '2-1' );
        try{
            ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.never() ) ).add( '1-1' );
            System.Assert.fail( 'Expected fflib_ApexMocks.ApexMocksException to be thrown. This assertion should never be triggered because the method has been called' );
        } catch( fflib_ApexMocks.ApexMocksException e ){
            System.Assert.areEqual( 'EXPECTED COUNT: 0 in order'
                + '\nACTUAL COUNT: 4'
                + '\nMETHOD: fflib_MyList__sfdc_ApexStub.add(String)'
                + '\n---'
                + '\nACTUAL ARGS: ("1-1"), ("2-1"), ("1-1"), ("1-1"), ("1-1"), ("1-1"), ("2-1")'
                + '\n---'
                + '\nEXPECTED ARGS: "1-1"',
                e.getMessage(),
                'Unexpected verify fail message' );
        }
    }

    @IsTest
    private static void thatVerifyNeverFailsWhenCalledWithMatchers(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );

        // Then - validate
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '1-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '2-1' );
        try{
            ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.never() ) ).add( fflib_Match.stringStartsWith( '1-' ) );
            System.Assert.fail( 'This Exception should never been thrown because the method has been called' );
        } catch( fflib_ApexMocks.ApexMocksException e ){
            System.Assert.areEqual( 'EXPECTED COUNT: 0 in order'
                + '\nACTUAL COUNT: 4'
                + '\nMETHOD: fflib_MyList__sfdc_ApexStub.add(String)'
                + '\n---'
                + '\nACTUAL ARGS: ("1-1"), ("2-1"), ("1-1"), ("1-1"), ("1-1"), ("1-1"), ("2-1")'
                + '\n---'
                + '\nEXPECTED ARGS: [starts with "1-"]',
                e.getMessage(),
                'Unexpected verify fail message' );
        }
    }

    @IsTest
    private static void thatVerifyThrowsExceptionWhenCallsIsInvokedFromStandardMock(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );

        // When - perform test
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );
        firstMock.add( '1-1' );

        // Then - validate
        try{
            ( ( fflib_MyList.IList ) MY_MOCKS.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '1-1' );
            System.Assert.fail( 'This Exception should never been thrown because this method is only implemented for InOrder class' );
        } catch( fflib_ApexMocks.ApexMocksException mockExcept ){
            String expectedMessage = 'The calls() method is available only in the InOrder Verification.';
            System.Assert.areEqual( expectedMessage, mockExcept.getMessage(), ' the error message is not as expected' );
        }
    }

    @IsTest
    private static void thatVerifyNoMoreInteractionsFails(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test
        firstMock.add( '1-1', '1-1', '1-1', '1-1' );
        firstMock.addMore( '2-1' );
        firstMock.add( '1-1' );

        // Then - validate
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '1-1', '1-1', '1-1', '1-1' );
        try{
            inOrder1.verifyNoMoreInteractions();
            System.Assert.fail( 'This Exception should never been thrown because there are other interactions' );
        } catch( fflib_ApexMocks.ApexMocksException mockExcept ){
            String expectedMessage = 'No more Interactions were expected after the ' + fflib_MyList.getStubClassName() +
                '.add(String, String, String, String) method.';
            System.Assert.areEqual( expectedMessage, mockExcept.getMessage(), ' the error message is not as expected' );
        }
    }

    @IsTest
    private static void thatVerifyNoMoreInteractionsFailsWhenOnLyOneMethodLeft(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test
        firstMock.add( '1-1', '1-1', '1-1', '1-1' );
        firstMock.addMore( '2-1' );
        firstMock.add( '1-1' );

        // Then - validate
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).addMore( '2-1' );
        try{
            inOrder1.verifyNoMoreInteractions();
            System.Assert.fail( 'This Exception should never been thrown because there are other interactions' );
        } catch( fflib_ApexMocks.ApexMocksException mockExcept ){
            String expectedMessage = 'No more Interactions were expected after the ' + fflib_MyList.getStubClassName() + '.addMore(String) method.';
            System.Assert.areEqual( expectedMessage, mockExcept.getMessage(), ' the error message is not as expected' );
        }
    }

    @IsTest
    private static void thatVerifyNoMoreInteractionsPass(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_MyList secondMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );
        fflib_InOrder inOrder2 = new fflib_InOrder( MY_MOCKS, new List<Object>{ secondMock } );

        // When - perform test
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );
        firstMock.add( '1-1' );
        secondMock.add( '1-1' );
        secondMock.add( '1-1' );

        // Then - validate
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '1-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '2-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '1-1' );

        inOrder1.verifyNoMoreInteractions();

        ( ( fflib_MyList.IList ) inOrder2.verify( secondMock, MY_MOCKS.calls( 2 ) ) ).add( '1-1' );

        inOrder2.verifyNoMoreInteractions();
    }

    @IsTest
    private static void thatVerifyNoMoreInteractionsFailsWhenNoInteracionOccurs(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );
        firstMock.add( '1-1' );

        // Then - validate
        try{
            inOrder1.verifyNoMoreInteractions();
            System.Assert.fail( 'This Exception should never been thrown because there are other interactions' );
        } catch( fflib_ApexMocks.ApexMocksException mockExcept ){
            String expectedMessage = 'No Interactions expected on this InOrder Mock instance!';
            System.Assert.areEqual( expectedMessage, mockExcept.getMessage(), ' the error message is not as expected' );
        }
    }

    @IsTest
    private static void thatVerifyNoInteractionsFails(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );
        firstMock.add( '1-1' );

        // Then - validate
        try{
            inOrder1.verifyNoInteractions();
            System.Assert.fail( 'This Exception should never been thrown because there are other interactions' );
        } catch( fflib_ApexMocks.ApexMocksException mockExcept ){
            String expectedMessage = 'No Interactions expected on this InOrder Mock instance!';
            System.Assert.areEqual( expectedMessage, mockExcept.getMessage(), ' the error message is not as expected' );
        }
    }

    @IsTest
    private static void thatVerifyNoInteractionsPass(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_MyList secondMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );


        // When - perform test
        secondMock.add( '1-2' );

        // Then - validate
        inOrder1.verifyNoInteractions();
    }

    @IsTest
    private static void thatStrictVerificationCanBePerformed(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );
        firstMock.add( '1-1' );
        firstMock.add( '4-1' );

        // Then - validate
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '1-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '2-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '1-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '4-1' );
    }

    @IsTest
    private static void thatMixedVerificationDoNotInterfierWithOtherImplementationChecking(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );
        firstMock.add( '1-1' );
        firstMock.add( '4-1' );

        // Then - validate
        ( ( fflib_MyList.IList ) MY_MOCKS.verify( firstMock, MY_MOCKS.times( 2 ) ) ).add( '1-1' );

        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '1-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '2-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '1-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '4-1' );

        ( ( fflib_MyList.IList ) MY_MOCKS.verify( firstMock, MY_MOCKS.times( 2 ) ) ).add( '1-1' );
    }

    @IsTest
    private static void thatVerifyAtLeastPassWithSameCallsOfAssertion(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test
        firstMock.add( '1-1' ); // Consumed by -> verify(firstMock, MY_MOCKS.calls(1))).add('1-1');
        firstMock.add( '2-1' ); // Consumed by -> verify(firstMock, MY_MOCKS.calls(1))).add('2-1');
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' ); // All consumed until there by -> verify(firstMock, MY_MOCKS.atLeast(3))).add('1-1');
        firstMock.add( '2-1' ); // Finally consumed by -> verify(firstMock, MY_MOCKS.calls(1))).add('2-1');

        // Then - validate
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '1-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '2-1' );

        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.atLeast( 3 ) ) ).add( '1-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '2-1' );
    }

    @IsTest
    private static void thatVerifyAtLeastPassWithMoreCallsThenAsserted(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test
        firstMock.add( '1-1' ); // Consumed by -> verify(firstMock, MY_MOCKS.calls(1))).add('1-1');
        firstMock.add( '2-1' ); // Consumed by -> verify(firstMock, MY_MOCKS.calls(1))).add('2-1');
        firstMock.add( '1-1' );
        firstMock.add( '1-1' ); // It verifies until here, but
        firstMock.add( '1-1' ); // This is consumed as well
        firstMock.add( '2-1' ); // Finally consumed by -> verify(firstMock, MY_MOCKS.calls(1))).add('2-1');

        // Then - validate
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '1-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '2-1' );

        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.atLeast( 2 ) ) ).add( '1-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '2-1' );
    }

    @IsTest
    private static void thatVerifyAtLeastThrowsErrorIfCalledLessTimes(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test
        firstMock.add( '1-1' ); // Consumed by -> verify(firstMock, MY_MOCKS.calls(1))).add('1-1');
        firstMock.add( '2-1' ); // Consumed by -> verify(firstMock, MY_MOCKS.calls(1))).add('2-1');
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' ); // There are then only 3 calls available, the assert 4 would fail
        firstMock.add( '2-1' );

        // Then - validate
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '1-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '2-1' );

        try{
            ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.atLeast( 4 ) ) ).add( '1-1' );
            System.Assert.fail( 'This Exception should never been thrown because atLeast is asserting 4 calls, instead there are only 3 not consumed calls' );
        } catch( fflib_ApexMocks.ApexMocksException mockExcept ){
            System.Assert.areEqual( 'EXPECTED COUNT: 4 in order'
                + '\nACTUAL COUNT: 3'
                + '\nMETHOD: fflib_MyList__sfdc_ApexStub.add(String)'
                + '\n---'
                + '\nACTUAL ARGS: ("1-1"), ("2-1"), ("1-1"), ("1-1"), ("1-1"), ("2-1")'
                + '\n---'
                + '\nEXPECTED ARGS: "1-1"',
                mockExcept.getMessage(),
                'Unexpected verify fail message' );
        }
    }

    @IsTest
    private static void thatVerifyAtLeastConsumeAllTheInstances(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test
        firstMock.add( '1-1' ); // Consumed by -> verify(firstMock, MY_MOCKS.calls(1))).add('1-1');
        firstMock.add( '2-1' ); // Consumed by -> verify(firstMock, MY_MOCKS.calls(1))).add('2-1');
        firstMock.add( '1-1' );
        firstMock.add( '1-1' ); // the verify atLeast(2) it verifies until here, but it keep going through the instances
        firstMock.add( '1-1' );
        firstMock.add( '2-1' ); // So this would fail because have to first consume all the instances of the ('1-1')
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );

        // Then - validate
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '1-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '2-1' );

        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.atLeast( 2 ) ) ).add( '1-1' );

        // Then - validate
        try{
            ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '2-1' );
            System.Assert.fail( 'This Exception should never been thrown because atLeast consumed all interactions of 1-1' );
        } catch( fflib_ApexMocks.ApexMocksException mockExcept ){
            System.Assert.areEqual( 'EXPECTED COUNT: 1 in order'
                + '\nACTUAL COUNT: 0'
                + '\nMETHOD: fflib_MyList__sfdc_ApexStub.add(String)'
                + '\n---'
                + '\nACTUAL ARGS: ("1-1"), ("2-1"), ("1-1"), ("1-1"), ("1-1"), ("2-1"), ("1-1"), ("1-1")'
                + '\n---'
                + '\nEXPECTED ARGS: "2-1"',
                mockExcept.getMessage(),
                'Unexpected verify fail message' );
        }
    }

    @IsTest
    private static void thatVerifyAtLeastConsumeAllTheInstancesForOnlyTheMethodVerified(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '2-1' ); // verify(firstMock, MY_MOCKS.atLeast(2))).add('2-1'); consume until here
        firstMock.add( '1-1' );
        firstMock.add( '1-1' ); // Those are then free for the second atLeast assertion

        // Then - validate
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.atLeast( 2 ) ) ).add( '2-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.atLeast( 2 ) ) ).add( '1-1' );
    }

    @IsTest
    private static void thatVerifyAtLeastOnce(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );
        firstMock.add( '1-1' );

        // Then - validate
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.atLeastOnce() ) ).add( '1-1' );
    }

    @IsTest
    private static void thatVerifyAtLeastOnceConsumesInstancesUntilLastMethodVerified(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );
        firstMock.add( '1-1' ); // Consumed until there by -> verify(firstMock, MY_MOCKS.atLeastOnce())).add('1-1');
        firstMock.add( '2-1' ); // Free for another assertion

        // Then - validate
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.atLeastOnce() ) ).add( '1-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.atLeastOnce() ) ).add( '2-1' );
    }

    @IsTest
    private static void thatVerifyAtLeastOnceThrowsErrorIfCalledLessTimes(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );
        firstMock.add( '1-1' );

        // Then - validate
        try{
            ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.atLeastOnce() ) ).add( '1-3' );
            System.Assert.fail( 'This Exception should never been thrown because ' +
                'atLeastOnce is asserted for 1 call, while method is not called at all with that argument' );
        } catch( fflib_ApexMocks.ApexMocksException mockExcept ){
            System.Assert.areEqual( 'EXPECTED COUNT: 1 in order'
                + '\nACTUAL COUNT: 0'
                + '\nMETHOD: fflib_MyList__sfdc_ApexStub.add(String)'
                + '\n---'
                + '\nACTUAL ARGS: ("1-1"), ("2-1"), ("1-1")'
                + '\n---'
                + '\nEXPECTED ARGS: "1-3"',
                mockExcept.getMessage(),
                'Unexpected verify fail message' );
        }
    }

    @IsTest
    private static void thatVerifyAtLeastOnceConsumesAllTheInstances(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' ); // All the instance have been consumed

        // Then - validate
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.atLeastOnce() ) ).add( '1-1' );
        try{
            ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '2-1' );
            System.Assert.fail( 'This Exception should never been thrown because atLeast has consumed all interactions of 1-1' );
        } catch( fflib_ApexMocks.ApexMocksException mockExcept ){
            System.Assert.areEqual( 'EXPECTED COUNT: 1 in order'
                + '\nACTUAL COUNT: 0'
                + '\nMETHOD: fflib_MyList__sfdc_ApexStub.add(String)'
                + '\n---'
                + '\nACTUAL ARGS: ("1-1"), ("2-1"), ("1-1"), ("2-1"), ("1-1"), ("1-1")'
                + '\n---'
                + '\nEXPECTED ARGS: "2-1"',
                mockExcept.getMessage(),
                'Unexpected verify fail message' );
        }
    }

    @IsTest
    private static void thatVerifyTimes(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );

        // Then - validate
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '1-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '2-1' );

        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.times( 3 ) ) ).add( '1-1' );
    }

    @IsTest
    private static void thatVerifyTimesThrowsExceptionIfCalledMoreTimesThanExpected(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );

        // Then - validate
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '1-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '2-1' );

        try{
            ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.times( 2 ) ) ).add( '1-1' );
            System.Assert.fail( 'This Exception should never been thrown because method is called more times than expected in verification' );
        } catch( fflib_ApexMocks.ApexMocksException mockExcept ){
            System.Assert.areEqual( 'EXPECTED COUNT: 2 in order'
                + '\nACTUAL COUNT: 3'
                + '\nMETHOD: fflib_MyList__sfdc_ApexStub.add(String)'
                + '\n---'
                + '\nACTUAL ARGS: ("1-1"), ("2-1"), ("1-1"), ("1-1"), ("1-1"), ("2-1")'
                + '\n---'
                + '\nEXPECTED ARGS: "1-1"',
                mockExcept.getMessage(),
                'Unexpected verify fail message' );
        }
    }

    @IsTest
    private static void thatVerifyTimesThrowsExceptionIfCalledLessTimesThanExpected(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );

        // Then - validate
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '1-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '2-1' );

        try{
            ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.times( 4 ) ) ).add( '1-1' );
            System.Assert.fail( 'This Exception should never been thrown because method has been called more times than expected in verification' );
        } catch( fflib_ApexMocks.ApexMocksException mockExcept ){
            System.Assert.areEqual( 'EXPECTED COUNT: 4 in order'
                + '\nACTUAL COUNT: 3'
                + '\nMETHOD: fflib_MyList__sfdc_ApexStub.add(String)'
                + '\n---'
                + '\nACTUAL ARGS: ("1-1"), ("2-1"), ("1-1"), ("1-1"), ("1-1"), ("2-1")'
                + '\n---'
                + '\nEXPECTED ARGS: "1-1"',
                mockExcept.getMessage(),
                'Unexpected verify fail message' );
        }
    }

    @IsTest
    private static void thatVerifyTimesPassWhenAnotherMethodIsCalledBetweenMethodsCalls(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );

        // Then - validate
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '1-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '2-1' );

        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.times( 4 ) ) ).add( '1-1' );

        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.times( 1 ) ) ).add( '2-1' );
    }

    @IsTest
    private static void thatVerifyTimesPassWhenAnotherMethodIsCalledBetweenMethodsCalls2(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );

        // Then - validate
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '1-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '2-1' );

        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.times( 3 ) ) ).add( '1-1' );

        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.times( 1 ) ) ).add( '2-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.times( 1 ) ) ).add( '1-1' );
    }

    @IsTest
    private static void thatVerifyTimesPassWhenAnotherMethodIsCalledBetweenMethodsCalls3(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );
        firstMock.add( '1-1' );

        // Then - validate
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '1-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '2-1' );

        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.times( 3 ) ) ).add( '1-1' );

        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.times( 1 ) ) ).add( '2-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.times( 2 ) ) ).add( '1-1' );

        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.times( 1 ) ) ).add( '2-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.times( 1 ) ) ).add( '1-1' );
    }

    @IsTest
    private static void thatVerifyTimesPassWhenAnotherMethodIsCalledBetweenMethodsCalls4(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );
        firstMock.add( '1-1' );

        // Then - validate
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '1-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '2-1' );

        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.times( 5 ) ) ).add( '1-1' );

        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.times( 1 ) ) ).add( '2-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.times( 1 ) ) ).add( '1-1' );
    }

    @IsTest
    private static void thatVerifyTimesThrowsExceptionWhenAnotherMethodIsCalledBetweenMethodsCalls(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );

        // Then - validate
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '1-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '2-1' );
        try{
            ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.times( 5 ) ) ).add( '1-1' );
            System.Assert.fail( 'This Exception should never been thrown because method has been called more times than expected in verification' );
        } catch( fflib_ApexMocks.ApexMocksException mockExcept ){
            System.Assert.areEqual( 'EXPECTED COUNT: 5 in order'
                + '\nACTUAL COUNT: 4'
                + '\nMETHOD: fflib_MyList__sfdc_ApexStub.add(String)'
                + '\n---'
                + '\nACTUAL ARGS: ("1-1"), ("2-1"), ("1-1"), ("1-1"), ("1-1"), ("2-1"), ("1-1"), ("2-1")'
                + '\n---'
                + '\nEXPECTED ARGS: "1-1"',
                mockExcept.getMessage(),
                'Unexpected verify fail message' );
        }
    }

    @IsTest
    private static void thatStrictVerificationCanBeEnforced(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );

        // Then - validate
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.times( 1 ) ) ).add( '1-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.times( 1 ) ) ).add( '2-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.times( 3 ) ) ).add( '1-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.times( 1 ) ) ).add( '2-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.times( 1 ) ) ).add( '1-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.times( 1 ) ) ).add( '2-1' );
    }

    @IsTest
    private static void thatTimesOneIsTheDefaultVerification(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );

        // Then - validate
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock ) ).add( '1-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock ) ).add( '2-1' );
        try{
            ( ( fflib_MyList.IList ) inOrder1.verify( firstMock ) ).add( '1-1' );
            System.Assert.fail( 'This Exception should never been thrown because method has been called more times than expected in verification' );
        } catch( fflib_ApexMocks.ApexMocksException mockExcept ){
            System.Assert.areEqual( 'EXPECTED COUNT: 1 in order'
                + '\nACTUAL COUNT: 4'
                + '\nMETHOD: fflib_MyList__sfdc_ApexStub.add(String)'
                + '\n---'
                + '\nACTUAL ARGS: ("1-1"), ("2-1"), ("1-1"), ("1-1"), ("1-1"), ("2-1"), ("1-1"), ("2-1")'
                + '\n---'
                + '\nEXPECTED ARGS: "1-1"',
                mockExcept.getMessage(),
                'Unexpected verify fail message' );
        }
    }

    @IsTest
    private static void thatWithOldNotation(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );

        // Then - validate
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '1-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '2-1' );

        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, 3 ) ).add( '1-1' );
    }

    @IsTest
    private static void thatWithOldNotationThrowsExceptionIfCalledMoreTimesThanExpected(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );

        // Then - validate
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '1-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '2-1' );
        try{
            ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, 2 ) ).add( '1-1' );
            System.Assert.fail( 'This Exception should never been thrown because method has been called more times than expected in verification' );
        } catch( fflib_ApexMocks.ApexMocksException mockExcept ){
            System.Assert.areEqual( 'EXPECTED COUNT: 2 in order'
                + '\nACTUAL COUNT: 3'
                + '\nMETHOD: fflib_MyList__sfdc_ApexStub.add(String)'
                + '\n---'
                + '\nACTUAL ARGS: ("1-1"), ("2-1"), ("1-1"), ("1-1"), ("1-1"), ("2-1")'
                + '\n---'
                + '\nEXPECTED ARGS: "1-1"',
                mockExcept.getMessage(),
                'Unexpected verify fail message' );
        }
    }

    @IsTest
    private static void thatWithOldNotationThrowsExceptionIfCalledLessTimesThanExpected(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );

        // Then - validate
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '1-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '2-1' );
        try{
            ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, 4 ) ).add( '1-1' );
            System.Assert.fail( 'This Exception should never been thrown because method has been called more times than expected in verification' );
        } catch( fflib_ApexMocks.ApexMocksException mockExcept ){
            System.Assert.areEqual( 'EXPECTED COUNT: 4 in order'
                + '\nACTUAL COUNT: 3'
                + '\nMETHOD: fflib_MyList__sfdc_ApexStub.add(String)'
                + '\n---'
                + '\nACTUAL ARGS: ("1-1"), ("2-1"), ("1-1"), ("1-1"), ("1-1"), ("2-1")'
                + '\n---'
                + '\nEXPECTED ARGS: "1-1"',
                mockExcept.getMessage(),
                'Unexpected verify fail message' );
        }
    }

    @IsTest
    private static void thatWithOldNotationPassWhenAnotherMethodIsCalledBetweenMethodsCalls(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );

        // Then - validate
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '1-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '2-1' );

        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, 4 ) ).add( '1-1' );
    }

    @IsTest
    private static void thatWithOldNotationThrowsExceptionWhenAnotherMethodIsCalledBetweenMethodsCalls(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );

        // Then - validate
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '1-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '2-1' );
        try{
            ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, 5 ) ).add( '1-1' );
            System.Assert.fail( 'This Exception should never been thrown because method has been called more times than expected in verification' );
        } catch( fflib_ApexMocks.ApexMocksException mockExcept ){
            System.Assert.areEqual( 'EXPECTED COUNT: 5 in order'
                + '\nACTUAL COUNT: 4'
                + '\nMETHOD: fflib_MyList__sfdc_ApexStub.add(String)'
                + '\n---'
                + '\nACTUAL ARGS: ("1-1"), ("2-1"), ("1-1"), ("1-1"), ("1-1"), ("2-1"), ("1-1"), ("2-1")'
                + '\n---'
                + '\nEXPECTED ARGS: "1-1"',
                mockExcept.getMessage(),
                'Unexpected verify fail message' );
        }
    }

    @IsTest
    private static void thatStrictVerificationCanBeEnforcedWithOldNotation(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );

        // Then - validate
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, 1 ) ).add( '1-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, 1 ) ).add( '2-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, 3 ) ).add( '1-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, 1 ) ).add( '2-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, 1 ) ).add( '1-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, 1 ) ).add( '2-1' );
    }

    @IsTest
    private static void thatStrictVerificationCanBeEnforcedWithOldNotationUsingDefaultTimesOne(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );

        // Then - validate
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock ) ).add( '1-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock ) ).add( '2-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, 3 ) ).add( '1-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock ) ).add( '2-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock ) ).add( '1-1' );
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock ) ).add( '2-1' );
    }

    @IsTest
    private static void thatVerifyAtLeastConsumesAllTheInstances2(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        //When
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '1-1' );
        firstMock.add( '2-1' );
        firstMock.add( '2-1' );
        firstMock.add( '2-1' );
        firstMock.add( '2-1' );
        firstMock.add( '2-1' );
        firstMock.add( '1-1' );

        // Then - validate
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.atLeast( 2 ) ) ).add( '1-1' );
        try{
            ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 1 ) ) ).add( '2-1' );
            System.Assert.fail( 'This Exception should never been thrown because atLeast has consumed all calls' );
        } catch( fflib_ApexMocks.ApexMocksException mockExcept ){
            System.Assert.areEqual( 'EXPECTED COUNT: 1 in order'
                + '\nACTUAL COUNT: 0'
                + '\nMETHOD: fflib_MyList__sfdc_ApexStub.add(String)'
                + '\n---'
                + '\nACTUAL ARGS: ("1-1"), ("1-1"), ("1-1"), ("2-1"), ("2-1"), ("2-1"), ("2-1"), ("2-1"), ("1-1")'
                + '\n---'
                + '\nEXPECTED ARGS: "2-1"',
                mockExcept.getMessage(),
                'Unexpected verify fail message' );
        }
    }

    @IsTest
    private static void verifyAtLeastAndCapture(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test
        firstMock.get2( 1, '1-1' );
        firstMock.get2( 2, '2-1' );
        firstMock.get2( 1, '3-1' );
        firstMock.get2( 1, '4-1' );
        firstMock.get2( 2, '5-1' );

        fflib_ArgumentCaptor argument = fflib_ArgumentCaptor.forClass( String.class );

        // Then - validate
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.atLeast( 2 ) ) )
            .get2( fflib_Match.eqInteger( 1 ), ( String ) argument.capture() );

        System.Assert.areEqual( '4-1', ( String ) argument.getValue(), 'the last value captured is not as expected' );
    }

    @IsTest
    private static void verifyTimesAndCaptor(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test
        firstMock.get2( 1, '1-1' );
        firstMock.get2( 2, '1-2' );
        firstMock.get2( 1, '2-1' );
        firstMock.get2( 2, '2-2' );
        firstMock.get2( 1, '3-1' );
        firstMock.get2( 2, '3-2' );
        firstMock.get2( 1, '4-1' );
        firstMock.get2( 2, '4-2' );
        firstMock.get2( 1, '5-1' );
        firstMock.get2( 2, '5-2' );

        fflib_ArgumentCaptor argument = fflib_ArgumentCaptor.forClass( String.class );

        // Then - validate
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.times( 5 ) ) )
            .get2( fflib_Match.eqInteger( 1 ), ( String ) argument.capture() );

        System.Assert.areEqual( '5-1', ( String ) argument.getValue(), 'the last value captured is not as expected' );
    }

    @IsTest
    private static void verifyCallsAndCapture(){
        // Create mocks
        fflib_MyList firstMock = ( fflib_MyList ) MY_MOCKS.mock( fflib_MyList.class );
        fflib_InOrder inOrder1 = new fflib_InOrder( MY_MOCKS, new List<Object>{ firstMock } );

        // When - perform test
        firstMock.get2( 1, '1-1' );
        firstMock.get2( 2, '1-2' );
        firstMock.get2( 1, '2-1' );
        firstMock.get2( 2, '2-2' );
        firstMock.get2( 1, '3-1' );
        firstMock.get2( 2, '3-2' );
        firstMock.get2( 1, '4-1' );
        firstMock.get2( 2, '4-2' );
        firstMock.get2( 1, '5-1' );
        firstMock.get2( 2, '5-2' );

        fflib_ArgumentCaptor argument = fflib_ArgumentCaptor.forClass( String.class );

        // Then - validate
        ( ( fflib_MyList.IList ) inOrder1.verify( firstMock, MY_MOCKS.calls( 2 ) ) )
            .get2( fflib_Match.eqInteger( 1 ), ( String ) argument.capture() );

        System.Assert.areEqual( '2-1', ( String ) argument.getValue(), 'the last value captured is not as expected' );
    }
}