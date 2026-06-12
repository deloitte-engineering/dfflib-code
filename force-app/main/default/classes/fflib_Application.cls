/**
 * Copyright (c), FinancialForce.com, inc
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
 *      may be used to endorse or promote products derived from this software without
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
 * Class provides inner classes implementing factories for the main components of the Apex Enterprise Patterns, Service, Unit Of Work, Selector and Domain.
 * It constructs the factory implementations using a custom metadata-driven approach, removing the need of supplying all compatible SObjectTypes and class implementation on compile time
 *
 * @author     Rafael Fernandes dos Santos (rfernandesdossantos@deloitte.nl)
 * @created    February 2022
 */
public with sharing virtual class fflib_Application{
    // Inner instantiation of the application config class, allowing easy mocking injection in test classes
    public static fflib_ApplicationConfig appConfig{
        get{
            if( appConfig == null ){
                appConfig = new fflib_ApplicationConfig();
            }
            return appConfig;
        }
        set;
    }

    /**
     * Class implements Unit of Work 2.0 factory
     */
    public virtual class UnitOfWorkFactory{
        private fflib_ISObjectUnitOfWork m_mockUow;

        /**
         * Constructs a Unit Of Work factory
         */
        public UnitOfWorkFactory(){}

        /**
         * Constructor for a completely blank fflib_ISObjectUnitOfWork
         */
        public fflib_ISObjectUnitOfWork newInstance(){
            return m_mockUow ?? new fflib_SObjectUnitOfWork();
        }

        /**
         * Constructor for an fflib_ISObjectUnitOfWork with prepopulated SObjectType list.
         * This could be used to deviate from the SortOrder specified in fflib_UOW_Config__mdt
         * Note, when one tries to register a record of an SObjectType nót in this provided list, an Exception will be thrown
         *
         * @param   sObjTypes   Ordered list of SObjectTypes to be allowed in the new UOW instance
         * @return  UnitOfWorkInterface to allow a fluent interface
         */
        public fflib_ISObjectUnitOfWork newInstance( List<SObjectType> sObjTypes ){
            return m_mockUow ?? new fflib_SObjectUnitOfWork( sObjTypes );
        }

        /**
         * Constructor for an fflib_ISObjectUnitOfWork with desired security enforcement
         *
         * @param   securityContext     Security context to be set on new UOW instance
         * @return  UnitOfWorkInterface to allow a fluent interface
         */
        public fflib_ISObjectUnitOfWork newInstance( fflib_Database.Context securityContext ){
            return m_mockUow ?? new fflib_SObjectUnitOfWork( securityContext );
        }

        /**
         * Constructor for an fflib_ISObjectUnitOfWork specifying a pre-populated SObjectType list and a Context
         *
         * @param   sObjTypes           Ordered list of SObjectTypes to be allowed in the new UOW instance
         * @param   securityContext     Security context to be set on new UOW instance
         * @return UnitOfWorkInterface to allow a fluent interface
         */
        public fflib_ISObjectUnitOfWork newInstance( List<SObjectType> sObjTypes, fflib_Database.Context securityContext ){
            return m_mockUow ?? new fflib_SObjectUnitOfWork( sObjTypes, securityContext );
        }

        /**
          * @param mockUow Instance of UnitOfWork class to mock
          * @deprecated Deprecated method as this can be replaced by `defineMock( fflib_ApexMocks mocks );`
          */
        @TestVisible
        private void setMock( fflib_ISObjectUnitOfWork mockUow ){
            m_mockUow = mockUow;
        }

        /**
         * @param mocks ApexMocks to allow constructing the mocked UnitOfWork
         * @return The mocked and applied UnitOfWork class which can be stubbed within `mocks.startStubbing()` and `mocks.stopStubbing()`
         */
        @TestVisible
        private fflib_ISObjectUnitOfWork defineMock( fflib_ApexMocks mocks ){
            fflib_ISObjectUnitOfWork uowMock = new fflib_SObjectMocks.SObjectUnitOfWork( mocks );
            m_mockUow = uowMock;
            return uowMock;
        }
    }

    /**
     * Simple Service Factory implementation.
     */
    public virtual class ServiceFactory{
        protected Map<Type, Type> m_serviceInterfaceTypeByServiceImplType; // Map of interfaces to Service classes
        protected Map<Type, Object> m_serviceInterfaceTypeByMockService; // Map of interfaces to mock instances of Service classes

        /**
         * Constructs a simple Service Factory, using a Map of Apex Interfaces to Apex Classes implementing the interface
         *	Note that this will not check the Apex Classes given actually implement the interfaces
         *	as this information is not presently available via the Apex runtime
         */
        public ServiceFactory(){
            m_serviceInterfaceTypeByMockService = new Map<Type, Object>();
            m_serviceInterfaceTypeByServiceImplType = m_serviceInterfaceTypeByServiceImplType ?? new Map<Type, Type>();
        }

        /**
         * Constructs a new instance of the Apex class associated with the given Apex interface
         *	Will return any mock implementation of the interface provided via setMock
         *	Note that this method will not check the configured Apex class actually implements the interface.
         *
         * @param   serviceInterfaceType    Apex interface type
         * @exception   Is thrown if there is no registered Apex class for the interface type
         * @return  New instance of the Apex class associated with the given Apex interface (or any mock implementation if provided)
         */
        public virtual Object newInstance( Type serviceInterfaceType ){
            // Mock implementation?
            if( m_serviceInterfaceTypeByMockService.containsKey( serviceInterfaceType ) ){
                return m_serviceInterfaceTypeByMockService.get( serviceInterfaceType );
            }

            // Create an instance of the type implementing the given interface
            Type serviceImpl = m_serviceInterfaceTypeByServiceImplType.get( serviceInterfaceType );
            if( serviceImpl == null ){
                // Try to get it from the custom metadata
                String serviceInterfaceTypeText = serviceInterfaceType.toString();
                // Retrieve the Service implementation for the interface type provided
                List<FFLIB_Service_Config__mdt> serviceTypeToImplMapping = appConfig.getServiceConfig( serviceInterfaceTypeText );
                if( !serviceTypeToImplMapping.isEmpty() ){
                    serviceImpl = Type.forName( serviceTypeToImplMapping[ 0 ].Implementation_Type__c );
                    if( serviceImpl == null ){
                        throw new DeveloperException( 'No implementation registered for service interface ' + serviceInterfaceType.getName() );
                    }
                    m_serviceInterfaceTypeByServiceImplType.put( serviceInterfaceType, serviceImpl );
                } else{
                    throw new DeveloperException( 'No implementation registered for service interface ' + serviceInterfaceType.getName() );
                }
            }

            return serviceImpl.newInstance();
        }

        /**
         * @param serviceInterfaceType SObjectType to which the mocked class should be mapped
         * @param serviceImpl Instance of Service class to mock
         * @deprecated Deprecated method as this can be replaced by `defineMock( fflib_ApexMocks mocks, Type classToMock );`
         *      or `defineMock( fflib_ApexMocks mocks, Type classToMock, Type serviceInterfaceType );`
         */
        @TestVisible
        private virtual void setMock( Type serviceInterfaceType, Object serviceImpl ){
            System.debug( System.LoggingLevel.INFO, '*** fflib - Note you can use the simplified `defineMock( fflib_ApexMocks mocks, Type classToMock );`' );
            m_serviceInterfaceTypeByMockService.put( serviceInterfaceType, serviceImpl );
        }

        /**
         * @param mocks ApexMocks to allow constructing the mocked service
         * @param classToMock Service class type to be mocked and map the service class to
         * @return The mocked and applied service class which can be stubbed within `mocks.startStubbing()` and `mocks.stopStubbing()`
         */
        @TestVisible
        private virtual Object defineMock( fflib_ApexMocks mocks, Type classToMock ){
            Object mockedService = mocks.mock( classToMock );
            m_serviceInterfaceTypeByMockService.put( classToMock, mockedService );
            return mockedService;
        }

        /**
         * @param mocks ApexMocks to allow constructing the mocked service
         * @param classToMock Service class type to be mocked
         * @param serviceInterfaceType Optional Interface service class type to allow mapping mocked classes correctly if `IService` is applicable
         * @return The mocked and applied service class which can be stubbed within `mocks.startStubbing()` and `mocks.stopStubbing()`
         */
        @TestVisible
        private virtual Object defineMock( fflib_ApexMocks mocks, Type classToMock, Type serviceInterfaceType ){
            Object mockedService = mocks.mock( classToMock );
            m_serviceInterfaceTypeByMockService.put( serviceInterfaceType, mockedService );
            return mockedService;
        }
    }

    /**
     * Class implements a Selector class factory
     */
    public virtual class SelectorFactory{
        protected Map<SObjectType, Type> m_sObjectBySelectorType; // Map of SObjectType's to Selector Apex Classes
        protected Map<SObjectType, fflib_ISObjectSelector> m_sObjectByMockSelector; // Map of SObjectType's to Selector Apex Class Interfaces for mocking

        /**
         * Constructs a Selector Factory linking SObjectType's with Apex Classes implement the fflib_ISObjectSelector interface
         * Note that the factory does not check the given Apex Classes implement the interface currently this is not possible in Apex
         */
        public SelectorFactory(){
            m_sObjectByMockSelector = new Map<SObjectType, fflib_ISObjectSelector>();
            m_sObjectBySelectorType = m_sObjectBySelectorType ?? new Map<SObjectType, Type>();
        }

        /**
         * Constructs a new instance of the associated Apex Class implementing fflib_ISObjectSelector for the given SObjectType,
         * or if provided via setMock returns the Mock implementation
         *
         * @param   sObjectType     An SObjectType token, e.g. Account.SObjectType
         * @return  New instance of the associated Apex Class or if provided, the Mock implementation
         */
        public virtual fflib_ISObjectSelector newInstance( SObjectType sObjectType ){
            System.debug( LoggingLevel.INFO, 'fflib - No fflib_Database.Context was specified, therefore defaulting to (legacy) INHERIT' );
            return this.newInstance( sObjectType, fflib_Database.Context.INHERIT );
        }

        /**
         * Constructs a new instance of the associated Apex Class implementing fflib_ISObjectSelector for the given SObjectType,
         * or if provided via setMock returns the Mock implementation
         *
         * @param   sObjectType         An SObjectType token, e.g. Account.SObjectType
         * @param   context             Database context for the selector implementation
         * @return  New instance of the associated Apex Class or if provided, the Mock implementation
         */
        public virtual fflib_ISObjectSelector newInstance( SObjectType sObjectType, fflib_Database.Context context ){
            // Mock implementation?
            if( m_sObjectByMockSelector.containsKey( sObjectType ) ){
                return m_sObjectByMockSelector.get( sObjectType );
            }

            // Determine Apex class for Selector class
            Type selectorClass = m_sObjectBySelectorType.get( sObjectType );
            if( selectorClass == null ){
                // Try to get it from the custom metadata
                String selectorSObjectTypeText = String.valueOf( sObjectType );
                // Retrieve the Selector implementation for the SObjectType provided
                List<FFLIB_Selector_Config__mdt> sObjectTypeToImplMapping = appConfig.getSelectorConfig( selectorSObjectTypeText );
                if( !sObjectTypeToImplMapping.isEmpty() ){
                    selectorClass = Type.forName( sObjectTypeToImplMapping[ 0 ].Implementation_Type__c );
                    if( selectorClass == null ){
                        throw new DeveloperException( 'Selector class not found for SObjectType ' + sObjectType );
                    }
                    m_sObjectBySelectorType.put( sObjectType, selectorClass );
                } else{
                    throw new DeveloperException( 'Selector class not found for SObjectType ' + sObjectType );
                }
            }

            // Construct Selector class and set the default database context
            return ( ( fflib_ISObjectSelector ) selectorClass.newInstance() ).setContext( context );
        }

        /**
         * Helper method to query the given SObject records
         * Internally creates an instance of the registered Selector and calls its selectSObjectById method
         *
         * @param       recordIds   The SObject record Ids, must be all the same SObjectType
         * @exception   Is thrown if the record Ids are not all the same or the SObjectType is not registered
         * @return  List<SObject> containing the given SObject records
         */
        public List<SObject> selectById( Set<Id> recordIds ){
            // No point creating an empty Domain class, nor can we determine the SObjectType anyway
            if( recordIds == null || recordIds.size() == 0 ){
                throw new DeveloperException( 'Invalid record Id\'s set' );
            }

            // Determine SObjectType
            SObjectType domainSObjectType = new List<Id>( recordIds )[ 0 ].getSobjectType();
            for( Id recordId : recordIds ){
                if( recordId.getSobjectType() != domainSObjectType ){
                    throw new DeveloperException( 'Unable to determine SObjectType, Set contains Id\'s from different SObject types' );
                }
            }

            // Construct Selector class and query by Id for the records
            return newInstance( domainSObjectType ).selectSObjectsById( recordIds );
        }

        /**
         * Helper method to query related records to those provided, for example
         *	if passed a list of Opportunity records and the Account Id field will
         *	construct internally a list of Account Ids and call the registered
         *	Account selector to query the related Account records, e.g.
         *
         *     List<Account> accounts =
         *        (List<Account>) fflib.Selector.selectByRelationship(myOpps, Opportunity.AccountId);
         *
         * @param   relatedRecords      Used to extract the related record Ids, e.g. Opportunity records
         * @param   relationshipField   Field in the passed records that contains the relationship records to query, e.g. Opportunity.AccountId
         * @return  List<SObject> containing the given SObject records
         */
        public List<SObject> selectByRelationship( List<SObject> relatedRecords, SObjectField relationshipField ){
            Set<Id> relatedIds = new Set<Id>();
            for( SObject relatedRecord : relatedRecords ){
                Id relatedId = ( Id ) relatedRecord.get( relationshipField );
                if( relatedId != null ){
                    relatedIds.add( relatedId );
                }
            }

            return selectById( relatedIds );
        }

        /**
         * @param selectorInstance Instance of SObjectSelector class to mock, note sObjectType() should be mocked already
         * @deprecated Deprecated method as this can be replaced by `defineMock( fflib_ApexMocks mocks, Type classToMock, SObjectType sType );`
         */
        @TestVisible
        private virtual void setMock( fflib_ISObjectSelector selectorInstance ){
            System.debug( System.LoggingLevel.INFO, '*** fflib - Please note your mocked class should have `sObjectType()` stubbed, or use `defineMock( fflib_ApexMocks mocks, Type classToMock, SObjectType sType );`' );
            setMock( selectorInstance.sObjectType(), selectorInstance );
        }

        /**
         * @param sType SObjectType to which the mocked class should be mapped
         * @param selectorInstance Instance of SObjectSelector class to mock, note sObjectType() should be mocked already
         * @deprecated Deprecated method as this can be replaced by `defineMock( fflib_ApexMocks mocks, Type classToMock, SObjectType sType );`
         */
        @TestVisible
        private virtual void setMock( SObjectType sType, fflib_ISObjectSelector selectorInstance ){
            System.debug( System.LoggingLevel.INFO, '*** fflib - Note you can use the simplified `defineMock( fflib_ApexMocks mocks, Type classToMock, SObjectType sType );`' );
            m_sObjectByMockSelector.put( sType, selectorInstance );
        }

        /**
         * @param mocks ApexMocks to allow constructing the mocked selector
         * @param classToMock Selector class type to be mocked
         * @param sType SObjectType to which the mocked selector should be mapped
         * @return The mocked and applied selector class which can be stubbed within `mocks.startStubbing()` and `mocks.stopStubbing()`
         */
        @TestVisible
        private virtual fflib_ISObjectSelector defineMock( fflib_IApexMocks mocks, Type classToMock, SObjectType sType ){
            fflib_ISObjectSelector mockedSelector = ( fflib_ISObjectSelector ) mocks.mock( classToMock );
            m_sObjectByMockSelector.put( sType, mockedSelector );
            return mockedSelector;
        }
    }

    /**
     * Class implements a Domain class factory
     */
    public virtual class DomainFactory{
        protected fflib_Application.SelectorFactory m_selectorFactory;
        protected Map<SObjectType, Type> m_sObjectByDomainConstructorType; // Map of Domain classes by SObjectType
        protected Map<SObjectType, fflib_ISObjectDomain> m_sObjectByMockDomain; // Map of Domain Class Interface by SObjectType for mocking

        /**
         * Constructs a Domain factory, using an instance of the Selector Factory
         *	and a map of Apex classes implementing fflib_ISObjectDomain by SObjectType
         *	Note this will not check the Apex classes provided actually implement the interfaces
         *	since this is not possible in the Apex runtime at present
         *
         * @param	selectorFactory     e.g. Application.Selector
         */
        public DomainFactory( fflib_Application.SelectorFactory selectorFactory ){
            m_selectorFactory = selectorFactory;
            m_sObjectByDomainConstructorType = m_sObjectByDomainConstructorType ?? new Map<SObjectType, Type>();
            m_sObjectByMockDomain = new Map<SObjectType, fflib_ISObjectDomain>();
        }

        /**
         * Dynamically constructs an instance of a Domain class for the given record Ids
         *   Internally uses the Selector Factory to query the records before passing to a
         *   dynamically constructed instance of the application Apex Domain class
         *
         * @param   recordIds   A list of Id's of the same type
         * @exception   Throws an exception via the Selector Factory if the Ids are not all of the same SObjectType
         * @return  fflib_ISObjectDomain instance
         */
        public virtual fflib_ISObjectDomain newInstance( Set<Id> recordIds ){
            return newInstance( m_selectorFactory.selectById( recordIds ) );
        }

        /**
         * Dynamically constructs an instance of the Domain class for the given records
         *	Will return a Mock implementation if one has been provided via setMock
         *
         * @param   records     A concrete list (e.g. List<Account> vs List<SObject>) of records
         * @exception   Throws an exception if the SObjectType cannot be determined from the list or the constructor for Domain class was not registered for the SObjectType
         * @return  fflib_ISObjectDomain instance
         */
        public virtual fflib_ISObjectDomain newInstance( List<SObject> records ){
            SObjectType domainSObjectType = records.getSObjectType();
            if( domainSObjectType == null ){
                throw new DeveloperException( 'Unable to determine SObjectType' );
            }

            // Mock implementation?
            if( m_sObjectByMockDomain.containsKey( domainSObjectType ) ){
                return m_sObjectByMockDomain.get( domainSObjectType );
            }

            // Determine SObjectType and Apex classes for Domain class
            Type domainConstructorClass = m_sObjectByDomainConstructorType.get( domainSObjectType );
            if( domainConstructorClass == null ){
                // Try to get it from the custom metadata
                String domainSObjectTypeText = String.valueOf( domainSObjectType );
                // Retrieve the Domain implementation for the SObjectType provided
                List<FFLIB_Domain_Config__mdt> sObjectTypeToImplMapping = appConfig.getDomainConfig( domainSObjectTypeText );
                if( !sObjectTypeToImplMapping.isEmpty() ){
                    domainConstructorClass = Type.forName( sObjectTypeToImplMapping[ 0 ].Implementation_Type__c );
                    if( domainConstructorClass == null ){
                        throw new DeveloperException( 'Domain constructor class not found for SObjectType ' + domainSObjectType );
                    }
                    m_sObjectByDomainConstructorType.put( domainSObjectType, domainConstructorClass );
                } else{
                    throw new DeveloperException( 'Domain constructor class not found for SObjectType ' + domainSObjectType );
                }
            }

            // Construct Domain class passing in the queried records
            fflib_SObjectDomain.IConstructable domainConstructor = ( fflib_SObjectDomain.IConstructable ) domainConstructorClass.newInstance();
            return ( fflib_ISObjectDomain ) domainConstructor.construct( records );
        }

        /**
         * Dynamically constructs an instance of the Domain class for the given records and SObjectType
         *	Will return a Mock implementation if one has been provided via setMock
         *
         * @param	records				A list records
         * @param	domainSObjectType	SObjectType for list of records
         * @exception   Throws an exception if the SObjectType is not specified or if constructor for Domain class was not registered for the SObjectType
         * @return  fflib_ISObjectDomain instance
         * @remark	Will support List<SObject> but all records in the list will be assumed to be of the type specified in sObjectType
         */
        public virtual fflib_ISObjectDomain newInstance( List<SObject> records, SObjectType domainSObjectType ){
            if( domainSObjectType == null ){
                throw new DeveloperException( 'Must specify sObjectType' );
            }

            // Mock implementation?
            if( m_sObjectByMockDomain.containsKey( domainSObjectType ) ){
                return m_sObjectByMockDomain.get( domainSObjectType );
            }

            // Determine SObjectType and Apex classes for Domain class
            Type domainConstructorClass = m_sObjectByDomainConstructorType.get( domainSObjectType );
            if( domainConstructorClass == null ){
                throw new DeveloperException( 'Domain constructor class not found for SObjectType ' + domainSObjectType );
            }

            // Construct Domain class passing in the queried records
            fflib_SObjectDomain.IConstructable2 domainConstructor = ( fflib_SObjectDomain.IConstructable2 ) domainConstructorClass.newInstance();
            return ( fflib_ISObjectDomain ) domainConstructor.construct( records, domainSObjectType );
        }

        /**
         * @param mockDomain Instance of SObjectDomain class to mock, note sObjectType() should be mocked already
         * @deprecated Deprecated method as this can be replaced by `defineMock( fflib_ApexMocks mocks, Type classToMock, SObjectType sType );`
         */
        @TestVisible
        private virtual void setMock( fflib_ISObjectDomain mockDomain ){
            System.debug( System.LoggingLevel.INFO, '*** fflib - Note your mocked class should have `sObjectType()` stubbed, or use `defineMock( fflib_ApexMocks mocks, Type classToMock, SObjectType sType );`' );
            setMock( mockDomain.sObjectType(), mockDomain );
        }

        /**
         * @param sType SObjectType to which the mocked class should be mapped
         * @param mockDomain Instance of SObjectDomain class to mock
         * @deprecated Deprecated method as this can be replaced by `defineMock( fflib_ApexMocks mocks, Type classToMock, SObjectType sType );`
         */
        @TestVisible
        private virtual void setMock( SObjectType sType, fflib_ISObjectDomain mockDomain ){
            System.debug( System.LoggingLevel.INFO, '*** fflib - Note you can use the simplified `defineMock( fflib_ApexMocks mocks, Type classToMock, SObjectType sType );`' );
            m_sObjectByMockDomain.put( sType, mockDomain );
        }

        /**
         * @param mocks ApexMocks to allow constructing the mocked domain
         * @param classToMock Domain class type to be mocked
         * @param sType SObjectType to which the mocked domain should be mapped
         * @return The mocked and applied domain class which can be stubbed within `mocks.startStubbing()` and `mocks.stopStubbing()`
         */
        @TestVisible
        private virtual fflib_ISObjectDomain defineMock( fflib_IApexMocks mocks, Type classToMock, SObjectType sType ){
            fflib_ISObjectDomain mockedDomain = ( fflib_ISObjectDomain ) mocks.mock( classToMock );
            m_sObjectByMockDomain.put( sType, mockedDomain );
            return mockedDomain;
        }
    }

    public class ApplicationException extends Exception{}

    /**
     * Exception representing a developer coding error, not intended for end user eyes
     */
    public class DeveloperException extends Exception{}
}
