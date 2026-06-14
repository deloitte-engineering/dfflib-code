/**
 * Copyright (c), FinancialForce.com, inc
 * Copyright (c) 2026, Deloitte Consultative Services B.V.
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
 * - Neither the name of the FinancialForce.com inc, nor Deloitte Consultative Services B.V., nor the names of its contributors
 *      may be used to endorse or promote products derived from this software without
 *      specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 *  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 *  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
 *  THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 *  OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
/**
 * The TestFactoryData contains all the default fields
 *
 * @created        November 2017
 */
@IsTest
public class UT_TestFactoryData{

    /**
     * Map which links an sObjectType to a class which is responsible for generating keys based upon the populated
     * values within a given record.
     */
    public static final Map<SObjectType, UT_SObjectFactory.Keyable> keyableMap = new Map<SObjectType, UT_SObjectFactory.Keyable>{
        User.sObjectType => new FieldNameKeyable( 'Username' )
    };


    /**
     * Generic field name key generator. This will generate a key based upon the value held within an sObject records'
     * field.
     */
    private class FieldNameKeyable implements UT_SObjectFactory.Keyable{
        private String fieldName;

        public FieldNameKeyable( String fieldName ){
            this.fieldName = fieldName.toLowerCase();
        }

        public String generateKey( SObject record ){
            String value = ( String ) record.get( fieldName );
            value = value != null ? value.toLowerCase() : null;
            return value;
        }

        public List<SObject> reload( SObjectType sType ){
            List<SObject> records = new List<SObject>();
            Id userId = UserInfo.getUserId();
            String fieldNames = String.join( UT_SObjectFactoryUtils.getFieldNameList( sType ), ',' );

            for( SObject record : Database.query( 'SELECT ' + fieldNames + ' FROM ' + sType.getDescribe().getName() + ' WHERE CreatedById = :userId AND CreatedDate = TODAY' ) ){
                if( generateKey( record ) != null ){
                    records.add( record );
                }
            }

            return records;
        }

    }

    public class AccountDefaults extends UT_SObjectFactory.SObjectDefaults{
        public override Map<String, Object> getFieldValues(){
            return new Map<String, Object>{
                'Name' => 'Test Account'
            };
        }
    }

    public class OpportunityDefaults extends UT_SObjectFactory.SObjectDefaults{
        public override Map<String, Object> getFieldValues(){
            return new Map<String, Object>{
                'Name' => 'Test Opportunity',
                'StageName' => 'Nieuw',
                'CloseDate' => System.today().addDays( 1 )
            };
        }
    }

    public class Product2Defaults extends UT_SObjectFactory.SObjectDefaults{
        public override Map<String, Object> getFieldValues(){
            return new Map<String, Object>{
                'Name' => new UT_Replacers.CounterReplacer( 'Test Product {0}' )
            };
        }
    }

    /**
     * Test data value provider for the (Person) Account sObject.
     */
    public class UserDefaults extends UT_SObjectFactory.SObjectDefaults{
        public override Map<String, Object> getFieldValues(){
            return new Map<String, Object>{
                'firstName' => 'testFirstName',
                'localeSidKey' => 'en_US',
                'languageLocaleKey' => 'en_US',
                'lastname' => 'test',
                'TimeZoneSidKey' => 'GMT',
                'EmailEncodingKey' => 'UTF-8',
                'alias' => 'ttk',
                'CommunityNickname' => new UT_Replacers.RandomReplacer( 'TEST{0}', 8 ),
                'Username' => new UT_Replacers.CounterReplacer( 'unittestuser{0}@fflibfast.com' ),
                'Email' => new UT_Replacers.CounterReplacer( 'unittestuser{0}@fflibfast.com' )
            };
        }
    }
}