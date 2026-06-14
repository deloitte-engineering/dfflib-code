/**
 * Class that defines an interface to the query proxy servicing selector-layer classes to be compatible with apex-mock framework
 *
 *  @created    February 2023
 */
public interface fflib_Database_IQuery{
    /**
     * Method definition relaying a formatted string representing a query expression to the query proxy implementation of Database.query(), with an optional specified AccessLevel
     * NOTE: Only to be used when there are no dynamic conditions applied, else it's recommended to provide a bindVariablesMap
     *
     * @param   query           Formatted string representing a query expression, without any bind variables
     * @param   accessLevel     AccessLevel to set context mode
     * @return  List<SObject> result of executing the query expression as input
     */
    List<Object> query( String query, AccessLevel accessLevel );

    /**
     * Method definition relaying a formatted string representing a query expression to the query proxy implementation of Database.queryWithBinds(), mapping of binding variables and an optional AccessLevel
     *
     * @param   query               Formatted string representing a query expression
     * @param   bindVariablesMap    Map of literals to the corresponding binding objects
     * @param   accessLevel         AccessLevel to set context mode
     * @return  List<SObject> result of executing the query expression, with the binding mapping as input
     */
    List<Object> query( String query, Map<String, Object> bindVariablesMap, AccessLevel accessLevel );

    /**
     * Method definition relaying a formatted string representing a query expression to the query proxy implementation of Database.getQueryLocator(), with an optional specified AccessLevel
     * NOTE: Only to be used when there are no dynamic conditions applied, else it's recommended to provide a bindVariablesMap
     *
     * @param   query           Formatted string representing a query expression
     * @param   accessLevel     AccessLevel to set context mode
     * @return  Database.QueryLocator object result to be used in batch Apex or Visualforce
     */
    Database.QueryLocator getQueryLocator( String query, AccessLevel accessLevel );

    /**
     * Method definition relaying a formatted string representing a query expression to the query proxy implementation of Database.getQueryLocatorWithBinds(), mapping of binding variables and an optional AccessLevel
     *
     * @param   query               Formatted string representing a query expression
     * @param   bindVariablesMap    Map of literals to the corresponding binding objects
     * @param   accessLevel         AccessLevel to set context mode
     * @return  Database.QueryLocator object result to be used in batch Apex or Visualforce, with the binding mapping as input
     */
    Database.QueryLocator getQueryLocator( String query, Map<String, Object> bindVariablesMap, AccessLevel accessLevel );

    /**
     * Relays a SOQL query string to Database.getCursor() for incremental processing of large result sets across Queueable chains.
     * NOTE: Only to be used when there are no dynamic conditions applied, else it's recommended to provide a bindVariablesMap.
     *
     * @param   query           Formatted SOQL string without bind variables
     * @param   accessLevel     AccessLevel to set context mode
     * @return  Database.Cursor for stateless incremental record fetching
     */
    Database.Cursor getCursor( String query, AccessLevel accessLevel );

    /**
     * Relays a SOQL query string with bind variables to Database.getCursorWithBinds() for incremental processing of large result sets across Queueable chains.
     *
     * @param   query               Formatted SOQL string with bind variable placeholders
     * @param   bindVariablesMap    Map of bind variable names to values
     * @param   accessLevel         AccessLevel to set context mode
     * @return  Database.Cursor for stateless incremental record fetching
     */
    Database.Cursor getCursor( String query, Map<String, Object> bindVariablesMap, AccessLevel accessLevel );

    /**
     * Relays a SOQL query string to Database.getPaginationCursor() for UI-based pagination. Unlike standard cursors,
     * fetchPage() skips deleted records to ensure consistent page sizes (max 100K rows per instance).
     * NOTE: Only to be used when there are no dynamic conditions applied, else it's recommended to provide a bindVariablesMap.
     *
     * @param   query           Formatted SOQL string without bind variables
     * @param   accessLevel     AccessLevel to set context mode
     * @return  Database.PaginationCursor for page-based record fetching
     */
    Database.PaginationCursor getPaginationCursor( String query, AccessLevel accessLevel );

    /**
     * Relays a SOQL query string with bind variables to Database.getPaginationCursorWithBinds() for UI-based pagination.
     * Unlike standard cursors, fetchPage() skips deleted records to ensure consistent page sizes (max 100K rows per instance).
     *
     * @param   query               Formatted SOQL string with bind variable placeholders
     * @param   bindVariablesMap    Map of bind variable names to values
     * @param   accessLevel         AccessLevel to set context mode
     * @return  Database.PaginationCursor for page-based record fetching
     */
    Database.PaginationCursor getPaginationCursor( String query, Map<String, Object> bindVariablesMap, AccessLevel accessLevel );
}