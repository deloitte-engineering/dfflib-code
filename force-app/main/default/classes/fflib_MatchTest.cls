/**
 * Copyright (c), FinancialForce.com, inc
 * Copyright (c), Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
@IsTest( isParallel = true )
private with sharing class fflib_MatchTest{

    @IsTest
    private static void whenMatchesAllArgsWithOneMatchReturnsTrue(){
        // Given - create data
        fflib_MethodArgValues argValues = new fflib_MethodArgValues( new List<Object>{ null } );
        List<fflib_IMatcher> targetMatchers = new List<fflib_IMatcher>{ new AlwaysMatch() };

        // When - perform test
        Boolean match = fflib_Match.matchesAllArgs( argValues, targetMatchers );

        // Then - validate
        System.Assert.isTrue( match );
    }

    @IsTest
    private static void whenMatchesAllArgsWithManyMatchesReturnsTrue(){
        // Given - create data
        fflib_MethodArgValues argValues = new fflib_MethodArgValues( new List<Object>{
            null,
            null,
            null,
            null
        } );

        List<fflib_IMatcher> targetMatchers = new List<fflib_IMatcher>{
            new AlwaysMatch(),
            new AlwaysMatch(),
            new AlwaysMatch(),
            new AlwaysMatch()
        };

        // When - perform test
        Boolean match = fflib_Match.matchesAllArgs( argValues, targetMatchers );

        // Then - validate
        System.Assert.isTrue( match );
    }

    @IsTest
    private static void whenMatchesAllArgsWithOneMismatchReturnsFalse(){
        // Given - create data
        fflib_MethodArgValues argValues = new fflib_MethodArgValues( new List<Object>{ null } );
        List<fflib_IMatcher> targetMatchers = new List<fflib_IMatcher>{ new NeverMatch() };

        // When - perform test
        Boolean match = fflib_Match.matchesAllArgs( argValues, targetMatchers );

        // Then - validate
        System.Assert.isFalse( match );
    }

    @IsTest
    private static void whenMatchesAllArgsWithManyMismatchesReturnsFalse(){
        // Given - create data
        fflib_MethodArgValues argValues = new fflib_MethodArgValues( new List<Object>{
            null,
            null,
            null,
            null
        } );

        List<fflib_IMatcher> targetMatchers = new List<fflib_IMatcher>{
            new NeverMatch(),
            new NeverMatch(),
            new NeverMatch(),
            new NeverMatch()
        };

        // When - perform test
        Boolean match = fflib_Match.matchesAllArgs( argValues, targetMatchers );

        // Then - validate
        System.Assert.isFalse( match );
    }

    @IsTest
    private static void whenMatchesAllArgsWithMatchesAndMismatchesReturnsFalse(){
        // Given - create data
        fflib_MethodArgValues argValues = new fflib_MethodArgValues( new List<Object>{
            null,
            null,
            null,
            null
        } );

        List<fflib_IMatcher> targetMatchers = new List<fflib_IMatcher>{
            new AlwaysMatch(),
            new AlwaysMatch(),
            new NeverMatch(),
            new AlwaysMatch()
        };

        // When - perform test
        Boolean match = fflib_Match.matchesAllArgs( argValues, targetMatchers );

        // Then - validate
        System.Assert.isFalse( match );
    }

    @IsTest
    private static void whenMatchesAllArgsWithNullMethodArgsThrowsException(){
        // Given - create data
        fflib_MethodArgValues methodArg = null;
        List<fflib_IMatcher> targetMatchers = new List<fflib_IMatcher>{ new AlwaysMatch() };

        // When - perform test
        try{
            fflib_Match.matchesAllArgs( methodArg, targetMatchers );
            System.Assert.fail( 'Expected fflib_ApexMocks.ApexMocksException to be thrown. This assertion should never be triggered' );
        } catch( fflib_ApexMocks.ApexMocksException e ){
            // Then - validate
            System.Assert.areEqual( 'MethodArgs cannot be null', e.getMessage() );
        }
    }

    @IsTest
    private static void whenMatchesAllArgsWithNullMethodArgsArgValuesThrowsException(){
        // Given - create data
        fflib_MethodArgValues methodArg = new fflib_MethodArgValues( null );
        List<fflib_IMatcher> targetMatchers = new List<fflib_IMatcher>{ new AlwaysMatch() };

        // When - perform test
        try{
            fflib_Match.matchesAllArgs( methodArg, targetMatchers );
            System.Assert.fail( 'Expected fflib_ApexMocks.ApexMocksException to be thrown. This assertion should never be triggered' );
        } catch( fflib_ApexMocks.ApexMocksException e ){
            // Then - validate
            System.Assert.areEqual( 'MethodArgs.argValues cannot be null', e.getMessage() );
        }
    }

    @IsTest
    private static void whenMatchesAllArgsWithNullMatchersThrowsException(){
        // Given - create data
        fflib_MethodArgValues methodArg = new fflib_MethodArgValues( new List<Object>{ 'Test' } );
        List<fflib_IMatcher> targetMatchers = null;

        // When - perform test
        try{
            fflib_Match.matchesAllArgs( methodArg, targetMatchers );
            System.Assert.fail( 'Expected fflib_ApexMocks.ApexMocksException to be thrown. This assertion should never be triggered' );
        } catch( fflib_ApexMocks.ApexMocksException e ){
            // Then - validate
            System.Assert.areEqual( 'Matchers cannot be null', e.getMessage() );
        }
    }

    @IsTest
    private static void whenMatchesAllArgsWithDifferentSizeArgValuesAndMatchersThrowsException(){
        // Given - create data
        fflib_MethodArgValues methodArg = new fflib_MethodArgValues( new List<Object>{ 'Test' } );
        List<fflib_IMatcher> targetMatchers = new List<fflib_IMatcher>{ new AlwaysMatch(), new AlwaysMatch() };

        // When - perform test
        try{
            fflib_Match.matchesAllArgs( methodArg, targetMatchers );
            System.Assert.fail( 'Expected fflib_ApexMocks.ApexMocksException to be thrown. This assertion should never be triggered' );
        } catch( fflib_ApexMocks.ApexMocksException e ){
            // Then - validate
            String expectedMessage = 'MethodArgs and matchers must have the same count'
                + ', MethodArgs: (' + methodArg.argValues.size() + ') ' + methodArg.argValues
                + ', Matchers: (' + targetMatchers.size() + ') ' + targetMatchers;

            System.Assert.areEqual( expectedMessage, e.getMessage() );
        }
    }

    @IsTest
    private static void whenMatchesWithOneMatcherSetsMatchingToTrue(){
        // Given - create data
        fflib_IMatcher matcher = new AlwaysMatch();

        // When - perform test
        fflib_Match.matches( matcher );

        // Then - validate
        System.Assert.isTrue( fflib_Match.Matching );
    }

    @IsTest
    private static void whenMatchesWithOneMatcherRegistersMatcher(){
        // Given - create data
        fflib_IMatcher matcher = new AlwaysMatch();

        // When - perform test
        fflib_Match.matches( matcher );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );

        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isTrue( matcher === registeredMatchers[ 0 ] );
    }

    @IsTest
    private static void whenMatchesWithOneMatcherReturnsNull(){
        // Given - create data
        fflib_IMatcher matcher = new AlwaysMatch();

        // When - perform test
        Object retval = fflib_Match.matches( matcher );

        // Then - validate
        System.Assert.isNull( retval );
    }

    @IsTest
    private static void allOfWithNoArgsThrowsException(){
        // Given, When
        try{
            Object x = fflib_Match.allOf( ( List<Object> ) null );
            System.Assert.fail( 'Expected fflib_ApexMocks.ApexMocksException to be thrown. This assertion should never be triggered' );
        } catch( fflib_ApexMocks.ApexMocksException e ){
            // Then - validate
            System.Assert.areEqual( 'Must register matchers to combine', e.getMessage() );
        }
    }

    @IsTest
    private static void allOfWithEmptyArgsThrowsException(){
        // Given, When
        try{
            Object x = fflib_Match.allOf( new List<Object>{} );
            System.Assert.fail( 'Expected fflib_ApexMocks.ApexMocksException to be thrown. This assertion should never be triggered' );
        } catch( fflib_ApexMocks.ApexMocksException e ){
            // Then - validate
            System.Assert.areEqual( 'Must register matchers to combine', e.getMessage() );
        }
    }

    @IsTest
    private static void allOfWithoutRegisteringInnerMatchersThrowsException(){
        // Given, When
        try{
            //Should be using fflib_Match.allOf(new List<Object>{ fflib_Match.myMatcher('Hello') })
            //to register the inner matcher.
            Object x = fflib_Match.allOf( new List<Object>{ 'Hello' } );
            System.Assert.fail( 'Expected fflib_ApexMocks.ApexMocksException to be thrown. This assertion should never be triggered' );
        } catch( fflib_ApexMocks.ApexMocksException e ){
            // Then - validate
            String expectedMessage = 'Error reclaiming inner matchers for combined matcher. '
                + 'Wanted 1 matchers but only got ' + new List<fflib_IMatcher>();
            System.Assert.areEqual( expectedMessage, e.getMessage() );
        }
    }

    @IsTest
    private static void allOfWith2ArgsRegistersCorrectMatcherType(){
        // Given, When
        Object x = fflib_Match.allOf( fflib_Match.eq( 'hello1' ), fflib_Match.eq( 'hello2' ) );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.Combined.class );
    }

    @IsTest
    private static void allOfWith3ArgsRegistersCorrectMatcherType(){
        // Given, When
        Object x = fflib_Match.allOf( fflib_Match.eq( 'hello1' ), fflib_Match.eq( 'hello2' ), fflib_Match.eq( 'hello3' ) );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.Combined.class );
    }

    @IsTest
    private static void allOfWith4ArgsRegistersCorrectMatcherType(){
        // Given, When
        Object x = fflib_Match.allOf( fflib_Match.eq( 'hello1' ), fflib_Match.eq( 'hello2' ), fflib_Match.eq( 'hello3' ), fflib_Match.eq( 'hello4' ) );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.Combined.class );
    }

    @IsTest
    private static void allOfWithListArgsRegistersCorrectMatcherType(){
        // Given, When
        Object x = fflib_Match.allOf( new List<Object>{ fflib_Match.eq( 'hello' ) } );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.Combined.class );
    }

    @IsTest
    private static void anyOfWith2ArgsRegistersCorrectMatcherType(){
        // Given, When
        Object x = fflib_Match.anyOf( fflib_Match.eq( 'hello1' ), fflib_Match.eq( 'hello2' ) );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.Combined.class );
    }

    @IsTest
    private static void anyOfWith3ArgsRegistersCorrectMatcherType(){
        // Given, When
        Object x = fflib_Match.anyOf( fflib_Match.eq( 'hello1' ), fflib_Match.eq( 'hello2' ), fflib_Match.eq( 'hello3' ) );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.Combined.class );
    }

    @IsTest
    private static void anyOfWith4ArgsRegistersCorrectMatcherType(){
        // Given, When
        Object x = fflib_Match.anyOf( fflib_Match.eq( 'hello1' ), fflib_Match.eq( 'hello2' ), fflib_Match.eq( 'hello3' ), fflib_Match.eq( 'hello4' ) );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.Combined.class );
    }

    @IsTest
    private static void anyOfWithListArgsRegistersCorrectMatcherType(){
        // Given, When
        Object x = fflib_Match.anyOf( new List<Object>{ fflib_Match.eq( 'hello' ) } );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.Combined.class );
    }

    @IsTest
    private static void isNotRegistersCorrectMatcherType(){
        // Given, When
        Object x = fflib_Match.isNot( fflib_Match.eq( 'hello1' ) );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.Combined.class );
    }

    @IsTest
    private static void noneOfWith2ArgsRegistersCorrectMatcherType(){
        // Given, When
        Object x = fflib_Match.noneOf( fflib_Match.eq( 'hello1' ), fflib_Match.eq( 'hello2' ) );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.Combined.class );
    }

    @IsTest
    private static void noneOfWith3ArgsRegistersCorrectMatcherType(){
        // Given, When
        Object x = fflib_Match.noneOf( fflib_Match.eq( 'hello1' ), fflib_Match.eq( 'hello2' ), fflib_Match.eq( 'hello3' ) );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.Combined.class );
    }

    @IsTest
    private static void noneOfWith4ArgsRegistersCorrectMatcherType(){
        // Given, When
        Object x = fflib_Match.noneOf( fflib_Match.eq( 'hello1' ), fflib_Match.eq( 'hello2' ), fflib_Match.eq( 'hello3' ), fflib_Match.eq( 'hello4' ) );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.Combined.class );
    }

    @IsTest
    private static void noneOfWithListArgsRegistersCorrectMatcherType(){
        // Given, When
        Object x = fflib_Match.noneOf( new List<Object>{ fflib_Match.eq( 'hello' ) } );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.Combined.class );
    }

    @IsTest
    private static void eqRegistersCorrectMatcherType(){
        // Given, When
        Object x = fflib_Match.eq( 'hello' );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.Eq.class );
    }

    @IsTest
    private static void eqBooleanRegistersCorrectMatcherType(){
        // Given, When
        Object x = fflib_Match.eqBoolean( true );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.Eq.class );
    }

    @IsTest
    private static void eqDateRegistersCorrectMatcherType(){
        // Given, When
        Object x = fflib_Match.eqDate( Date.today() );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.Eq.class );
    }

    @IsTest
    private static void eqDatetimeRegistersCorrectMatcherType(){
        // Given, When
        Object x = fflib_Match.eqDatetime( System.now() );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.Eq.class );
    }

    @IsTest
    private static void eqDecimalRegistersCorrectMatcherType(){
        // Given, When
        Object x = fflib_Match.eqDecimal( 123 );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.Eq.class );
    }

    @IsTest
    private static void eqDoubleRegistersCorrectMatcherType(){
        // Given, When
        Object x = fflib_Match.eqDouble( 123 );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.Eq.class );
    }

    @IsTest
    private static void eqIdRegistersCorrectMatcherType(){
        // Given, When
        Object x = fflib_Match.eqId( fflib_IDGenerator.generate( Account.SObjectType ) );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.Eq.class );
    }

    @IsTest
    private static void eqIntegerRegistersCorrectMatcherType(){
        // Given, When
        Object x = fflib_Match.eqInteger( 123 );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.Eq.class );
    }

    @IsTest
    private static void eqListRegistersCorrectMatcherType(){
        // Given, When
        Object x = fflib_Match.eqList( new List<String>{ 'hello' } );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.Eq.class );
    }

    @IsTest
    private static void eqLongRegistersCorrectMatcherType(){
        // Given, When
        Object x = fflib_Match.eqLong( 123 );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.Eq.class );
    }

    @IsTest
    private static void eqSObjectFieldRegistersCorrectMatcherType(){
        // Given, When
        Schema.SObjectField f = Schema.getGlobalDescribe().get( 'Account' ).getDescribe().fields.getMap().get( 'Id' );
        Object x = fflib_Match.eqSObjectField( f );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.Eq.class );
    }

    @IsTest
    private static void eqSObjectTypeRegistersCorrectMatcherType(){
        // Given, When
        Schema.SObjectType ot = Schema.getGlobalDescribe().get( 'Account' );
        Object x = fflib_Match.eqSObjectType( ot );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.Eq.class );
    }

    @IsTest
    private static void eqStringRegistersCorrectMatcherType(){
        // Given, When
        Object x = fflib_Match.eqString( 'hello' );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.Eq.class );
    }

    @IsTest
    private static void refEqRegistersCorrectMatcherType(){
        // Given, When
        Object x = fflib_Match.refEq( 'hello' );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.RefEq.class );
    }

    @IsTest
    private static void anyBooleanRegistersCorrectMatcherType(){
        // Given, When
        Boolean x = fflib_Match.anyBoolean();

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.AnyBoolean.class );
    }

    @IsTest
    private static void anyDateRegistersCorrectMatcherType(){
        // Given, When
        Date x = fflib_Match.anyDate();

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.AnyDate.class );
    }

    @IsTest
    private static void anyDatetimeRegistersCorrectMatcherType(){
        // Given, When
        Datetime x = fflib_Match.anyDatetime();

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.AnyDatetime.class );
    }

    @IsTest
    private static void anyDecimalRegistersCorrectMatcherType(){
        // Given, When
        Decimal x = fflib_Match.anyDecimal();

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.AnyDecimal.class );
    }

    @IsTest
    private static void anyDoubleRegistersCorrectMatcherType(){
        // Given, When
        Double x = fflib_Match.anyDouble();

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.AnyDouble.class );
    }

    @IsTest
    private static void anyFieldSetRegistersCorrectMatcherType(){
        // Given, When
        Schema.FieldSet x = fflib_Match.anyFieldSet();

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.AnyFieldSet.class );
    }

    @IsTest
    private static void anyIdRegistersCorrectMatcherType(){
        // Given, When
        Id x = fflib_Match.anyId();

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.AnyId.class );
    }

    @IsTest
    private static void anyIntegerRegistersCorrectMatcherType(){
        // Given, When
        Integer x = fflib_Match.anyInteger();

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.AnyInteger.class );
    }

    @IsTest
    private static void anyListRegistersCorrectMatcherType(){
        // Given, When
        List<Object> x = fflib_Match.anyList();

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.AnyList.class );
    }

    @IsTest
    private static void anyLongRegistersCorrectMatcherType(){
        // Given, When
        Long x = fflib_Match.anyLong();

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.AnyLong.class );
    }

    @IsTest
    private static void anyObjectRegistersCorrectMatcherType(){
        // Given, When
        Object x = fflib_Match.anyObject();

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.AnyObject.class );
    }

    @IsTest
    private static void anyStringRegistersCorrectMatcherType(){
        // Given, When
        String x = fflib_Match.anyString();

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.AnyString.class );
    }

    @IsTest
    private static void anySObjectRegistersCorrectMatcherType(){
        // Given, When
        SObject x = fflib_Match.anySObject();

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.AnySObject.class );
    }

    @IsTest
    private static void anySObjectFieldRegistersCorrectMatcherType(){
        // Given, When
        SObjectField x = fflib_Match.anySObjectField();

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.AnySObjectField.class );
    }

    @IsTest
    private static void anySObjectTypeRegistersCorrectMatcherType(){
        // Given, When
        SObjectType x = fflib_Match.anySObjectType();

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.AnySObjectType.class );
    }

    @IsTest
    private static void dateAfterRegistersCorrectMatcherType(){
        // Given, When
        Date x = fflib_Match.dateAfter( Date.today() );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.DatetimeAfter.class );
    }

    @IsTest
    private static void dateBeforeRegistersCorrectMatcherType(){
        // Given, When
        Date x = fflib_Match.dateBefore( Date.today() );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.DatetimeBefore.class );
    }

    @IsTest
    private static void dateBetweenRegistersCorrectMatcherType(){
        // Given, When
        Date x = fflib_Match.dateBetween( Date.today(), Date.today() );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.DatetimeBetween.class );
    }

    @IsTest
    private static void datetimeAfterRegistersCorrectMatcherType(){
        // Given, When
        Datetime x = fflib_Match.datetimeAfter( System.now() );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.DatetimeAfter.class );
    }

    @IsTest
    private static void datetimeBeforeRegistersCorrectMatcherType(){
        // Given, When
        Datetime x = fflib_Match.datetimeBefore( System.now() );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.DatetimeBefore.class );
    }

    @IsTest
    private static void datetimeBetweenRegistersCorrectMatcherType(){
        // Given, When
        Datetime x = fflib_Match.datetimeBetween( System.now(), System.now() );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.DatetimeBetween.class );
    }

    @IsTest
    private static void decimalBetweenRegistersCorrectMatcherType(){
        // Given, When
        Decimal x = fflib_Match.decimalBetween( 0, 10 );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.DecimalBetween.class );
    }

    @IsTest
    private static void decimalLessThanRegistersCorrectMatcherType(){
        // Given, When
        Decimal x = fflib_Match.decimalLessThan( 0 );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.DecimalLessThan.class );
    }

    @IsTest
    private static void decimalMoreThanRegistersCorrectMatcherType(){
        // Given, When
        Decimal x = fflib_Match.decimalMoreThan( 0 );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.DecimalMoreThan.class );
    }

    @IsTest
    private static void doubleBetweenRegistersCorrectMatcherType(){
        // Given, When
        Double x = fflib_Match.doubleBetween( 0, 10 );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.DecimalBetween.class );
    }

    @IsTest
    private static void doubleLessThanRegistersCorrectMatcherType(){
        // Given, When
        Double x = fflib_Match.doubleLessThan( 0 );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.DecimalLessThan.class );
    }

    @IsTest
    private static void doubleMoreThanRegistersCorrectMatcherType(){
        // Given, When
        Double x = fflib_Match.doubleMoreThan( 0 );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.DecimalMoreThan.class );
    }

    @IsTest
    private static void fieldSetEquivalentWithNullFieldSetThrowsException(){
        try{
            fflib_Match.fieldSetEquivalentTo( null );
            System.Assert.fail( 'Expected fflib_ApexMocks.ApexMocksException to be thrown. This assertion should never be triggered' );
        } catch( fflib_ApexMocks.ApexMocksException e ){
            System.Assert.areEqual( 'Arg cannot be null: null', e.getMessage() );
        }
    }

    @IsTest
    private static void fieldSetEquivalentToRegistersCorrectMatcherType(){
        Schema.FieldSet anyFieldSet = fflib_ApexMocksUtilsTest.findAnyFieldSet();
        if( anyFieldSet == null ){
            return;
        }

        // Given, When
        Schema.FieldSet x = fflib_Match.fieldSetEquivalentTo( anyFieldSet );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.FieldSetEquivalentTo.class );
    }

    @IsTest
    private static void integerBetweenRegistersCorrectMatcherType(){
        // Given, When
        Integer x = fflib_Match.integerBetween( 0, 10 );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.DecimalBetween.class );
    }

    @IsTest
    private static void integerLessThanRegistersCorrectMatcherType(){
        // Given, When
        Integer x = fflib_Match.integerLessThan( 0 );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.DecimalLessThan.class );
    }

    @IsTest
    private static void integerMoreThanRegistersCorrectMatcherType(){
        // Given, When
        Integer x = fflib_Match.integerMoreThan( 0 );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.DecimalMoreThan.class );
    }

    @IsTest
    private static void isNotNullRegistersCorrectMatcherType(){
        // Given, When
        Object x = fflib_Match.isNotNull();

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.IsNotNull.class );
    }

    @IsTest
    private static void isNullRegistersCorrectMatcherType(){
        // Given, When
        Object x = fflib_Match.isNull();

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.IsNull.class );
    }

    @IsTest
    private static void listContainsRegistersCorrectMatcherType(){
        // Given, When
        Object x = fflib_Match.listContains( 'fred' );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.ListContains.class );
    }

    @IsTest
    private static void listIsEmptyRegistersCorrectMatcherType(){
        // Given, When
        Object x = fflib_Match.listIsEmpty();

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.ListIsEmpty.class );
    }

    @IsTest
    private static void longBetweenRegistersCorrectMatcherType(){
        // Given, When
        Long x = fflib_Match.longBetween( 0, 10 );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.DecimalBetween.class );
    }

    @IsTest
    private static void longLessThanRegistersCorrectMatcherType(){
        // Given, When
        Long x = fflib_Match.longLessThan( 0 );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.DecimalLessThan.class );
    }

    @IsTest
    private static void longMoreThanRegistersCorrectMatcherType(){
        // Given, When
        Long x = fflib_Match.longMoreThan( 0 );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.DecimalMoreThan.class );
    }

    @IsTest
    private static void sObjectOfTypeRegistersCorrectMatcherType(){
        // Given - create data
        Schema.SObjectType ot = Schema.getGlobalDescribe().get( 'Account' );
        if( ot == null ){
            return;
        }

        // When - perform test
        SObject x = fflib_Match.sObjectOfType( ot );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.SObjectOfType.class );
    }

    @IsTest
    private static void sObjectWithRegistersCorrectMatcherType(){
        // Given - create data
        Schema.SObjectType ot = Schema.getGlobalDescribe().get( 'Account' );
        if( ot == null ){
            return;
        }

        Schema.SObjectField f = ot.getDescribe().fields.getMap().get( 'Id' );

        // When - perform test
        SObject x = fflib_Match.sObjectWith( new Map<Schema.SObjectField, Object>{ f => null } );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.SObjectWith.class );
    }

    @IsTest
    private static void sObjectsWithRegistersCorrectMatcherType(){
        // Given - create data
        Schema.SObjectType ot = Schema.getGlobalDescribe().get( 'Account' );
        if( ot == null ){
            return;
        }

        Schema.SObjectField f = ot.getDescribe().fields.getMap().get( 'Id' );

        // When - perform test
        SObject[] x = fflib_Match.sObjectsWith( new List<Map<Schema.SObjectField, Object>>{
            new Map<Schema.SObjectField, Object>{ f => null }
        } );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.SObjectsWith.class );
    }

    @IsTest
    private static void sObjectsWithMatchInOrderRegistersCorrectMatcherType(){
        // Given - create data
        Schema.SObjectType ot = Schema.getGlobalDescribe().get( 'Account' );
        if( ot == null ){
            return;
        }

        Schema.SObjectField f = ot.getDescribe().fields.getMap().get( 'Id' );

        // When - perform test
        SObject[] x = fflib_Match.sObjectsWith( new List<Map<Schema.SObjectField, Object>>{
            new Map<Schema.SObjectField, Object>{ f => null }
        }, false );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.SObjectsWith.class );
    }

    @IsTest
    private static void sObjectWithIdRegistersCorrectMatcherType(){
        // Given, When
        SObject x = fflib_Match.sObjectWithId( fflib_IDGenerator.generate( Account.SObjectType ) );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.SObjectWithId.class );
    }

    @IsTest
    private static void sObjectWithNameRegistersCorrectMatcherType(){
        // Given, When
        SObject x = fflib_Match.sObjectWithName( 'hello' );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.SObjectWithName.class );
    }

    @IsTest
    private static void stringContainsRegistersCorrectMatcherType(){
        // Given, When
        String x = fflib_Match.stringContains( 'hello' );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.StringContains.class );
    }

    @IsTest
    private static void stringEndsWithRegistersCorrectMatcherType(){
        // Given, When
        String x = fflib_Match.stringEndsWith( 'hello' );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.StringEndsWith.class );
    }

    @IsTest
    private static void stringIsBlankRegistersCorrectMatcherType(){
        // Given, When
        String x = fflib_Match.stringIsBlank();

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.StringIsBlank.class );
    }

    @IsTest
    private static void stringIsNotBlankRegistersCorrectMatcherType(){
        // Given, When
        String x = fflib_Match.stringIsNotBlank();

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.StringIsNotBlank.class );
    }

    @IsTest
    private static void stringMatchesRegistersCorrectMatcherType(){
        // Given, When
        String x = fflib_Match.stringMatches( '[a-z]*' );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.StringMatches.class );
    }

    @IsTest
    private static void stringStartsWithRegistersCorrectMatcherType(){
        // Given, When
        String x = fflib_Match.stringStartsWith( 'hello' );

        // Then - validate
        List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 1 );
        System.Assert.isNotNull( registeredMatchers );
        System.Assert.areEqual( 1, registeredMatchers.size() );
        System.Assert.isInstanceOfType( registeredMatchers[ 0 ], fflib_MatcherDefinitions.StringStartsWith.class );
    }

    @IsTest
    private static void getAndClearMatchers_shouldThrowExceptionWhenMatcherCountMismatches(){
        // Given, When
        Object x = fflib_Match.anyObject();

        // Then - validate
        try{
            List<fflib_IMatcher> registeredMatchers = fflib_Match.getAndClearMatchers( 0 );
            System.Assert.fail( 'This Exception should never been thrown' );
        } catch( fflib_ApexMocks.ApexMocksException mockExcept ){
            String expectedMessage = 'The number of matchers defined (' + 1 + ') does not match the number expected (' + 0 + ').\n'
                + 'If you are using matchers all arguments must be passed in as matchers.\n'
                + 'For example myList.add(fflib_Match.anyInteger(), \'String\') should be defined as myList.add(fflib_Match.anyInteger(), fflib_Match.eq(\'String\')).';
            System.Assert.areEqual( expectedMessage, mockExcept.getMessage(), ' the error message is not as expected' );
        }
    }

    private class AlwaysMatch implements fflib_IMatcher{
        public Boolean matches( Object arg ){
            return true;
        }
    }

    private class NeverMatch implements fflib_IMatcher{
        public Boolean matches( Object arg ){
            return false;
        }
    }
}
