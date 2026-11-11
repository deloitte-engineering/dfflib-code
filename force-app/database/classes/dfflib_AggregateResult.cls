/**
 * Copyright (c) 2019, Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
/**
 * Allows aggregate results to be used to mock when testing
 */
public with sharing class dfflib_AggregateResult {

    private AggregateResult result;

    public dfflib_AggregateResult(){
        // No body
    }

    private dfflib_AggregateResult( AggregateResult result ){
        this.result = result;
    }

    public Object get( String field ){
        return result.get( field );
    }

    public static List<dfflib_AggregateResult> construct( List<AggregateResult> results ){
        List<dfflib_AggregateResult> aggResults = new List<dfflib_AggregateResult>();

        for( Integer i = 0, j = results.size(); i < j; i++ ){
            aggResults.add( new dfflib_AggregateResult( results[ i ] ) );
        }

        return aggResults;
    }

}