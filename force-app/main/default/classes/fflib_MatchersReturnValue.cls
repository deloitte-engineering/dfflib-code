/**
 * Copyright (c), FinancialForce.com, inc
 * Copyright (c) 2019, Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
/**
 * Wrapper object which encapsulates the matchers and corresponding return value
 * for a given stubbed method invocation.
 */
@NamespaceAccessible
@SuppressWarnings('PMD.ClassNamingConventions, PMD.ApexDoc')
public with sharing class fflib_MatchersReturnValue{
    /**
     * The list of matchers to match against method arguments.
     */
    public List<fflib_IMatcher> matchers;

    /**
     * The return value to be returned when all matchers match.
     */
    public fflib_MethodReturnValue returnValue;

    /**
     * Constructor to create a wrapper object for matchers and their corresponding return value.
     * @param matchers The list of matchers to match against method arguments
     * @param returnValue The return value to be returned when all matchers match
     */
    public fflib_MatchersReturnValue( List<fflib_IMatcher> matchers, fflib_MethodReturnValue returnValue ){
        this.matchers = matchers;
        this.returnValue = returnValue;
    }
}