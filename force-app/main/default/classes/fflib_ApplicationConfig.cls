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
 *  Class that serves as a config provider to the fflib_Application main class.
 *  Note this class intentionally performs queries outside a Selector layer context,
 *  allowing proper mocking injection using apex-mocks framework without the need for self-referencing custom metadata records
 *
 *  @author     Rafael Fernandes dos Santos (rfernandesdossantos@deloitte.nl)
 *  @created    February 2022
 */
public with sharing class fflib_ApplicationConfig implements IApplicationConfig{

    private interface IApplicationConfig{
        List<FFLIB_Domain_Config__mdt> getDomainConfig( String domainSObjectTypeText );
        List<FFLIB_Selector_Config__mdt> getSelectorConfig( String selectorSObjectTypeText );
        List<FFLIB_Service_Config__mdt> getServiceConfig( String serviceInterfaceTypeText );
        List<FFLIB_UOW_Config__mdt> getUnitOfWorkConfigs();
    }

    public List<FFLIB_Domain_Config__mdt> getDomainConfig( String domainSObjectTypeText ){
        return [ SELECT SObjectType__c, Implementation_Type__c FROM FFLIB_Domain_Config__mdt WHERE SObjectType__c = :domainSObjectTypeText ];
    }

    public List<FFLIB_Selector_Config__mdt> getSelectorConfig( String selectorSObjectTypeText ){
        return [ SELECT SObjectType__c, Implementation_Type__c FROM FFLIB_Selector_Config__mdt WHERE SObjectType__c = :selectorSObjectTypeText ];
    }

    public List<FFLIB_Service_Config__mdt> getServiceConfig( String serviceInterfaceTypeText ){
        return [ SELECT Interface_Type__c, Implementation_Type__c FROM FFLIB_Service_Config__mdt WHERE Interface_Type__c = :serviceInterfaceTypeText ];
    }

    public List<FFLIB_UOW_Config__mdt> getUnitOfWorkConfigs(){
        return [ SELECT SObjectType__c, SortOrder__c FROM FFLIB_UOW_Config__mdt ORDER BY SortOrder__c, SObjectType__c ];
    }
}