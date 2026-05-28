/**
 * Class that defines an interface to the query proxy servicing selector-layer classes to be compatible with apex-mock framework
 *
 *  @author     Rafael Fernandes dos Santos (rfernandesdossantos@deloitte.nl)
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
}