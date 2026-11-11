/**
 * Copyright (c) 2019, Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
/**
 * Centralised class to group all Database query operations:
 * 1) Allowing to easily apply different database security models, through sharing modes and access levels (AccessLevel)
 * 2) Allowing optimal separation of concerns where QueryFactory focuses on construction and dfflib_Database_QueryProxy on database retrieval
 *      This allows to simplify Test methods, and make the framework more environment-independent (test-classes not failing on added validations)
 *      Lastly, this enables unlocked packages where framework code is not needed to be touched by project developers
 */
public abstract class dfflib_Database_QueryProxy{

    /**
     * Getter providing a DMLProxy implementation for the security enforcement model provided
     *
     * @param   securityContext     Database security context for queries to be executed on
     * @return  QueryProxy implementation for the security context provided
     */
    public static dfflib_Database_IQuery getQueryProxyImplementation( dfflib_Database.Context securityContext ){
        return SECURITY_ENFORCEMENT_QUERY.get( securityContext );
    }

    /**
     * Database context models supported mapped to the respective interface implementations.
     */
    private final static Map<dfflib_Database.Context, dfflib_Database_IQuery> SECURITY_ENFORCEMENT_QUERY = new Map<dfflib_Database.Context, dfflib_Database_IQuery>{
        dfflib_Database.Context.FULL => new QueryWithSharing(),
        dfflib_Database.Context.SHARING_SKIP_PERMISSIONS => new QueryWithSharing(),
        dfflib_Database.Context.NONE => new QueryWithoutSharing(),
        dfflib_Database.Context.INHERIT => new QueryInheritedSharing()
    };

    /**
     * Class implementation of the QueryProxy that enforces sharing rules (aka "with sharing").
     * All QueryProxy implementations have public methods to be able to be accessed outside of this class without being able to instantiate the implementations
     */
    @TestVisible
    private with sharing class QueryWithSharing implements dfflib_Database_IQuery{
        public List<Object> query( String query, AccessLevel accessLevel ){
            return Database.query( query, accessLevel );
        }
        public List<Object> query( String query, Map<String, Object> bindVariablesMap, AccessLevel accessLevel ){
            return Database.queryWithBinds( query, bindVariablesMap, accessLevel );
        }
        public Database.QueryLocator getQueryLocator( String query, AccessLevel accessLevel ){
            return Database.getQueryLocator( query, accessLevel );
        }
        public Database.QueryLocator getQueryLocator( String query, Map<String, Object> bindVariablesMap, AccessLevel accessLevel ){
            return Database.getQueryLocatorWithBinds( query, bindVariablesMap, accessLevel );
        }
        public Database.Cursor getCursor( String query, AccessLevel accessLevel ){
            return Database.getCursor( query, accessLevel );
        }
        public Database.Cursor getCursor( String query, Map<String, Object> bindVariablesMap, AccessLevel accessLevel ){
            return Database.getCursorWithBinds( query, bindVariablesMap, accessLevel );
        }
        public Database.PaginationCursor getPaginationCursor( String query, AccessLevel accessLevel ){
            return Database.getPaginationCursor( query, accessLevel );
        }
        public Database.PaginationCursor getPaginationCursor( String query, Map<String, Object> bindVariablesMap, AccessLevel accessLevel ){
            return Database.getPaginationCursorWithBinds( query, bindVariablesMap, accessLevel );
        }
    }

    /**
     * Class implementation of the QueryProxy that does NOT enforce sharing rules (aka "without sharing").
     * All QueryProxy implementations have public methods to be able to be accessed outside of this class without being able to instantiate the implementations
     */
    @TestVisible
    private without sharing class QueryWithoutSharing implements dfflib_Database_IQuery{
        public List<Object> query( String query, AccessLevel accessLevel ){
            return Database.query( query, accessLevel );
        }
        public List<Object> query( String query, Map<String, Object> bindVariablesMap, AccessLevel accessLevel ){
            return Database.queryWithBinds( query, bindVariablesMap, accessLevel );
        }
        public Database.QueryLocator getQueryLocator( String query, AccessLevel accessLevel ){
            return Database.getQueryLocator( query, accessLevel );
        }
        public Database.QueryLocator getQueryLocator( String query, Map<String, Object> bindVariablesMap, AccessLevel accessLevel ){
            return Database.getQueryLocatorWithBinds( query, bindVariablesMap, accessLevel );
        }
        public Database.Cursor getCursor( String query, AccessLevel accessLevel ){
            return Database.getCursor( query, accessLevel );
        }
        public Database.Cursor getCursor( String query, Map<String, Object> bindVariablesMap, AccessLevel accessLevel ){
            return Database.getCursorWithBinds( query, bindVariablesMap, accessLevel );
        }
        public Database.PaginationCursor getPaginationCursor( String query, AccessLevel accessLevel ){
            return Database.getPaginationCursor( query, accessLevel );
        }
        public Database.PaginationCursor getPaginationCursor( String query, Map<String, Object> bindVariablesMap, AccessLevel accessLevel ){
            return Database.getPaginationCursorWithBinds( query, bindVariablesMap, accessLevel );
        }
    }

    /**
     * Class implementation of the QueryProxy that applies the sharing context from the callee (aka "inherit sharing").
     * All QueryProxy implementations have public methods to be able to be accessed outside of this class without being able to instantiate the implementations
     */
    @TestVisible
    private inherited sharing class QueryInheritedSharing implements dfflib_Database_IQuery{
        public List<Object> query( String query, AccessLevel accessLevel ){
            return Database.query( query, accessLevel );
        }
        public List<Object> query( String query, Map<String, Object> bindVariablesMap, AccessLevel accessLevel ){
            return Database.queryWithBinds( query, bindVariablesMap, accessLevel );
        }
        public Database.QueryLocator getQueryLocator( String query, AccessLevel accessLevel ){
            return Database.getQueryLocator( query, accessLevel );
        }
        public Database.QueryLocator getQueryLocator( String query, Map<String, Object> bindVariablesMap, AccessLevel accessLevel ){
            return Database.getQueryLocatorWithBinds( query, bindVariablesMap, accessLevel );
        }
        public Database.Cursor getCursor( String query, AccessLevel accessLevel ){
            return Database.getCursor( query, accessLevel );
        }
        public Database.Cursor getCursor( String query, Map<String, Object> bindVariablesMap, AccessLevel accessLevel ){
            return Database.getCursorWithBinds( query, bindVariablesMap, accessLevel );
        }
        public Database.PaginationCursor getPaginationCursor( String query, AccessLevel accessLevel ){
            return Database.getPaginationCursor( query, accessLevel );
        }
        public Database.PaginationCursor getPaginationCursor( String query, Map<String, Object> bindVariablesMap, AccessLevel accessLevel ){
            return Database.getPaginationCursorWithBinds( query, bindVariablesMap, accessLevel );
        }
    }
}
