/**
 * Copyright (c), Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
/**
 * The TestFactoryData contains all the default fields
 *
 * @author         Dirk van de Lindt (dvandelindt@deloitte.nl)
 * @created        November 2017
 */
@IsTest
public with sharing class UT_TestFactoryData{

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

            for( SObject record : Database.query( 'SELECT ' + fieldNames + ' FROM ' + sType.getDescribe().getName() + ' WHERE CreatedById = :userId AND CreatedDate = TODAY', AccessLevel.USER_MODE ) ){
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