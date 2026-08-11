/**
 * Copyright (c), FinancialForce.com, inc
 * Copyright (c), Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
/**
 * Base class for generic Apex objects (including SObjects), providing core utilities to treat records as typed object instances for other framework layers
 *
 *  @created    October 2025
 */
public virtual class fflib_Objects implements fflib_IObjects{
    protected List<Object> objects{ get; protected set; } {
        objects = new List<Object>();
    }

    /**
     * Class constructor
     */
    public fflib_Objects( List<Object> objects ){
        // Ensure the domain class has its own copy of the data
        this.objects = objects.clone();
    }

    public virtual Object getType(){
        return Object.class;
    }

    public List<Object> getObjects(){
        return this.objects;
    }

    public Boolean contains( Object value ){
        return getObjects()?.contains( value );
    }

    public Boolean containsAll( List<Object> values ){
        if( values == null ){
            return false;
        }

        return containsAll( new Set<Object>( values ) );
    }

    public Boolean containsAll( Set<Object> values ){
        if( values == null ){
            return false;
        }

        for( Object value : values ){
            if( !getObjects()?.contains( value ) ) return false;
        }
        return true;
    }

    public Boolean containsNot( Object value ){
        return !contains( value );
    }

    public Boolean containsNot( List<Object> values ){
        if( values == null ) return true;

        return containsNot( new Set<Object>( values ) );
    }

    public Boolean containsNot( Set<Object> values ){
        if( values == null ) return true;

        for( Object value : values ){
            if( getObjects()?.contains( value ) ) return false;
        }
        return true;
    }

    public Boolean isEmpty(){
        return getObjects()?.isEmpty();
    }

    public Boolean isNotEmpty(){
        return !isEmpty();
    }

    public Integer size(){
        return getObjects().size();
    }

    @TestVisible
    protected void setObjects( List<Object> objects ){
        this.objects = objects;
    }

    /**
     * Method to verify whether the input parameter is not null
     *
     * @param   param           The parameter to validate
     * @param   paramName       The parameter name to display in case the parameter is invalid
     */
    public static void verifyNotNull( Object param, String paramName ){
        if( param == null ){
            throw new fflib.InvalidInputValueException( message( '{0} cannot be null', paramName ) );
        }
    }

    /**
     * Method to verify whether the input parameter is not blank
     *
     * @param   param           The parameter to validate
     * @param   paramName       The parameter name to display in case the parameter is invalid
     */
    public static void verifyNotBlank( String param, String paramName ){
        if( String.isBlank( param ) ){
            throw new fflib.InvalidInputValueException( message( '{0} cannot be blank', paramName ) );
        }
    }

    /**
     * Method to verify whether the input list is not null nor empty
     *
     * @param   objList         The list to validate
     * @param   paramName       The parameter name to display in case the parameter is invalid
     */
    public static void verifyNotEmpty( List<Object> objList, String paramName ){
        if( objList == null || objList.isEmpty() ){
            throw new fflib.InvalidInputValueException( message( '{0} cannot be empty', paramName ) );
        }
    }

    /**
     * Method to shortcut the String.format call when having only one parameter to be substituted
     *
     * @param   message             The message to be formatted
     * @param   substitutionString  The substitution string to replace in the original message
     * @return  String where {0} in message variable is substituted with substitutionString
     */
    public static String message( String message, String substitutionString ){
        return String.format( message, new List<String>{ substitutionString } );
    }
}
