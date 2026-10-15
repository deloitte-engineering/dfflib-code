/**
 * Copyright (c), FinancialForce.com, inc
 * Copyright (c), Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
/**
 * Helper class, roughly based on the Java version, but subclassed to assist in a number of use cases in this library.
 * 
 * NOTE: Aspects of this where developed before recent improvements to String handling, as such could likely be enhanced at this stage.
 */
@NamespaceAccessible
public virtual class fflib_StringBuilder{
    @NamespaceAccessible
    protected List<String> buffer = new List<String>();

    /**
     * Construct an empty StringBuilder.
     */
    @NamespaceAccessible
    public fflib_StringBuilder(){}

    /**
     * Construct a StringBuilder with the given values.
     */
    @NamespaceAccessible
    public fflib_StringBuilder( List<String> values ){
        add( values );
    }

    /**
     * Add the given values to the StringBuilder.
     */
    @NamespaceAccessible
    public virtual void add( List<String> values ){
        buffer.addAll( values );
    }

    /**
     * Add the given value to the StringBuilder.
     */
    @NamespaceAccessible
    public virtual void add( String value ){
        buffer.add( value );
    }

    @NamespaceAccessible
    public virtual override String toString(){
        return String.join( buffer, '' );
    }

    /**
     * Method that returns the state of the StringBuilder. It is provided as a convenience in the event you wish to
     * handle the state of the StringBuilder in a different way.
     *
     * @return  String representing the current state of the StringBuilder.
     */
    @NamespaceAccessible
    public virtual String getStringValue(){
        return toString();
    }

    /**
     * Subclasses the StringBuilder to produce a comma delimited concatenation of strings.
     */
    @NamespaceAccessible
    public virtual with sharing class CommaDelimitedListBuilder extends fflib_StringBuilder{
        String itemPrefix = '';
        String delimiter = ',';

        @NamespaceAccessible
        public CommaDelimitedListBuilder(){}

        @NamespaceAccessible
        public CommaDelimitedListBuilder( List<String> values ){
            super( values );
        }

        @NamespaceAccessible
        public void setItemPrefix( String itemPrefix ){
            this.itemPrefix = itemPrefix;
        }

        @NamespaceAccessible
        public void setDelimiter( String delimiter ){
            this.delimiter = delimiter;
        }

        @NamespaceAccessible
        public String getStringValue( String itemPrefix ){
            setItemPrefix( itemPrefix );
            return toString();
        }

        @NamespaceAccessible
        public override String toString(){
            return itemPrefix + String.join( buffer, delimiter + itemPrefix );
        }
    }

    /**
     * Subclasses the StringCommaDelimitedBuilder to accept native SObjectField tokens and optional FieldSet definitions
     * to concatenate when building queries.
     */
    @NamespaceAccessible
    public virtual with sharing class FieldListBuilder extends CommaDelimitedListBuilder{

        /**
         * Construct a FieldListBuilder with the given values.
         */
        @NamespaceAccessible
        public FieldListBuilder( List<Schema.SObjectField> values ){
            this( values, null );
        }

        /**
         * Construct a FieldListBuilder with the given values and field set definitions.
         */
        @NamespaceAccessible
        public FieldListBuilder( List<Schema.SObjectField> values, List<Schema.FieldSet> fieldSets ){
            // Create a distinct set of fields (or field paths) to select
            for( Schema.SObjectField value : values ){
                add( String.valueOf( value ) );
            } // Alternative to value.getDescribe().getName()

            if( fieldSets != null ){
                for( Schema.FieldSet fieldSet : fieldSets ){
                    for( Schema.FieldSetMember fieldSetMember : fieldSet.getFields() ){
                        add( fieldSetMember.getFieldPath() );
                    }
                }
            }
        }
    }

    /**
     * Subclasses the FieldListBuilder to auto sense and include when needed the CurrencyIsoCode field in the field list.
     */
    @NamespaceAccessible
    public with sharing class MultiCurrencyFieldListBuilder extends FieldListBuilder{

        /**
         * Construct a MultiCurrencyFieldListBuilder with the given values.
         */
        @NamespaceAccessible
        public MultiCurrencyFieldListBuilder( List<Schema.SObjectField> values ){
            this( values, null );
        }

        /**
         * Construct a MultiCurrencyFieldListBuilder with the given values and field set definitions.
         */
        @NamespaceAccessible
        public MultiCurrencyFieldListBuilder( List<Schema.SObjectField> values, List<Schema.FieldSet> fieldSets ){
            super( values, fieldSets );

            // Dynamically add CurrencyIsoCode field for multi-currency organisations.
            if( UserInfo.isMultiCurrencyOrganization() ){
                add( 'CurrencyIsoCode' );
            }
        }
    }
}