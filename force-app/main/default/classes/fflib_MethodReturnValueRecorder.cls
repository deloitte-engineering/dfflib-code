/**
 * Copyright (c), FinancialForce.com, inc
 * Copyright (c) 2019, Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
@NamespaceAccessible
@SuppressWarnings('PMD.AvoidBooleanMethodParameters, PMD.ClassNamingConventions, PMD.PropertyNamingConventions, PMD.ApexDoc')
public with sharing class fflib_MethodReturnValueRecorder{
    public Boolean stubbing { get; set; }

    public List<Exception> doThrowWhenExceptions { get; set; }

    /**
     * Map of matchers by method.
     *
     * Key: qualifiedMethod
     * Object: map of method return values by method.
     */
    private Map<fflib_QualifiedMethod, List<fflib_MatchersReturnValue>> matcherReturnValuesByMethod;

    public fflib_MethodReturnValue methodReturnValue { get; private set; }

    public fflib_MethodReturnValueRecorder(){
        matcherReturnValuesByMethod = new Map<fflib_QualifiedMethod, List<fflib_MatchersReturnValue>>();

        this.methodReturnValue = null;
    }

    /**
     * Prepare a stubbed method return value.
     *
     * @param   invocation  The object holding all the data of the invocation, like the method and arguments and the mock instance.
     * @return  The MethodReturnValue instance.
     */
    public fflib_MethodReturnValue prepareMethodReturnValue( fflib_InvocationOnMock invocation ){
        this.methodReturnValue = new fflib_MethodReturnValue();

        List<fflib_MatchersReturnValue> matcherReturnValues = matcherReturnValuesByMethod.get( invocation.getMethod() );
        if( matcherReturnValues == null ){
            matcherReturnValues = new List<fflib_MatchersReturnValue>();
            matcherReturnValuesByMethod.put( invocation.getMethod(), matcherReturnValues );
        }

        List<Object> argValues = invocation.getMethodArgValues().argValues;

        // Register explicit arg values as 'equals' matchers, to preserve old behaviour
        if( !fflib_Match.Matching ){
            for( Object arg : argValues ){
                if( arg == null ){
                    fflib_Match.isNull();
                } else{
                    fflib_Match.eq( arg );
                }
            }
        }

        List<fflib_IMatcher> matchers = fflib_Match.getAndClearMatchers( argValues.size() );
        matcherReturnValues.add( new fflib_MatchersReturnValue( matchers, this.methodReturnValue ) );

        return this.methodReturnValue;
    }

    /**
     * Get the method return value for the given method call.
     *
     * @param   invocation  The object holding all the data of the invocation, like the method and arguments and the mock instance.
     * @return  The MethodReturnValue instance.
     */
    public fflib_MethodReturnValue getMethodReturnValue( fflib_InvocationOnMock invocation ){
        List<fflib_MatchersReturnValue> matchersForMethods = matcherReturnValuesByMethod.get( invocation.getMethod() );
        if( matchersForMethods != null ){
            for( Integer i = matchersForMethods.size() - 1; i >= 0; i-- ){
                fflib_MatchersReturnValue matchersReturnValue = ( fflib_MatchersReturnValue ) matchersForMethods.get( i );
                if( fflib_Match.matchesAllArgs( invocation.getMethodArgValues(), matchersReturnValue.matchers ) ){
                    return matchersReturnValue.ReturnValue;
                }
            }
        }

        return null;
    }

    /**
     * Prepare a stubbed exceptions for a void method.
     *
     * @param   exps    The list of exception to throw.
     */
    public void prepareDoThrowWhenExceptions( List<Exception> exps ){
        this.doThrowWhenExceptions = exps;
    }
}