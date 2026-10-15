/**
 * Copyright (c), FinancialForce.com, inc
 * Copyright (c), Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
@NamespaceAccessible
public with sharing class fflib_IDGenerator{

    private static Integer fakeIdCount = 0;
    private static final String ID_PATTERN = '000000000000';
    private static Map<SObjectType, String> prefixCacheMap = new Map<SObjectType, String>();

    /**
     * Method that generates a fake Salesforce Id for the given SObjectType.
     *
     * @param	sObjectType		The type of SObject being described.
     * @return	Randomized Salesforce Id for the given SObjectType.
     */
    public static Id generate( Schema.SObjectType sObjectType ){
        // Avoid describing sObject multiple times
        if( !prefixCacheMap.containsKey( sObjectType ) ){
            prefixCacheMap.put( sObjectType, sObjectType.getDescribe().getKeyPrefix() );
        }

        String keyPrefix = prefixCacheMap.get( sObjectType );

        fakeIdCount++;
        String fakeIdPrefix = ID_PATTERN.substring( 0, ID_PATTERN.length() - fakeIdCount.format().replaceAll( '[^\\d.]', '' ).length() );
        return Id.valueOf( keyPrefix + fakeIdPrefix + fakeIdCount );
    }
}