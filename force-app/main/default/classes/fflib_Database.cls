/**
 * Copyright (c), Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
/**
 *  Class that serves as a hub providing access to DML- and QueryProxy interfaces.
 *  It centralises database security modes to be used for setting sharing context and enforcement of CRUD/FLS on the respective interface implementation.
 *
 */
public inherited sharing class fflib_Database{

    /**
     * Defines the database access context for DML and SOQL operations,
     * controlling AccessLevel, sharing rule enforcement, and FLS/CRUD checks.
     *
     * <pre>
     * Value                    | AccessLevel | Sharing                                            | FLS/CRUD
     * -------------------------|-------------|----------------------------------------------------|-------------
     * FULL                     | USER_MODE   | Enforced, as USER_MODE overrides class declaration | Enforced
     * SHARING_SKIP_PERMISSIONS | SYSTEM_MODE | Enforced, via `with sharing` inner proxy           | Not enforced
     * NONE                     | SYSTEM_MODE | Bypasses, via `without sharing` inner proxy        | Not enforced
     * INHERIT                  | SYSTEM_MODE | Inherited sharing from calling class chain         | Not enforced
     * </pre>
     *
     * Note: SHARING_SKIP_PERMISSIONS, NONE, and INHERIT all map to SYSTEM_MODE for AccessLevel.
     * The difference in record visibility between them is controlled entirely by the inner proxy
     * class's explicit sharing declaration, not by the AccessLevel parameter.
     */
    public enum Context{
        /**
         * USER_MODE — Enforces sharing rules, FLS, and CRUD.
         *
         * <p>AccessLevel is set to {@code USER_MODE}, which always overrides the class-level
         * sharing declaration. Both record visibility and field-level security are enforced.</p>
         *
         * <p><b>Use for:</b> All user-facing operations. Secure by default.</p>
         *
         * <p><b>API v67.0:</b> Immune to the sharing default change —
         * {@code USER_MODE} always overrides class sharing regardless of API version.</p>
         */
        FULL,
        /**
         * SYSTEM_MODE — Enforces sharing rules, skips FLS/CRUD.
         *
         * <p>AccessLevel is set to {@code SYSTEM_MODE} via an explicit {@code with sharing}
         * inner proxy class. Record visibility is respected, but field-level security is not enforced.</p>
         *
         * <p><b>Use for:</b> Operations that must respect record visibility but do not require FLS checks.</p>
         *
         * <p><b>API v67.0:</b> Inner proxy has explicit {@code with sharing} —
         * unaffected by the sharing default change.</p>
         */
        SHARING_SKIP_PERMISSIONS,
        /**
         * SYSTEM_MODE — Bypasses sharing rules and FLS/CRUD entirely.
         *
         * <p>AccessLevel is set to {@code SYSTEM_MODE} via an explicit {@code without sharing}
         * inner proxy class. All records are visible regardless of the user's permissions.</p>
         *
         * <p><b>Use for:</b> System-level operations that must access all records regardless of user permissions.</p>
         *
         * <p><b>API v67.0:</b> Inner proxy has explicit {@code without sharing} — unaffected by the sharing
         * default change. This is the <b>only</b> context that guarantees pre-v67.0 'all records visible'
         * behaviour regardless of the calling class's API version or sharing declaration.</p>
         */
        NONE,
        /**
         * SYSTEM_MODE — Inherits the sharing intent of the calling class chain.
         *
         * <p>AccessLevel is set to {@code SYSTEM_MODE} via an {@code inherited sharing} inner proxy.
         * Record visibility follows the sharing declaration of the nearest explicit class in the call stack.</p>
         *
         * <p><b>Use for:</b> Framework-transparent operations where the caller's sharing intent should propagate.</p>
         *
         * <p><b>API v67.0:</b> Any class in the calling chain without an explicit sharing keyword now defaults
         * to {@code with sharing}. Client classes extending framework base classes <b>must</b> declare an
         * explicit sharing keyword before compiling at v67.0+.
         * See {@code documentation/API-v67-Upgrade-Guide.md}.</p>
         */
        INHERIT
    }

    // Mapping of database security contexts to the respective AccessLevel.
    // Note: SHARING_SKIP_PERMISSIONS, NONE, and INHERIT all use SYSTEM_MODE — record visibility differences
    // between these three contexts are governed by the inner proxy class sharing declarations in
    // fflib_Database_DMLProxy and fflib_Database_QueryProxy, not by the AccessLevel parameter.
    private final static Map<fflib_Database.Context, AccessLevel> SECURITY_CONTEXT_ACCESS_LEVEL_MAP = new Map<fflib_Database.Context, AccessLevel>{
        fflib_Database.Context.FULL => AccessLevel.USER_MODE,
        fflib_Database.Context.SHARING_SKIP_PERMISSIONS => AccessLevel.SYSTEM_MODE,
        fflib_Database.Context.NONE => AccessLevel.SYSTEM_MODE,
        fflib_Database.Context.INHERIT => AccessLevel.SYSTEM_MODE
    };

    /**
     * Getter providing an AccessLevel for the security context provided
     *
     * @param   securityContext     Database security context
     * @return  AccessLevel for the security context provided
     */
    public static AccessLevel getAccessLevel( fflib_Database.Context securityContext ){
        return SECURITY_CONTEXT_ACCESS_LEVEL_MAP.get( securityContext );
    }

    /**
     * Getter providing a fflib_Database_DMLProxy implementation for the security context provided
     *
     * @param   securityContext     Database security context for DML operations to be executed on
     * @return  fflib_Database_DMLProxy implementation for the security context provided
     */
    public static fflib_Database_IDML getDMLProxy( Context securityContext ){
        return fflib_Database_DMLProxy.getDMLProxyImplementation( securityContext );
    }

    /**
     * Getter providing a fflib_Database_QueryProxy implementation for the security context model provided
     *
     * @param   securityContext     Database security context for queries to be executed on
     * @return  fflib_Database_QueryProxy implementation for the security context provided
     */
    public static fflib_Database_IQuery getQueryProxy( Context securityContext ){
        return fflib_Database_QueryProxy.getQueryProxyImplementation( securityContext );
    }
}
