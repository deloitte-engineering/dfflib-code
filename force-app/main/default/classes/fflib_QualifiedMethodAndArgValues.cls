/**
 * Copyright (c), FinancialForce.com, inc
 * Copyright (c), Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
/**
 * @group Core
 */
public with sharing class fflib_QualifiedMethodAndArgValues{
    private final fflib_QualifiedMethod qm;
    private final fflib_MethodArgValues args;
    private final Object mockInstance;

    public fflib_QualifiedMethodAndArgValues( fflib_QualifiedMethod qm, fflib_MethodArgValues args, Object mockInstance ){
        this.qm = qm;
        this.args = args;
        this.mockInstance = mockInstance;
    }

    public fflib_QualifiedMethod getQualifiedMethod(){
        return qm;
    }

    public fflib_MethodArgValues getMethodArgValues(){
        return args;
    }

    public Object getMockInstance(){
        return mockInstance;
    }

    public override String toString(){
        return qm + ' with args: [' + String.join( args.argValues, '],[' ) + ']';
    }
}
