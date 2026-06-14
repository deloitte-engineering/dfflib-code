/**
 * Copyright (c) 2025, Deloitte NL
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 *   are permitted provided that the following conditions are met:
 *
 * - Redistributions of source code must retain the above copyright notice,
 *      this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright notice,
 *      this list of conditions and the following disclaimer in the documentation
 *      and/or other materials provided with the distribution.
 * - Neither the name of the FinancialForce.com, inc nor the names of its contributors
 *      may be used to endorse or promote products derived FROM this software without
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
 * A replacer is used when adding values to an instance of SObjectMock within UT_SObjectFactory. Replacers provide
 * the ability to use merge fields for dynamic values, such as counters or ensuring randomised values each time an
 * sObject is mocked or saved to the database.
 *
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