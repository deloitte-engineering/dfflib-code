/**
 * Copyright (c), Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
/**
 * Allows aggregate results to be used to mock when testing
 *
 * @created     March 2019
 */
public with sharing class fflib_AggregateResult {

    private AggregateResult result;

    public fflib_AggregateResult(){
        // No body
    }

    private fflib_AggregateResult( AggregateResult result ){
        this.result = result;
    }

    public Object get( String field ){
        return result.get( field );
    }

    public static List<fflib_AggregateResult> construct( List<AggregateResult> results ){
        List<fflib_AggregateResult> aggResults = new List<fflib_AggregateResult>();

        for( Integer i = 0, j = results.size(); i < j; i++ ){
            aggResults.add( new fflib_AggregateResult( results[ i ] ) );
        }

        return aggResults;
    }

}
