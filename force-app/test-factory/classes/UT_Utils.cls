/**
 * Copyright (c), Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
/**
 * Unit test utility methods to support unit tests.
 *
 */
@IsTest
public with sharing class UT_Utils{

    // Private static
    private static final Map<String, Map<String, SObject>> sObjectCache = new Map<String, Map<String, SObject>>();

    /**
     * Utility method for getting the record for the current user. This is useful when you want to use System.runAs
     * without having to duplicate this query.
     *
     * @return	The user record associated to the current user.
     */
    public static User getCurrentUser(){
        return new User( Id = UserInfo.getUserId() );
    }

    /**
     * This creates a list of sObjects based on the sObject instance provided, it clones it upto the number
     * of sObjects requested.
     *
     * @param  sObj 			SObject instance to clone to populate the return list.
     * @param  numberOfObjects  Number of sObjects to create
     * @return                  List of sObjects populated with the data populated using the default test value data provider.
     */
    public static SObject[] createSObjectList( SObject sObj, Integer numberOfObjects ){
        return createSObjectList( sObj, numberOfObjects, false );
    }

    /**
     * This creates a list of sObjects based on the sObject instance provided, it clones it upto the number
     * of sObjects requested. Additionally, you can specify to insert the created sObjects immediately to the database.
     *
     * @param  sObj 			SObject instance to clone to populate the return list.
     * @param  numberOfObjects  Number of sObjects to create
     * @param  doInsert  		Set to true to insert the data immediately to the database.
     * @return                  List of sObjects populated with the data populated using the default test value data
     *                          provider.
     */
    public static SObject[] createSObjectList( SObject sObj, Integer numberOfObjects, Boolean doInsert ){
        List<SObject> records = new List<SObject>();

        for( Integer i = 0; i < numberOfObjects; i++ ){
            records.add( new UT_SObjectFactory().create( sObj ).getSObject() );
        }

        if( doInsert ){
            Database.insert( records, AccessLevel.USER_MODE );
        }

        return records;
    }

    /**
     * This will return the ID of the profile found within the system matching the given name.
     *
     * @param profileName	Profile name to get the ID of.
     */
    public static Id getProfileId( String profileName ){
        return getProfile( profileName ).Id;
    }

    /**
     * This will return the profile record found within the system matching the given name.
     */
    public static Profile getProfile( String name ){
        Map<String, SObject> cachedMap = loadCache(
            'Profile',
            'name',
            new List<String>{ name },
            new Set<String>{ 'name' }
        );
        Profile p = ( Profile ) cachedMap.get( name );
        return p;
    }


    /**
     * Cache specific records for subsequent use in calls like getProfile, getRole, etc
     */
    public static Map<String, SObject> loadCache(
        String objectName,
        String fieldName,
        List<String> keyValues,
        Set<String> fieldsToCache ){
        String objectNameLower = objectName.toLowerCase();
        Map<String, SObject> resultMap = new Map<String, SObject> ();
        Map<String, SObject> cachedMap = sObjectCache.get( objectNameLower );

        if( cachedMap == null ){
            cachedMap = new Map<String, SObject>();
            sObjectCache.put( objectNameLower, cachedMap );
        }

        Set<String> keysToLoad = new Set<String>();
        for( String key : keyValues ){
            SObject objLoaded = cachedMap.get( key );
            if( objLoaded == null ){
                keysToLoad.add( key );
            } else{
                resultMap.put( key, objLoaded );
            }
        }

        if( !keysToLoad.isEmpty() ){
            String soqlStr = 'SELECT Id, ' + fieldName;
            for( String fName : fieldsToCache ){
                if( !'id'.equalsIgnoreCase( fName ) && !fieldName.equalsIgnoreCase( fName ) ){
                    soqlStr += ',' + fName;
                }
            }
            soqlStr += ' FROM ' + objectName + ' WHERE ' + fieldName + ' in: keysToLoad';

            for( SObject obj : Database.query( soqlStr, AccessLevel.USER_MODE ) ){
                resultMap.put( ( String ) obj.get( fieldName ), obj );
            }
            cachedMap.putAll( resultMap );
        }
        return resultMap;
    }

    /**
     * Utility method for create mock Database.SaveResult instances.
     *
     * @param recordId		The ID of the record to generate a save result for.
     * @param success		Indicates if the save result should be successful or not.
     * @param message		An optional error message to be added.
     *
     * @return	A new Database.SaveResult mock instance.
     */
    public static Database.SaveResult createSaveResult( Id recordId, Boolean success, String message ){
        Map<String, Object> result = new Map<String, Object>{
            'success' => success,
            'id' => recordId
        };

        if( !String.isBlank( message ) ){
            result.put( 'errors', new List<Object>{
                new Map<String, String>{
                    'message' => message
                }
            } );
        }

        return ( Database.SaveResult ) JSON.deserialize( JSON.serialize( result ), Database.SaveResult.class );
    }

    /**
     * Utility method for create mock Database.DeleteResult instances.
     *
     * @param recordId		The ID of the record to generate a delete result for.
     * @param success		Indicates if the save result should be successful or not.
     * @param message		An optional error message to be added.
     *
     * @return	A new Database.DeleteResult mock instance.
     */
    public static Database.DeleteResult createDeleteResult( Id recordId, Boolean success, String message ){
        Map<String, Object> result = new Map<String, Object>{
            'success' => success,
            'id' => recordId
        };

        if( !String.isBlank( message ) ){
            result.put( 'errors', new List<Object>{
                new Map<String, String>{
                    'message' => message
                }
            } );
        }

        return ( Database.DeleteResult ) JSON.deserialize( JSON.serialize( result ), Database.DeleteResult.class );
    }

    /**
     * Utility method for create mock Database.UndeleteResult instances.
     *
     * @param recordId		The ID of the record to generate a undelete result for.
     * @param success		Indicates if the save result should be successful or not.
     * @param message		An optional error message to be added.
     *
     * @return	A new Database.UndeleteResult mock instance.
     */
    public static Database.UndeleteResult createUndeleteResult( Id recordId, Boolean success, String message ){
        Map<String, Object> result = new Map<String, Object>{
            'success' => success,
            'id' => recordId
        };

        if( !String.isBlank( message ) ){
            result.put( 'errors', new List<Object>{
                new Map<String, String>{
                    'message' => message
                }
            } );
        }

        return ( Database.UndeleteResult ) JSON.deserialize( JSON.serialize( result ), Database.UndeleteResult.class );
    }
}