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
 *//**
 * Centralised class to group all Database query operations:
 * 1) Allowing to easily apply different database security models, through sharing modes and access levels (AccessLevel)
 * 2) Allowing optimal separation of concerns where QueryFactory focuses on construction and fflib_Database_QueryProxy on database retrieval
 *      This allows to simplify Test methods, and make the framework more environment-independent (test-classes not failing on added validations)
 *      Lastly, this enables unlocked packages where framework code is not needed to be touched by project developers
 *
 *  @created    February 2023
 */
public abstract class fflib_Database_QueryProxy{

    /**
     * Getter providing a DMLProxy implementation for the security enforcement model provided
     *
     * @param   securityContext     Database security context for queries to be executed on
     * @return  QueryProxy implementation for the security context provided
     */
    public static fflib_Database_IQuery getQueryProxyImplementation( fflib_Database.Context securityContext ){
        return SECURITY_ENFORCEMENT_QUERY.get( securityContext );
    }

    /**
     * Database context models supported mapped to the respective interface implementations.
     */
    private final static Map<fflib_Database.Context, fflib_Database_IQuery> SECURITY_ENFORCEMENT_QUERY = new Map<fflib_Database.Context, fflib_Database_IQuery>{
        fflib_Database.Context.FULL => new QueryWithSharing(),
        fflib_Database.Context.SHARING_SKIP_PERMISSIONS => new QueryWithSharing(),
        fflib_Database.Context.NONE => new QueryWithoutSharing(),
        fflib_Database.Context.INHERIT => new QueryInheritedSharing()
    };

    /**
     * Class implementation of the QueryProxy that enforces sharing rules (aka "with sharing").
     * All QueryProxy implementations have public methods to be able to be accessed outside of this class without being able to instantiate the implementations
     */
    @TestVisible
    private with sharing class QueryWithSharing implements fflib_Database_IQuery{
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
    private without sharing class QueryWithoutSharing implements fflib_Database_IQuery{
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
    private inherited sharing class QueryInheritedSharing implements fflib_Database_IQuery{
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