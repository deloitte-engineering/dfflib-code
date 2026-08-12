/**
 * Copyright (c), FinancialForce.com, inc
 * Copyright (c), Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
public with sharing class fflib_MatchersReturnValue{
    public List<fflib_IMatcher> matchers;
    public fflib_MethodReturnValue returnValue;

    public fflib_MatchersReturnValue( List<fflib_IMatcher> matchers, fflib_MethodReturnValue returnValue ){
        this.matchers = matchers;
        this.returnValue = returnValue;
    }
}
