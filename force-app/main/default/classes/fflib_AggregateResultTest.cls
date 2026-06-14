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
/**
 * Test class for fflib_AggregateResult class.
 *
 * @created     March 2019
 */
@IsTest( isParallel = true )
public with sharing class fflib_AggregateResultTest{

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
        List<fflib_AggregateResult> result = fflib_AggregateResult.construct( aggregates );

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
            List<fflib_AggregateResult> result = fflib_AggregateResult.construct( aggregates );
            result.get( 0 ).get( 'something' );
        } catch( SObjectException ex ){
            // Then
            System.Assert.areEqual( 'Invalid field something for AggregateResult', ex.getMessage() );
        }
    }

    @IsTest
    private static void testConstructor(){
        //Calling constructor for code coverage
        fflib_AggregateResult agg = new fflib_AggregateResult();
    }
}