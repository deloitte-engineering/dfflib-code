/**
 * Copyright (c) 2019, Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
/**
 * Test class for dfflib_AggregateResult class.
 */
@IsTest( isParallel = true )
public with sharing class dfflib_AggregateResultTest{

    private class TestAggregate{}

    @IsTest
    private static void shouldConstructAggregateResult(){
        // Given
        List<TestAggregate> aggregateData = new List<TestAggregate>{
            new TestAggregate(),
            new TestAggregate()
        };

        List<AggregateResult> aggregates = ( List<AggregateResult> ) JSON.deserialize(
            JSON.serialize( aggregateData ),
            List<AggregateResult>.class
        );

        // When
        List<dfflib_AggregateResult> result = dfflib_AggregateResult.construct( aggregates );

        // Then
        System.Assert.areEqual( 2, result.size() );
    }

    @IsTest
    private static void shouldGetData(){
        List<TestAggregate> aggregateData = new List<TestAggregate>{
            new TestAggregate()
        };

        List<AggregateResult> aggregates = ( List<AggregateResult> ) JSON.deserialize(
            JSON.serialize( aggregateData ),
            List<AggregateResult>.class
        );

        try{
            // When
            List<dfflib_AggregateResult> result = dfflib_AggregateResult.construct( aggregates );
            result.get( 0 ).get( 'something' );
        } catch( SObjectException ex ){
            // Then
            System.Assert.areEqual( 'Invalid field something for AggregateResult', ex.getMessage() );
        }
    }

    @IsTest
    private static void testConstructor(){
        //Calling constructor for code coverage
        dfflib_AggregateResult agg = new dfflib_AggregateResult();
    }
}