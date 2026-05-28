/**
 * Copyright (c), FinancialForce.com, inc
 * Copyright (c) 2025, Deloitte NL
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
 * - Neither the name of the FinancialForce.com, inc nor the names of its contributors 
 *      may be used to endorse or promote products derived from this software without 
 *      specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
 *  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
 *  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL 
 *  THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 *  OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 *  OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

public interface fflib_ISObjectSelector{

    /**
     * Provides the SObjectType for the object the given Selector is providing query logic for.
     *
     * @return	Schema.SObjectType definition of the given selector
     */
    Schema.SObjectType sObjectType();

    /**
     * Selects by Id records using the fields defined by the Selector configuration
     *
     * @param 	idSet   Set of ids
     * @return	A list of SObject's.
     */
    List<SObject> selectSObjectsById( Set<Id> idSet );

    /**
     * Method for selecting records for deletion
     *
     * @param 	queryConditionString	The query criteria (F.e. Origin = 'Phone')
     * @return  List of records for deletion.
     */
    Database.QueryLocator selectDeleteBatchRecords( String queryConditionString );

    /**
     * Method for querying and retrieving all SObject records associated with the relevant SObjectType in context
     *
     * @return	List of SObject records.
     */
    List<SObject> selectAllSObjectRecords();

    /**
     * Setter to allow changing the database security context when querying for records
     * Default is set to FULL, applying the sharing of the calling class and user-context CRUD/FLS checks
     *
     * @param   securityContext     Database security context of this instance
     * @return  Returns this instance
     */
    fflib_SObjectSelector setContext( fflib_Database.Context securityContext );

    /**
     * Relay-methods to the query proxy. These methods have the sole responsibility to pass down the query expression and binding map to the query proxy implementation.
     * In addition, it allows one to inject stubs for mocking actual database operations and verify the contents of the input parameters above
     */
    // Database.query() specifications
    List<SObject> executeQuery( String query );
    List<SObject> executeQuery( fflib_QueryFactory qf );
    List<SObject> executeQuery( String query, Map<String, Object> bindVariablesMap );
    List<SObject> executeQuery( fflib_QueryFactory qf, Map<String, Object> bindVariablesMap );

    // Database.query() for Grouped By Results returning AggregateResults
    List<fflib_AggregateResult> executeAggregateQuery( String query );
    List<fflib_AggregateResult> executeAggregateQuery( fflib_QueryFactory qf );
    List<fflib_AggregateResult> executeAggregateQuery( String query, Map<String, Object> bindVariablesMap );
    List<fflib_AggregateResult> executeAggregateQuery( fflib_QueryFactory qf, Map<String, Object> bindVariablesMap );

    // Database.getQueryLocator() specifications
    Database.QueryLocator getQueryLocator( String query );
    Database.QueryLocator getQueryLocator( fflib_QueryFactory qf );
    Database.QueryLocator getQueryLocator( String query, Map<String, Object> bindVariablesMap );
    Database.QueryLocator getQueryLocator( fflib_QueryFactory qf, Map<String, Object> bindVariablesMap );
}