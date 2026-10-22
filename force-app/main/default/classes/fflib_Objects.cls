/**
 * Copyright (c), FinancialForce.com, inc
 * Copyright (c) 2019, Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
/**
 * Base class for generic Apex objects (including SObjects), providing core utilities to treat records as typed object instances for other framework layers
 */
@NamespaceAccessible
public virtual class fflib_Objects implements fflib_IObjects{
    @NamespaceAccessible
    protected List<Object> objects{ get; protected set; } {
        objects = new List<Object>();
    }

    /**
     * Class constructor
     */
    @NamespaceAccessible
    public fflib_Objects( List<Object> objects ){
        // Ensure the domain class has its own copy of the data
        this.objects = objects.clone();
    }

    @NamespaceAccessible
    public virtual Object getType(){
        return Object.class;
    }

    @NamespaceAccessible
    public List<Object> getObjects(){
        return this.objects;
    }

    @NamespaceAccessible
    public Boolean contains( Object value ){
        return getObjects()?.contains( value );
    }

    @NamespaceAccessible
    public Boolean containsAll( List<Object> values ){
        if( values == null ){
            return false;
        }

        return containsAll( new Set<Object>( values ) );
    }

    @NamespaceAccessible
    public Boolean containsAll( Set<Object> values ){
        if( values == null ){
            return false;
        }

        for( Object value : values ){
            if( !getObjects()?.contains( value ) ) return false;
        }
        return true;
    }

    @NamespaceAccessible
    public Boolean containsNot( Object value ){
        return !contains( value );
    }

    @NamespaceAccessible
    public Boolean containsNot( List<Object> values ){
        if( values == null ) return true;

        return containsNot( new Set<Object>( values ) );
    }

    @NamespaceAccessible
    public Boolean containsNot( Set<Object> values ){
        if( values == null ) return true;

        for( Object value : values ){
            if( getObjects()?.contains( value ) ) return false;
        }
        return true;
    }

    @NamespaceAccessible
    public Boolean isEmpty(){
        return getObjects()?.isEmpty() ?? true;
    }

    @NamespaceAccessible
    public Boolean isNotEmpty(){
        return !isEmpty();
    }

    @NamespaceAccessible
    public Integer size(){
        return getObjects().size();
    }

    @NamespaceAccessible
    @TestVisible
    protected void setObjects( List<Object> objects ){
        this.objects = objects;
    }

    /**
     * Centralised Exception to allow reuse on any invalid input/field value
     */
	@NamespaceAccessible
    public virtual class InvalidValueException extends Exception{}
}