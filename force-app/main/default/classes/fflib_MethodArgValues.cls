/**
 * Copyright (c), FinancialForce.com, inc
 * Copyright (c), Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
public with sharing class fflib_MethodArgValues{
    public List<Object> argValues;

    /**
     * Wrapper object which encapsulates the argument values supplied during a given method call.
     *
     * @param   argValues   List<Object> containing the arguments values.
     */
    public fflib_MethodArgValues( List<Object> argValues ){
        this.argValues = argValues;
    }

    /**
     * Standard equals override.
     *
     * @param   other   The object whose equality we are verifying
     * @return  Boolean True if meaningfully equivalent, false otherwise.
     */
    public Boolean equals( Object other ){
        if( this === other ){
            return true;
        }

        fflib_MethodArgValues that = other instanceof fflib_MethodArgValues ? ( fflib_MethodArgValues ) other : null;
        return that != null && this.argValues == that.argValues;
    }

    /**
     * Standard hashCode override.
     *
     * @return  Integer The generated hashCode
     */
    public Integer hashCode(){
        Integer prime = 31;
        Integer result = 1;

        result = prime * result + ( ( argValues == null ) ? 0 : argValues.hashCode() );

        return result;
    }
}
