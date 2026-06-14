/**
 * Copyright (c) 2025, Deloitte NL
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 *   are permitted provided that the following conditions are met:
 *
 * - Redistributions of source code must retain the above copyright notices,
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
/**
 *  Class that serves as a hub providing access to DML- and QueryProxy interfaces.
 *  It centralises database security modes to be used for setting sharing context and enforcement of CRUD/FLS on the respective interface implementation.
 *
 *  @created    February 2023
 */
public class fflib_Database{

    /**
     * Enum defining the security context within the proxy interface. The security context (independently!) controls both the sharing rules' context to be applied (either system/user context), and FLS/CRUD permission level.
     * The following options have been compiled:
     *
     *  - FULL
     *  - SHARING_SKIP_PERMISSIONS
     *  - NONE
     *  - INHERIT
     *
     * Following a secure-by-design holistic approach, Proxy interface configuration should default baseline to a full user context (i.e. enforcing sharing rules and FLS/CRUD permission checks), giving flexibility to
     * switch between modes depending on the business context.
     */
    public enum Context{
        FULL,
        SHARING_SKIP_PERMISSIONS,
        NONE,
        INHERIT
    }

    // Mapping of database security contexts to the respective AccessLevel
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