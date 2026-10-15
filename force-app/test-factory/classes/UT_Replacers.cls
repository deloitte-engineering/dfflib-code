/**
 * Copyright (c), Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
/**
 * A replacer is used when adding values to an instance of SObjectMock within UT_SObjectFactory. Replacers provide
 * the ability to use merge fields for dynamic values, such as counters or ensuring randomised values each time an
 * sObject is mocked or saved to the database.
 *
 * @author      Adam Marchbanks (amarchbanks@deloitte.nl)
 * @created     January 2017
 */
@IsTest
public with sharing class UT_Replacers{

    private static final Map<String, Integer> countersMap = new Map<String, Integer>();

    /**
     * A simple counter replacer which will increment by one each time it is evaluated for a field on an sObject.
     * E.g. new CounterReplacer('Account Name {0}') would result in 'Account Name 0'.
     */
    public class CounterReplacer implements UT_SObjectFactory.ValueReplacer{
        private String value;

        public CounterReplacer( String value ){
            this.value = value;
        }

        public String evaluate( SObjectType sObjectType, String fieldName ){
            String key = sObjectType.getDescribe().getName() + '.' + fieldName;

            if( !countersMap.containsKey( key ) ){
                countersMap.put( key, -1 );
            }

            countersMap.put( key, countersMap.get( key ) + 1 );

            String output = String.format( value, new List<String>{ String.valueOf( countersMap.get( key ) ) } );
            return output;
        }
    }

    /**
     * A replacer which will generate a random output.
     * E.g. new CounterReplacer( 'Account Name {0}' ) would result in 'Account Name 897812328'.
     */
    public class RandomReplacer implements UT_SObjectFactory.ValueReplacer{
        private String value;
        private Integer length;

        public RandomReplacer( String value, Integer length ){
            this.value = value;
            this.length = length;
        }

        public String evaluate( SObjectType sObjectType, String fieldName ){
            String argument = String.valueof( Math.random() * 99999999 );
            while( argument.length() < length ){
                argument = argument + '0';
            }
            return String.format( value, new List<String>{ argument } ).substring( 0, length );
        }
    }
}
