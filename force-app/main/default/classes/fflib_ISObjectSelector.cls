/**
 * Copyright (c), FinancialForce.com, inc
 * Copyright (c) 2019, Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */

@NamespaceAccessible
public interface fflib_ISObjectSelector{

    /**
     * Provides the SObjectType for the object the given Selector is providing query logic for.
     *
     * @return    Schema.SObjectType definition of the given selector
     */
    Schema.SObjectType sObjectType();

    /**
     * Selects by Id records using the fields defined by the Selector configuration
     *
     * @param     idSet   Set of ids
     * @return    A list of SObject's.
     */
    List<SObject> selectSObjectsById( Set<Id> idSet );

    /**
     * Method for selecting records for deletion
     *
     * @param     queryConditionString    The query criteria (F.e. Origin = 'Phone')
     * @return  List of records for deletion.
     */
    Database.QueryLocator selectDeleteBatchRecords( String queryConditionString );

    /**
     * Method for querying and retrieving all SObject records associated with the relevant SObjectType in context
     *
     * @return    List of SObject records.
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
