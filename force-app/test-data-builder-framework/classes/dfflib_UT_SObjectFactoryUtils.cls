/**
 * Copyright (c) 2019, Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
/**
 * Common utilities for the unit test class factory classes.
 */
@IsTest
public with sharing class dfflib_UT_SObjectFactoryUtils{

    // Variables for caching the FieldNames and Relationships for Objects
    private static final Map<SObjectType, List<String>> fieldNamesByObjectType = new Map<SObjectType, List<String>>();

    // Cache for storing the child relationship lookup field tokens
    private static final Map<SObjectType, Map<String, SObjectField>> childRelationshipCache = new Map<SObjectType, Map<String, SObjectField>>();

    // Cache for storing the child relationship names
    private static final Map<SObjectType, Map<SObjectField, String>> childRelationshipNameCache = new Map<SObjectType, Map<SObjectField, String>>();

    // Cache for storing the field names for SObjectFields, reduces need to constantly describe fields
    private static Map<SObjectField, String> fieldNameMap = new Map<SObjectField, String>();

    /**
     * Method to resolve the Field Names the given SObjectType
     *
     * @param  sObjectType    SObjectType for which the Field Names needs to be resolved
     * @return List<String>   List with Field Names
     */
    public static List<String> getFieldNameList( SObjectType sObjectType ){
        List<String> fieldNames = fieldNamesByObjectType.get( sObjectType );

        if( fieldNames == null ){
            Map<String, SObjectField> fieldMap = sObjectType.getDescribe().fields.getMap();
            fieldNames = new List<String>( fieldMap.keySet() );
            fieldNamesByObjectType.put( sObjectType, fieldNames );
        }

        return fieldNames;
    }

    /**
     * Method to get the SObject Field Value without causing errors for compound fields.
     * e.g. BillingAddress, Address, Location...
     *
     * @param  sObject      SObject record which contains the data
     * @param  fieldName    Field name for which the value needs to be returned
     * @return Object       The value of the field
     */
    public static Object getFieldValue( SObject sObj, String fieldName ){
        if( sObj == null ) return null;
        Object value = null;

        // try catch to prevent exceptions on compound fields
        try{
            value = sObj.get( fieldName );
        } catch( Exception eIgnore ){
            // Expected exception, swallowing deliberately
        }
        return value;
    }

    /**
     * Method to get Child Relationship field name for given parent SObjectType and child relationship field name
     *
     * @param    parentType          Parent SObject Type
     * @param    relationshipName    Parent Relation field name which links to the children
     * @return    String with Child Field Name which links to the Parent
     */
    public static String getChildRelationshipFieldName( Schema.SObjectType parentType, String relationshipName ){
        return getFieldName( getChildRelationshipFieldToken( parentType, relationshipName ) );
    }

    /**
     * Method to get Child Relationship field token for given parent SObjectType and child relationship field name
     *
     * @param    parentType            Parent SObject Type
     * @param    relationshipName    Parent Relation field name which links to the children
     *
     * @return    SObjectField (Token) which links to the Parent
     */
    public static Schema.SObjectField getChildRelationshipFieldToken( Schema.SObjectType parentType, String relationshipName ){
        // Prepare the cache map for this sObject type
        initCache( parentType );

        // Retrieve a potential cache entry
        Schema.SObjectField token = childRelationshipCache.get( parentType ).get( relationshipName );

        // If we have a cache miss then attempt to find the relationship field
        if( token == null ){
            DescribeSObjectResult parentDescribe = parentType.getDescribe();
            List<Schema.ChildRelationship> childRelationships = parentDescribe.getChildRelationships();

            for( Schema.ChildRelationship childRelationship : childRelationships ){
                if( childRelationship.relationshipName == relationshipName ){
                    token = childRelationship.getField();
                    break;
                }
            }

            childRelationshipCache.get( parentType ).put( relationshipName, token );
            childRelationshipNameCache.get( parentType ).put( token, relationshipName );
        }

        return token;
    }

    /**
     * This will determine the child relationship name for a given sObject field in relation to its parent relationship.
     * Note, this does not work with polymorphic fields.
     *
     * @param sType                 The sObjectType of the parent sObject to use to find the child relationship which matches
     * @param relationshipField     The field on the child object.
     *
     * @return    The child relationship name for the given field from the parent object. E.g. If selecting contacts
     *             as a subquery from the account object then the relationship name would be "Contacts".
     */
    public static String getChildRelationshipName( SObjectType sType, SObjectField relationshipField ){
        // Prepare the cache map for this sObject type
        initCache( sType );

        // Retrieve a potential cache entry
        String name = childRelationshipNameCache.get( sType ).get( relationshipField );

        // If we have a cache miss then attempt to find the relationship name
        if( name == null ){
            DescribeSObjectResult parentDescribe = sType.getDescribe();
            List<Schema.ChildRelationship> relationships = parentDescribe.getChildRelationships();

            for( Schema.ChildRelationship relationship : relationships ){
                if( relationship.getField() == relationshipField ){
                    name = relationship.getRelationshipName();
                    break;
                }
            }

            childRelationshipCache.get( sType ).put( name, relationshipField );
            childRelationshipNameCache.get( sType ).put( relationshipField, name );
        }

        return name;
    }

    private static void initCache( SObjectType sType ){
        if( !childRelationshipCache.containsKey( sType ) ){
            childRelationshipCache.put( sType, new Map<String, SObjectField>() );
            childRelationshipNameCache.put( sType, new Map<SObjectField, String>() );
        }
    }

    /**
     * Utility method for retrieving the API name of a field using the fields token (SObjectField). As the operation
     * to get the field name through a describe call is relatively expensive, especially when hit multiple times
     * within the same transaction, this method also caches the field name to avoid describing the field on later calls.
     *
     * @param   field     The field on the child object.
     *
     * @return  String value of field API Name
     */
    public static String getFieldName( SObjectField field ){
        String name = fieldNameMap.get( field );

        if( !fieldNameMap.containsKey( field ) ){
            name = field.getDescribe().getName();
            fieldNameMap.put( field, name );
        }

        return name;
    }
}
