/**
 * Copyright (c) 2019, Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
/**
 *  Class that serves as a config provider to the dfflib_Application main class.
 *  Note this class intentionally performs queries outside a Selector layer context,
 *  allowing proper mocking injection using apex-mocks framework without the need for self-referencing custom metadata records
 */
public with sharing class dfflib_ApplicationConfig implements IApplicationConfig{

    private interface IApplicationConfig{
        List<Dfflib_Domain_Config__mdt> getDomainConfig( String domainSObjectTypeText );
        List<Dfflib_Selector_Config__mdt> getSelectorConfig( String selectorSObjectTypeText );
        List<Dfflib_Service_Config__mdt> getServiceConfig( String serviceInterfaceTypeText );
        List<Dfflib_UOW_Config__mdt> getUnitOfWorkConfigs();
    }

    public List<Dfflib_Domain_Config__mdt> getDomainConfig( String domainSObjectTypeText ){
        return [ SELECT SObjectType__c, Implementation_Type__c FROM Dfflib_Domain_Config__mdt WHERE SObjectType__c = :domainSObjectTypeText ];
    }

    public List<Dfflib_Selector_Config__mdt> getSelectorConfig( String selectorSObjectTypeText ){
        return [ SELECT SObjectType__c, Implementation_Type__c FROM Dfflib_Selector_Config__mdt WHERE SObjectType__c = :selectorSObjectTypeText ];
    }

    public List<Dfflib_Service_Config__mdt> getServiceConfig( String serviceInterfaceTypeText ){
        return [ SELECT Interface_Type__c, Implementation_Type__c FROM Dfflib_Service_Config__mdt WHERE Interface_Type__c = :serviceInterfaceTypeText ];
    }

    public List<Dfflib_UOW_Config__mdt> getUnitOfWorkConfigs(){
        return [ SELECT SObjectType__c, SortOrder__c FROM Dfflib_UOW_Config__mdt ORDER BY SortOrder__c, SObjectType__c ];
    }
}
