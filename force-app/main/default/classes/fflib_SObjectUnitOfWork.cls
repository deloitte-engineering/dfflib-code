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
 *  fflib_SObjectUnitOfWork 2.0
 *  - Metadata driven, preparing SFDX or complex projects to get rid of centralised-class-conflicts
 *  - Initiating only those items which are requested for performance improvements
 *  - Simplified and extended processing of Relationships within the same transaction
 *
 *  Inspiration based on Apex-Commons repository from FinancialForce.com, Inc
 *
 *  @created   December 2020
 */
/**
 * Provides an implementation of the Enterprise Application Architecture Unit Of Work, as defined by Martin Fowler
 *   http://martinfowler.com/eaaCatalog/unitOfWork.html
 *
 * "You can change the database with each change to your object model, but this can lead to lots of very small database calls,
 *  which ends up being very slow. Furthermore it requires you to have a transaction open for the whole interaction, which is
 *  impractical if you have a business transaction that spans multiple requests. The situation is even worse if you need to
 *  keep track of the objects you've read so you can avoid inconsistent reads."
 *
 * "A Unit of Work keeps track of everything you do during a business transaction that can affect the database. When you're done,
 *  it figures out everything that needs to be done to alter the database as a result of your work."
 *
 * In an Apex context this pattern provides the following specific benefits
 *  - Applies bulkification to DML operations, insert, update and delete
 *  - Manages a business transaction around the work and ensures a rollback occurs (even when exceptions are later handled by the caller)
 *  - Honours dependency rules between records and updates dependent relationships automatically during the commit
 *
 * Please refer to the testMethod's in this class for example usage
 */
public virtual class fflib_SObjectUnitOfWork implements fflib_ISObjectUnitOfWork{
    /**
     * DMLActions - this enum is used to easily share for what DML an SObjectType should be registered
     * Note, prefix of 'd' as NEW and INSERT are restricted values for enums
     */
    public enum DMLActions{
        dNEW, dNEW_PRIO, dNEW_IMMEDIATE,
        dUPDATE, dUPDATE_PRIO, dUPDATE_IMMEDIATE,
        dDELETE, dDELETE_PRIO, dDELETE_IMMEDIATE,
        dUNDELETE,
        dEMPTY_RECBIN,
        dPUB_BEFORE, dPUB_AFTER_SUCCESS, dPUB_AFTER_FAILURE
    }
    public enum Operations{
        PROCESS_APPROVAL_PROCESS, SEND_EMAIL
    }
    private final Set<DMLActions> ACTIONS_DMLOPTIONS = new Set<DMLActions>{ DMLActions.dNEW, DMLActions.dNEW_PRIO, DMLActions.dUPDATE, DMLActions.dUPDATE_PRIO };
    private final Set<DMLActions> ACTIONS_ALLORNONE = new Set<DMLActions>{ DMLActions.dDELETE, DMLActions.dDELETE_PRIO, DMLActions.dUNDELETE };
    private final Set<DMLActions> ACTIONS_EVENTS = new Set<DMLActions>{ DMLActions.dPUB_BEFORE, DMLActions.dPUB_AFTER_SUCCESS, DMLActions.dPUB_AFTER_FAILURE };

    /**
     * List/Map of SObjects by type
     */
    protected Boolean constructorDefinedSObjectTypesList = false;
    protected Boolean constructorDefinedHasWork = false;
    // Ordered list of SObjectTypes which are registered for this UOW, exposed for test-class to validate behaviour
    @TestVisible protected List<Schema.SObjectType> m_sObjectTypes = new List<Schema.SObjectType>();

    @TestVisible protected Map<Schema.SObjectType, List<SObject>> m_newListByType = new Map<Schema.SObjectType, List<SObject>>();
    protected Map<Schema.SObjectType, List<SObject>> m_newImmediateListByType = new Map<Schema.SObjectType, List<SObject>>();
    protected Map<Schema.SObjectType, List<SObject>> m_newPriorityListByType = new Map<Schema.SObjectType, List<SObject>>();

    @TestVisible protected Map<Schema.SObjectType, Map<String, SObject>> m_dirtyMapByType = new Map<Schema.SObjectType, Map<String, SObject>>();
    // No Map, since no later updates on record are allowed after registration
    protected Map<Schema.SObjectType, List<SObject>> m_dirtyImmediateListByType = new Map<Schema.SObjectType, List<SObject>>();
    protected Map<Schema.SObjectType, Map<String, SObject>> m_dirtyPriorityMapByType = new Map<Schema.SObjectType, Map<String, SObject>>();

    protected Map<Schema.SObjectType, List<SObject>> m_deletedListByType = new Map<Schema.SObjectType, List<SObject>>();
    protected Map<Schema.SObjectType, List<SObject>> m_deletedImmediateListByType = new Map<Schema.SObjectType, List<SObject>>();
    protected Map<Schema.SObjectType, List<SObject>> m_deletedPriorityListByType = new Map<Schema.SObjectType, List<SObject>>();

    protected Map<Schema.SObjectType, List<SObject>> m_undeletedListByType = new Map<Schema.SObjectType, List<SObject>>();
    protected Map<Schema.SObjectType, List<SObject>> m_emptyRecycleBinListByType = new Map<Schema.SObjectType, List<SObject>>();

    protected Map<Schema.SObjectType, List<SObject>> m_publishBeforeListByType = new Map<Schema.SObjectType, List<SObject>>();
    protected Map<Schema.SObjectType, List<SObject>> m_publishAfterSuccessListByType = new Map<Schema.SObjectType, List<SObject>>();
    protected Map<Schema.SObjectType, List<SObject>> m_publishAfterFailureListByType = new Map<Schema.SObjectType, List<SObject>>();

    @TestVisible protected Map<Operations, List<Object>> m_operationObjects = new Map<Operations, List<Object>>();

    /**
     * Map of database result classes by SObject types
     */
    // By default ignore SaveResults as it consumes memory and time, while only very few times the Results are requested after commitWork (only relevant when AllOrNone is false)
    @TestVisible private Boolean saveResultsRequired = false;
    private Map<Schema.SObjectType, List<Database.SaveResult>> m_newSaveResults;
    private Map<Schema.SObjectType, List<Database.SaveResult>> m_dirtySaveResults;
    private Map<Schema.SObjectType, List<Database.DeleteResult>> m_deletedSaveResults;
    private Map<Schema.SObjectType, List<Database.UndeleteResult>> m_undeletedSaveResults;
    private Map<Schema.SObjectType, List<Database.EmptyRecycleBinResult>> m_emptyRecycleBinSaveResults;
    private Map<Schema.SObjectType, List<Database.SaveResult>> m_publishSaveResults;
    // Maps linking the above SaveResults per DMLActions; note since only constructed once really needed, this mapping is also within setSaveResultsRequired()
    private Map<DMLActions, Map<Schema.SObjectType, List<Object>>> SAVERESULTS_PER_DMLACTION;
    private Map<Operations, List<Object>> SAVERESULTS_PER_OPERATION;

    /**
     * Storage of Relationships for both SObjectTypes and Objects (based on Operation)
     */
    @TestVisible protected Map<Schema.SObjectType, List<IRelationship>> m_relationships = new Map<Schema.SObjectType, List<IRelationship>>();
    @TestVisible protected Map<Operations, List<IRelationship>> m_relationshipsOperations = new Map<Operations, List<IRelationship>>();

    /**
     * DMLOptions and AllOrNone flags stored per SObjectType
     */
    protected Map<Schema.SObjectType, Database.DMLOptions> m_newDmlOptions = new Map<Schema.SObjectType, Database.DMLOptions>();
    protected Map<Schema.SObjectType, Database.DMLOptions> m_dirtyDmlOptions = new Map<Schema.SObjectType, Database.DMLOptions>();

    protected Map<Schema.SObjectType, Boolean> m_deletedAllOrNone = new Map<Schema.SObjectType, Boolean>();
    protected Map<Schema.SObjectType, Boolean> m_undeletedAllOrNone = new Map<Schema.SObjectType, Boolean>();

    final Map<DMLActions, Map<Schema.SObjectType, Object>> dmlOptionsPerAction = new Map<DMLActions, Map<Schema.SObjectType, Object>>{
        DMLActions.dNEW         => m_newDmlOptions,
        DMLActions.dNEW_PRIO    => m_newDmlOptions,
        DMLActions.dUPDATE      => m_dirtyDmlOptions,
        DMLActions.dUPDATE_PRIO => m_dirtyDmlOptions,
        DMLActions.dDELETE      => m_deletedAllOrNone,
        DMLActions.dDELETE_PRIO => m_deletedAllOrNone,
        DMLActions.dUNDELETE    => m_undeletedAllOrNone
    };

    /**
     * WorkLists
     */
    @TestVisible protected List<IDoWork> m_workList = new List<IDoWork>();

    // Inner interface implementation of fflib_Database_IDML, defines sharing mode for DML operations (default set in constructor)
    @TestVisible
    protected fflib_Database_IDML m_dml;

    // Inner instance of fflib_Database.Context driving sharing mode and FLS/CRUD access level for DML operations (default set in constructor)
    @TestVisible
    private fflib_Database.Context m_securityContext = fflib_Database.Context.INHERIT;

    /**
     * Centralised one-off retrieval for UOW Configs to prevent each new SObjectType to result in a metadata-query
     * Performing SOQL inline as UOW is often constructed before Selectors are available
     */
    @TestVisible
    private static List<FFLIB_UOW_Config__mdt> uowConfigs{
        get{
            if( uowConfigs == null ){
                uowConfigs = fflib_Application.appConfig.getUnitOfWorkConfigs();
            }
            return uowConfigs;
        }
        set;
    }

    /**
     * Method to enable Maps for newly requested DMLAction-SObjectType combi
     * - First verify whether DMLAction is allowed for requested SObjectType
     * - Check whether SObjectType is known in current UOW, else check metadata for correct order
     * - Initiate DMLAction-SObjectType corresponding maps
     * @param sObjType  Requested SObjectType to initiate Maps for
     * @param dmlAction Requested DMLAction to initiate Maps for
     */
    @TestVisible private void implementSObjectType( Schema.SObjectType sObjType, DMLActions dmlAction ){
        // First validate whether this SObjectType is allowed for this DMLAction (e.g. PlatformEvents should use Publish DML Actions)
        checkDMLActionAllowedForSObjectType( dmlAction, sObjType );

        if( !m_sObjectTypes.contains( sObjType ) ){
            // Query metadata and ensure m_sObjectTypes is satisfying metadata order
            addSObjectTypeInCorrectOrder( sObjType );
        } else if( constructorDefinedSObjectTypesList ){
            constructorDefinedHasWork = true;
        }

        // Add SObjectType to relevant Map to prevent too much overhead
        switch on dmlAction{
            when dNEW{
                m_newListByType.put( sObjType, new List<SObject>() );
            }
            when dNEW_IMMEDIATE{
                m_newImmediateListByType.put( sObjType, new List<SObject>() );
            }
            when dNEW_PRIO{
                m_newPriorityListByType.put( sObjType, new List<SObject>() );
            }
            when dUPDATE{
                m_dirtyMapByType.put( sObjType, new Map<String, SObject>() );
            }
            when dUPDATE_IMMEDIATE{
                m_dirtyImmediateListByType.put( sObjType, new List<SObject>() );
            }
            when dUPDATE_PRIO{
                m_dirtyPriorityMapByType.put( sObjType, new Map<String, SObject>() );
            }
            when dDELETE{
                m_deletedListByType.put( sObjType, new List<SObject>() );
                m_deletedAllOrNone.put( sObjType, true );
            }
            when dDELETE_IMMEDIATE{
                m_deletedImmediateListByType.put( sObjType, new List<SObject>() );
            }
            when dDELETE_PRIO{
                m_deletedPriorityListByType.put( sObjType, new List<SObject>() );
                m_deletedAllOrNone.put( sObjType, true );
            }
            when dUNDELETE{
                m_undeletedListByType.put( sObjType, new List<SObject>() );
                m_undeletedAllOrNone.put( sObjType, true );
            }
            when dEMPTY_RECBIN{
                m_emptyRecycleBinListByType.put( sObjType, new List<SObject>() );
            }
            when dPUB_BEFORE{
                m_publishBeforeListByType.put( sObjType, new List<SObject>() );
            }
            when dPUB_AFTER_SUCCESS{
                m_publishAfterSuccessListByType.put( sObjType, new List<SObject>() );
            }
            when dPUB_AFTER_FAILURE{
                m_publishAfterFailureListByType.put( sObjType, new List<SObject>() );
            }
            when else{
                System.debug( LoggingLevel.ERROR, 'fflib - DMLAction ' + dmlAction + ' was not registered as valid action' );
            }
        }
    }

    /**
     * Validate if the SObjectType is allowed for Event Register and supported by Unit Of Work
     *
     * @param   action      Type of DMLAction to be performed
     * @param   sObjType    Type of SObject
     */
    private void checkDMLActionAllowedForSObjectType( DMLActions action, Schema.SObjectType sObjType ){
        String sObjectTypeName = sObjType.getDescribe().getName();
        Boolean isPlatformEventSObject = isPlatformEvent( sObjectTypeName );
        Boolean isPlatformEventAction = ACTIONS_EVENTS.contains( action );

        if( isPlatformEventSObject && !isPlatformEventAction ){
            throw new UnitOfWorkException( 'PlatformEvents like ' + sObjectTypeName + ' should be registered via a registerPublish...() method' );
        } else if( !isPlatformEventSObject && isPlatformEventAction ){
            throw new UnitOfWorkException( 'Records with SObjectType like ' + sObjectTypeName + ' are not allowed to be registered for publish, but should use registerNew() and such' );
        }
    }

    /**
     * Method to centralize logic to determine if an SObjectType is a PlatformEvent
     * - Detect custom platform events, ending by __e
     * - Detect standard events, ending by Event, but exclude Event object
     *   (detecting by length, given better performance compared to 'equals Event')
     *
     * @param   String     Textual representation of SObjectType
     * @return  Boolean that if true, SObjectType is Platform Type
     */
    @TestVisible private static final Map<String, Boolean> platformEventCache = new Map<String, Boolean>();
    private Boolean isPlatformEvent( String sObjTypeName ){
        if( !platformEventCache.containsKey( sObjTypeName ) ){
            platformEventCache.put( sObjTypeName,
                ( sObjTypeName.endsWith( '__e' )
                || ( sObjTypeName.endsWith( 'Event' ) && sObjTypeName.length() > 5 ) ) );
        }
        return platformEventCache.get( sObjTypeName );
    }

    /**
     * Method to check the FFLIB_UOW_Config__mdt for SortOrder and whether or not SObjectType is defined and update order properly
     */
    // Set of Strings to allow more efficient comparison with fflib_UOW_Config__mdt SObjectType (String) on whether it is already part of this UnitOfWork
    // This also avoids the need to transform Config SObjectType strings to SObjectTypes which could cause issues for restricted/licensed objects like Knowledge__kav for users without access
    private Set<String> m_sObjectTypesStrings = new Set<String>();
    private void addSObjectTypeInCorrectOrder( Schema.SObjectType sObjType ){
        // Determine String of SObjectType to allow easier and more efficient fflib_UOW_Config__mdt comparison and logging
        String sObjTypeString = String.valueOf( sObjType );
        if( constructorDefinedSObjectTypesList ){
            throw new UnitOfWorkException(
                'SObjectType ' + sObjTypeString + ' was not specified in the Constructor-list. '
                    + 'Either migrate to use fflib_UOW_Config__mdt, or add this SObjectType to the Constructor-list.'
            );
        }

        // Loop over UOW Configs to determine whether the new SObjectType is allowed/exists and what index it should be added
        Boolean foundInConfig = false;
        Integer numImplementedSObjectTypes = 0;
        for( Integer i = 0, j = uowConfigs.size(); i < j; i++ ){
            String configSObjTypeString = uowConfigs[ i ].SObjectType__c;

            // If loop-Config matches requested SObjectType, stop for-loop
            if( configSObjTypeString.equalsIgnoreCase( sObjTypeString ) ){
                foundInConfig = true;
                break;
            }
            // If loop-Config didn't match but is already implemented in this UOW, increase counter
            if( m_sObjectTypesStrings.contains( configSObjTypeString ) ){
                numImplementedSObjectTypes++;
            }
        }
        // If the requested SObjectType isn't setup, throw Exception
        if( !foundInConfig ){
            throw new UnitOfWorkException( 'SObjectType ' + sObjTypeString + ' is not (yet) registered for this Unit of Work.' +
                'You can insert a fflib_UOW_Config__mdt or specify this in the Constructor (fflib.unitOfWork.newInstance( new List<SObjectType>{ ... }, fflib_Database.Context.FULL ); )' );
        }

        // In the loop a counter was kept of the number of SObjectType sequentially occurring before the new requested SObjectType
        // When 4 SObjectTypes already registered in this UOW and all counted in the Config loop BEFORE the requested SObjectType (n=4) => add the new SObjectType last
        // When 5 SObjectTypes already registered, but only 3 counted BEFORE the new SObjectType => add the new SObjectType after 3rd (as 4th on index 3)
        if( numImplementedSObjectTypes == m_sObjectTypes.size() ){
            m_sObjectTypes.add( sObjType );
        } else{
            m_sObjectTypes.add( numImplementedSObjectTypes, sObjType );
        }
        // Also keep track of SObjectType in String to prevent conversion from SObjectType in Config (String) to SObjectType for comparisons
        m_sObjectTypesStrings.add( sObjTypeString );
    }

    /**
     * Constructs a new Unit Of Work with the default Inherit database context and based on metadata-SObjectTypes
     */
    public fflib_SObjectUnitOfWork(){
        this( null, fflib_Database.Context.INHERIT );
    }

    /**
     * Constructs a new Unit Of Work with pre-defined SObjectTypes list to deviate from fflib_UOW_Config__mdt SortOrder
     * Note, when using this option, an Exception is thrown when a record is registered which is not listed in this Constructor-list.
     * @param sObjTypes List of SObjectTypes to be registered for this Unit Of Work
     */
    public fflib_SObjectUnitOfWork( List<SObjectType> sObjTypes ){
        this( sObjTypes, fflib_Database.Context.INHERIT );
    }

    /**
     * Constructs a new Unit Of Work with specified database security model
     * @param securityContext Database Context to be applied for all records and operations within this Unit Of Work
     */
    public fflib_SObjectUnitOfWork( fflib_Database.Context securityContext ){
        this( null, securityContext );
    }

    /**
     * Constructs a new Unit Of Work with specified database security model and pre-defined SObjectTypes list to deviate from fflib_UOW_Config__mdt (SortOrder)
     * @param sObjTypes       List of SObjectTypes to be registered for this Unit Of Work
     * @param securityContext Database Context to be applied for all records and operations within this Unit Of Work
     */
    public fflib_SObjectUnitOfWork( List<SObjectType> sObjTypes, fflib_Database.Context securityContext ){
        if( sObjTypes != null ){
            // Validate no duplicate SObjectTypes provided in list, by converting to Set which only keeps unique values
            if( ( new Set<Schema.SObjectType>( sObjTypes ) ).size() != sObjTypes.size() ){
                throw new UnitOfWorkException( 'Duplicate SObjectType defined within provided List of SObjectTypes' );
            }
            m_sObjectTypes = sObjTypes.clone();
            constructorDefinedSObjectTypesList = true;
        }
        setContext( securityContext );
    }

    /**
     * Setter to allow changing the database security context when committing records to the database. The default is INHERIT (no FLS/CRUD checks) to match the sharing model used in the calling class, otherwise use this
     * method to be explicit on which sharing model should be used
     *
     * @param   securityContext     Sharing mode to be used in this unit of work
     */
    public void setContext( fflib_Database.Context securityContext ){
        this.m_securityContext = securityContext;
        this.m_dml = fflib_Database.getDMLProxy( securityContext );
    }

    /**
     * Verification method to check whether Record is valid for requested Action.
     * Main check is whether Id is known for Updates, Deletes and Undeletes and no Id is set for Inserts
     *
     * @param record    Record requested for DML Action
     * @param action    DMLAction requested for record
     * @param sObjType  ONLY for Update-With-Registration-DMLActions: SObjectType to check current registerNew() records for that SObjectType
     */
    public void validateRecordForDMLAction( SObject record, DMLActions action ){
        this.validateRecordForDMLAction( record, action, null );
    }
    public void validateRecordForDMLAction( SObject record, DMLActions action, Schema.SObjectType sObjType ){
        switch on action{
            when dNEW_PRIO, dNEW, dNEW_IMMEDIATE{
                if( String.isNotBlank( record?.Id ) ){
                    throw new UnitOfWorkException( 'Only new records can be registered as new' );
                }
            }
            when dUPDATE_PRIO, dUPDATE, dUPDATE_IMMEDIATE{
                if( String.isBlank( record?.Id ) ){
                    // Scenario: Allow setting a parent Lookup to a child (1:1 relation, e.g. Account.Primary_Contact__c) in same transaction as both inserts
                    // `sObjType` should ONLY be provided in registerDirty-withRelationship, else record is required to have an Id to update
                    // Reason: Prevention of (accidental) misuse causing unexpected behaviour, only if developer is certain of use-case we can deviate
                    // 1) registerNew( record ) registers reference, so any later update `record.Field1__c = 'abc'` is already included at insert
                    //    Only possible change between inserted and updated record is when resolving a relationship
                    // 2) registerDirty() registers references based on record.Id, for this scenario we introduced random-string-map-key,
                    //    but this still leaves risk of unexpected behaviour when registerDirty is called multiple times for same record without id
                    if( sObjType == null ){
                        throw new UnitOfWorkException( 'New records cannot be registered as dirty' );
                    } else{
                        // When record has no SF Id (yet), but should have a relation resolved, verify whether record was registeredNew within this UOW
                        // If so, record.Id will be available on update, as this is defined after insert, which always happen before update
                        List<SObject> registeredForPriorityInsert = m_newPriorityListByType.get( sObjType );
                        List<SObject> registerForImmediateInsert = ( action == DMLActions.dUPDATE_IMMEDIATE || action == DMLActions.dUPDATE ) ? m_newImmediateListByType.get( sObjType ) : null;
                        List<SObject> registerForInsert = ( action == DMLActions.dUPDATE ) ? m_newListByType.get( sObjType ) : null;
                        // When record is NOT registered for Insert in this UOW, throw Exception as Id will not be known at Database.update()
                        if( ( registeredForPriorityInsert == null || !registeredForPriorityInsert.contains( record ) )
                            && ( registerForImmediateInsert == null || !registerForImmediateInsert.contains( record ) )
                            && ( registerForInsert == null || !registerForInsert.contains( record ) ) ){
                            throw new UnitOfWorkException( 'New records cannot be registered as dirty, or should be registeredNew() before calling registerDirty()' );
                        }
                    }
                }
            }
            when dDELETE_PRIO, dDELETE, dDELETE_IMMEDIATE,
                dUNDELETE{
                if( String.isBlank( record.Id ) ){
                    throw new UnitOfWorkException( 'New records cannot be registered for ' + action );
                }
            }
            when else{
                throw new UnitOfWorkException( 'No matching DMLAction' );
            }
        }
    }

    /**
     * For specific scenarios you may wish to register new records to be inserted into the database before other records
     * within the same transaction are inserted to enable relationships to be populated correctly. E.g. inserting a
     * parent and child record of the same sObject type could not be linked together in the same unit of work otherwise.
     *
     * @param   record  A newly created SObject instance to be inserted during commitWork
     */
    public void registerPriorityNew( SObject record ){
        registerPriorityNew( record, null, null );
    }
    public void registerPriorityNew( List<SObject> records ){
        for( Integer i = 0, j = records.size(); i < j; i++ ){
            this.registerPriorityNew( records[ i ] );
        }
    }
    public void registerPriorityNew( SObject record, Schema.SObjectField relatedToParentField, SObject relatedToParentRecord ){
        validateRecordForDMLAction( record, DMLActions.dNEW_PRIO );

        Schema.SObjectType sObjType = record.getSObjectType();
        if( !m_newPriorityListByType.containsKey( sObjType ) ){
            implementSObjectType( sObjType, DMLActions.dNEW_PRIO );
        }
        m_newPriorityListByType.get( sObjType ).add( record );

        // @todo: WARNING to ONLY allow registration when the relatedParentRecord SObjectType is BEFORE in m_sObjectType when also in registration..
        if( relatedToParentRecord != null && relatedToParentField != null ){
            registerRelationship( record, relatedToParentField, relatedToParentRecord, DMLActions.dNEW_PRIO );
        }
    }

    /**
     * Register a newly created SObject instance to be inserted during commitWork()
     *
     * @param   record  A newly created SObject instance to be inserted during commitWork
     */
    public void registerNew( SObject record ){
        registerNew( record, null, null );
    }
    public void registerNew( List<SObject> records ){
        for( Integer i = 0, j = records.size(); i < j; i++ ){
            registerNew( records[ i ], null, null );
        }
    }

    /**
     * Register a newly created SObject instance to be inserted when commitWork is called, you may also provide a reference
     * to the parent record instance (should also be registered as new separately)
     *
     * @param   record                  A newly created SObject instance to be inserted during commitWork
     * @param   relatedToParentField    A SObjectField reference to the child field that associates the child record with its parent
     * @param   relatedToParentRecord   A SObject instance of the parent record (should also be registered as new separately)
     */
    public void registerNew( SObject record, Schema.SObjectField relatedToParentField, SObject relatedToParentRecord ){
        validateRecordForDMLAction( record, DMLActions.dNEW );

        Schema.SObjectType sObjType = record.getSObjectType();
        if( !m_newListByType.containsKey( sObjType ) ){
            implementSObjectType( sObjType, DMLActions.dNEW );
        }
        m_newListByType.get( sObjType ).add( record );

        if( relatedToParentRecord != null && relatedToParentField != null ){
            registerRelationship( record, relatedToParentField, relatedToParentRecord, DMLActions.dNEW );
        }
    }

    /**
     * Method to register records to be inserted using Database.insertImmediate();
     * This is used for external, Big or special Objects (like ThirdPartyAccountLinks)
     *
     * @param record An instance of an External, Big or Special object to be inserted immediately
     */
    public void registerNewImmediate( SObject record ){
        validateRecordForDMLAction( record, DMLActions.dNEW_IMMEDIATE );

        Schema.SObjectType sObjType = record.getSObjectType();
        if( !m_newImmediateListByType.containsKey( sObjType ) ){
            implementSObjectType( sObjType, DMLActions.dNEW_IMMEDIATE );
        }
        m_newImmediateListByType.get( sObjType ).add( record );
    }
    public void registerNewImmediate( List<SObject> records ){
        for( Integer i = 0, j = records.size(); i < j; i++ ){
            this.registerNewImmediate( records[ i ] );
        }
    }

    /**
     * For specific scenarios you may wish to register records to be updated into the database before other records
     * within the same transaction are inserted to enable standard required to be populated correctly.
     *
     * @param   record  A existing SObject instance to be updated during commitWork
     */
    public void registerPriorityDirty( SObject record ){
        registerPriorityDirty( record, null, null );
    }
    public void registerPriorityDirty( List<SObject> records ){
        for( Integer i = 0, j = records.size(); i < j; i++ ){
            this.registerPriorityDirty( records[ i ] );
        }
    }
    public void registerPriorityDirty( SObject record, Schema.SObjectField relatedToParentField, SObject relatedToParentRecord ){
        Schema.SObjectType sObjType = record.getSObjectType();
        // On registry of updates with relations we allow records inserted in same transaction, else, each record should have an Id
        // To prevent an additional getSObjectType() in validateRecordForDMLAction(), condition is put on this place to save extra action
        validateRecordForDMLAction( record, DMLActions.dUPDATE_PRIO, sObjType );

        if( !m_dirtyPriorityMapByType.containsKey( sObjType ) ){
            implementSObjectType( sObjType, DMLActions.dUPDATE_PRIO );
        }

        // record.Id might be null (see validateRecordForDMLAction() ), then guarantee unique Map-key to prevent overwriting UOW workload
        String mapIdentifier = String.isNotBlank( record.Id ) ? String.valueOf( record.Id ) : String.valueOf( Math.round( Math.random() * 100 ) + '' + System.now().getTime() );
        m_dirtyPriorityMapByType.get( sObjType ).put( mapIdentifier, record );
        if( relatedToParentRecord != null && relatedToParentField != null ){
            registerRelationship( record, relatedToParentField, relatedToParentRecord, DMLActions.dUPDATE_PRIO );
        }
    }

    /**
     * Register an existing record to be updated during commitWork()
     *
     * @param   record      An existing record
     */
    public void registerDirty( SObject record ){
        registerDirty( record, null, null, null );
    }
    public void registerDirty( List<SObject> records ){
        for( Integer i = 0, j = records.size(); i < j; i++ ){
            this.registerDirty( records[ i ] );
        }
    }

    /**
     * Register specific fields on an existing record to be updated during commitWork()
     *
     * When called after registerDirty(record), only the specified fields are enriched on the already registered record
     * When called first time, a new clean instance is made and only the specified fields are populated
     * When called followed by registerDirty(record), an exception is thrown, due to mismatch in memory reference.
     * NOTE: no reference is kept in this function. When applying registerDirty( record, fields ), then altering the input record,
     *      one will have to call registerDirty( fields ) again to make sure those changes are included in the commitWork
     *
     * @param   record              An existing record
     * @param   dirtyFields         The list of fields to be updated only
     */
    public void registerDirty( SObject record, List<SObjectField> dirtyFields ){
        this.registerDirty( record, dirtyFields, null, null );
    }
    public void registerDirty( List<SObject> records, List<SObjectField> dirtyFields ){
        for( Integer i = 0, j = records.size(); i < j; i++ ){
            this.registerDirty( records[ i ], dirtyFields );
        }
    }

    /**
     * Register an existing record to be updated, while ensuring a reference/lookup is populated before performing the update
     * Allowing a parent record to be inserted by the same UOW as the child record to be referenced to
     *
     * @param   record                  The SObject instance to be updated
     * @param   relatedToParentField    The SObjectField reference to the field that associates the child record with its parent
     * @param   relatedToParentRecord   The SObject instance of the parent record (should be registered as new separately!)
     */
    public void registerDirty( SObject record, Schema.SObjectField relatedToParentField, SObject relatedToParentRecord ){
        this.registerDirty( record, null, relatedToParentField, relatedToParentRecord );
    }

    /**
     * Method to allow registering only some of the record variables fields, while also referencing a relationship to be resolved
     * Method mainly introduced to centralize both logics for dirtyFields and relationshipFields to ensure all checks are performed in all cases
     *
     * @param record                    The SObject instance to be updated
     * @param dirtyFields               Opt. list of SObjectFields specifying which fields to update in the database
     * @param relatedToParentField      Opt. SObjectField detailing the relation from this SObjectType to the parent (lookup) to populate
     * @param relatedToParentRecord     Opt. SObject referring to the parent record, which should be registeredNew separately to retrieve an ID in the UOW before update
     */
    public void registerDirty( SObject record, List<SObjectField> dirtyFields, Schema.SObjectField relatedToParentField, SObject relatedToParentRecord ){
        // Validate whether the record is allowed to be registered for update (e.g. having recordId, or inserted in same transaction)
        // Note, to allow partial records (dirtyFields) the recordId should already be known, since a clone is made and no later update is then possible
        // Therefore, when dirtyFields are provided, the record.Id should be populated, else an Exception is thrown
        Schema.SObjectType sObjType = record.getSObjectType();
        Boolean dirtyFieldsProvided = dirtyFields != null && !dirtyFields.isEmpty();
        validateRecordForDMLAction( record, DMLActions.dUPDATE, ( ( dirtyFieldsProvided ) ? null : sObjType ) );

        if( !m_dirtyMapByType.containsKey( sObjType ) ){
            implementSObjectType( sObjType, DMLActions.dUPDATE );
        }

        // Fetch all yet registered records of same SObjectType for local variable efficiency
        Map<String, SObject> registeredSObjects = m_dirtyMapByType.get( sObjType );
        if( dirtyFieldsProvided ){
            // If dirty fields are specified and record Id wasn't known, register clean SObject to make sure only dirty fields get populated
            if( !registeredSObjects.containsKey( record.Id ) ){
                registeredSObjects.put( record.Id, record.getSObjectType().newSObject( record.Id ) );
            }
            // Fetch either already existing reference, or newly created clone
            SObject registeredRecord = registeredSObjects.get( record.Id );

            // Loop over provided fields to extend registered record with new field input
            for( Integer i = 0, j = dirtyFields.size(); i < j; i++ ){
                SObjectField dirtyField = dirtyFields[ i ];
                registeredRecord.put( dirtyField, record.get( dirtyField ) );
            }

        } else{
            SObject registeredRecord = registeredSObjects.get( record.Id );
            if( registeredRecord == null ){
                // If no dirtyFields are specified and record wasn't registered yet, register full record
                // Note, record.Id might be null (see validateRecordForDMLAction() ), then guarantee unique Map-key to prevent overwriting UOW workload
                String mapIdentifier = String.isNotBlank( record.Id ) ? String.valueOf( record.Id ) : String.valueOf( Math.round( Math.random() * 100 ) + '' + System.now().getTime() );
                registeredSObjects.put( mapIdentifier, record );

            } else if( registeredRecord !== record ){
                // Validate whether provided instance is different and NO fields are provided
                // System cannot determine what changes to make (assuming updating nothing is incorrect)
                throw new UnitOfWorkException( 'Cannot determine what fields to update on record ' + record );
            }
        }

        // Regardless of dirtyFields or not, register relationship when input is provided
        if( relatedToParentRecord != null && relatedToParentField != null ){
            registerRelationship( record, relatedToParentField, relatedToParentRecord, DMLActions.dUPDATE );
        }
    }

    /**
     * Method to register records to be updated using Database.updatedImmediate();
     * This is used for external, Big or special Objects (like ThirdPartyAccountLinks)
     *
     * @param record An instance of an External, Big or Special object to be updated immediately
     */
    public void registerDirtyImmediate( SObject record ){
        validateRecordForDMLAction( record, DMLActions.dUPDATE_IMMEDIATE );

        Schema.SObjectType sObjType = record.getSObjectType();
        if( !m_dirtyImmediateListByType.containsKey( sObjType ) ){
            implementSObjectType( sObjType, DMLActions.dUPDATE_IMMEDIATE );
        }
        m_dirtyImmediateListByType.get( sObjType ).add( record );
    }
    public void registerDirtyImmediate( List<SObject> records ){
        for( Integer i = 0, j = records.size(); i < j; i++ ){
            this.registerDirtyImmediate( records[ i ] );
        }
    }

    /**
     * Register a new or existing record to be inserted/updated during commitWork()
     *
     * @param   record      A new or existing record
     */
    public void registerUpsert( SObject record ){
        if( String.isBlank( record.Id ) ){
            this.registerNew( record, null, null );
        } else{
            this.registerDirty( record );
        }
    }
    public void registerUpsert( List<SObject> records ){
        for( Integer i = 0, j = records.size(); i < j; i++ ){
            this.registerUpsert( records[ i ] );
        }
    }

    /**
     * For specific scenarios you may wish to register records to be deleted into the database before other records
     * within the same transaction are inserted/Updated to enable standard required to be populated correctly.
     *
     * @param record An existing record to be deleted
     **/
    public void registerPriorityDeleted( SObject record ){
        validateRecordForDMLAction( record, DMLActions.dDELETE_PRIO );

        Schema.SObjectType sObjType = record.getSObjectType();
        if( !m_deletedPriorityListByType.containsKey( sObjType ) ){
            implementSObjectType( sObjType, DMLActions.dDELETE_PRIO );
        }

        m_deletedPriorityListByType.get( sObjType ).add( record );
    }
    public void registerPriorityDeleted( List<SObject> records ){
        for( Integer i = 0, j = records.size(); i < j; i++ ){
            this.registerPriorityDeleted( records[ i ] );
        }
    }

    /**
     * Register an existing record to be deleted during the commitWork method
     *
     * @param   record      An existing record to be deleted
     */
    public void registerDeleted( SObject record ){
        validateRecordForDMLAction( record, DMLActions.dDELETE );

        Schema.SObjectType sObjType = record.getSObjectType();
        if( !m_deletedListByType.containsKey( sObjType ) ){
            implementSObjectType( sObjType, DMLActions.dDELETE );
        }
        m_deletedListByType.get( sObjType ).add( record );
    }
    public void registerDeleted( List<SObject> records ){
        for( Integer i = 0, j = records.size(); i < j; i++ ){
            this.registerDeleted( records[ i ] );
        }
    }

    /**
     * Method to register records to be deleted using Database.deleteImmediate();
     * This is used for external, Big or special Objects (like ThirdPartyAccountLinks)
     *
     * @param record An instance of an External, Big or Special object to be deleted immediately
     */
    public void registerDeletedImmediate( SObject record ){
        validateRecordForDMLAction( record, DMLActions.dDELETE_IMMEDIATE );

        Schema.SObjectType sObjType = record.getSObjectType();
        if( !m_deletedImmediateListByType.containsKey( sObjType ) ){
            implementSObjectType( sObjType, DMLActions.dDELETE_IMMEDIATE );
        }
        m_deletedImmediateListByType.get( sObjType ).add( record );
    }
    public void registerDeletedImmediate( List<SObject> records ){
        for( Integer i = 0, j = records.size(); i < j; i++ ){
            this.registerDeletedImmediate( records[ i ] );
        }
    }

    /**
     * Register a list of existing records to be deleted and removed from the recycle bin during commitWork()
     *
     * @param   record      An existing record to be permanently deleted and thus directly removed from recycle bin
     */
    public void registerPermanentlyDeleted( SObject record ){
        this.registerDeleted( record );
        this.registerEmptyRecycleBin( record );
    }
    public void registerPermanentlyDeleted( List<SObject> records ){
        for( Integer i = 0, j = records.size(); i < j; i++ ){
            this.registerPermanentlyDeleted( records[ i ] );
        }
    }

    /**
     * Register an deleted record to be removed from the recycle bin during commitWork()
     *
     * @param  record      An existing record to be removed from recycle bin
     */
    public void registerEmptyRecycleBin( SObject record ){
        Schema.SObjectType sObjType = record.getSObjectType();
        if( !m_emptyRecycleBinListByType.containsKey( sObjType ) ){
            implementSObjectType( sObjType, DMLActions.dEMPTY_RECBIN );
        }
        m_emptyRecycleBinListByType.get( sObjType ).add( record );
    }
    public void registerEmptyRecycleBin( List<SObject> records ){
        for( Integer i = 0, j = records.size(); i < j; i++ ){
            registerEmptyRecycleBin( records[ i ] );
        }
    }

    /**
     * Register an existing record to be undeleted during commitWork()
     *
     * @param record A deleted record which should be 'undeleted'/'reverted'
     */
    public void registerUndeleted( SObject record ){
        validateRecordForDMLAction( record, DMLActions.dUNDELETE );

        Schema.SObjectType sObjType = record.getSObjectType();
        if( !m_undeletedListByType.containsKey( sObjType ) ){
            implementSObjectType( sObjType, DMLActions.dUNDELETE );
        }
        m_undeletedListByType.get( sObjType ).add( record );
    }
    public void registerUndeleted( List<SObject> records ){
        for( Integer i = 0, j = records.size(); i < j; i++ ){
            this.registerUndeleted( records[ i ] );
        }
    }

    /**
     * Register a newly created SObject (Platform Event) instance to be published during commitWork()
     *
     * @param   record  A newly created SObject (Platform Event) instance to be inserted during commitWork
     */
    public void registerPublishBeforeTransaction( SObject record ){
        Schema.SObjectType sObjType = record.getSObjectType();
        if( !m_publishBeforeListByType.containsKey( sObjType ) ){
            implementSObjectType( sObjType, DMLActions.dPUB_BEFORE );
        }

        m_publishBeforeListByType.get( sObjType ).add( record );
    }
    public void registerPublishBeforeTransaction( List<SObject> records ){
        for( Integer i = 0, j = records.size(); i < j; i++ ){
            this.registerPublishBeforeTransaction( records[ i ] );
        }
    }

    /**
     * Register a newly created SObject (Platform Event) instance to be published during commitWork()
     *
     * @param   record      A newly created SObject (Platform Event) instance to be inserted during commitWork
     */
    public void registerPublishAfterFailureTransaction( SObject record ){
        Schema.SObjectType sObjType = record.getSObjectType();
        if( !m_publishAfterFailureListByType.containsKey( sObjType ) ){
            implementSObjectType( sObjType, DMLActions.dPUB_AFTER_FAILURE );
        }

        m_publishAfterFailureListByType.get( sObjType ).add( record );
    }
    public void registerPublishAfterFailureTransaction( List<SObject> records ){
        for( Integer i = 0, j = records.size(); i < j; i++ ){
            this.registerPublishAfterFailureTransaction( records[ i ] );
        }
    }

    /**
     * Register a newly created SObject (Platform Event) instance to be published when commitWork is called
     *
     * @param   record      A newly created SObject (Platform Event) instance to be inserted during commitWork
     */
    public void registerPublishAfterSuccessTransaction( SObject record ){
        Schema.SObjectType sObjType = record.getSObjectType();
        if( !m_publishAfterSuccessListByType.containsKey( sObjType ) ){
            implementSObjectType( sObjType, DMLActions.dPUB_AFTER_SUCCESS );
        }

        m_publishAfterSuccessListByType.get( sObjType ).add( record );
    }
    public void registerPublishAfterSuccessTransaction( List<SObject> records ){
        for( Integer i = 0, j = records.size(); i < j; i++ ){
            this.registerPublishAfterSuccessTransaction( records[ i ] );
        }
    }

    /**
     * Register a generic piece of work to be invoked during commitWork()
     *
     * @param work  A class instance which implements IDoWork interface and should be executed at the end of commitWork()
     */
    public void registerWork( IDoWork work ){
        m_workList.add( work );
    }

    /**
     * Register a given email to be send during commitWork()
     *
     * @param email     Messaging.Email or Messaging.SingleEmailMessage instance to be send
     */
    public void registerEmail( Messaging.Email email ){
        List<Object> emailsRegistered = m_operationObjects.get( Operations.SEND_EMAIL );
        if( emailsRegistered == null ){
            m_operationObjects.put( Operations.SEND_EMAIL, new List<Object>{ email } );
        } else{
            emailsRegistered.add( email );
        }
    }

    /**
     * Register a given SingleEmailMessage and directly link record to a provided WhatId
     * Note, WhatId can only be set for SingleEmailMessages, hence bit different method-signature
     *
     * @param email     Messaging.SingleEmailMessage instance to be send
     * @param relatedTo An SObject instance to be set as WhatId on the email
     */
    public void registerEmail( Messaging.SingleEmailMessage email, SObject relatedTo ){
        this.registerEmail( email );
        this.registerRelationship( email, relatedTo );
    }

    /**
     * Register an Approval Process Request to be submitted, approved or rejected
     *
     * @param process   Either a ProcessSubmitRequest or ProcessWorkitemRequest to be processed
     */
    public void registerApprovalProcess( Approval.ProcessRequest process ){
        List<Object> approvalsRegistered = m_operationObjects.get( Operations.PROCESS_APPROVAL_PROCESS );
        if( approvalsRegistered == null ){
            m_operationObjects.put( Operations.PROCESS_APPROVAL_PROCESS, new List<Object>{ process } );
        } else{
            approvalsRegistered.add( process );
        }
    }

    /**
     * Register an Approval Process Request to be submitted, approved or rejected, and directly link it to a related record.
     * For SubmitRequests the relation is set to TargetObjectId, for WorkitemRequests it is set to WorkitemId
     *
     * @param process   Either a ProcessSubmitRequest or ProcessWorkitemRequest to be processed
     * @param relatedTo An SObject instance to be set as the TargetObjectId on the approval process
     */
    public void registerApprovalProcess( Approval.ProcessRequest process, SObject relatedTo ){
        this.registerApprovalProcess( process );
        this.registerRelationship( process, relatedTo );
    }

    /**
     * Register a relationship between two records that have yet to be inserted to the database. This information will be used
     * during commitWork() to make the references only when related records have been inserted to the database.
     *
     * @param   record              An existing or to be created record
     * @param   relatedToField      A SObjectField reference to the lookup field that relates the two records together
     * @param   relatedTo           A SObject instance (yet to be committed to the database)
     */
    public void registerRelationship( SObject record, Schema.SObjectField relatedToField, SObject relatedTo ){
        registerRelationship( record, relatedToField, relatedTo, null );
    }
    public void registerRelationship( SObject record, Schema.SObjectField relatedToField, SObject relatedTo, DMLActions specificDMLAction ){
        Schema.SObjectType sObjType = record.getSObjectType();

        // Validate whether sObjectType to populate Relation on is part of New or Update list, else throw Exception
        if( !m_sObjectTypes.contains( sObjType ) ){
            throw new UnitOfWorkException( 'You can\'t register a Relationship to a sObjectType which is not implemented for this unit of work: ' + String.valueOf( sObjType ) );
        }

        // Instantiate IRelationship and add to Map
        addToRelationshipsMap(
            sObjType,
            new Relationship( record, relatedToField, relatedTo, specificDMLAction )
        );
    }

    /**
     * Registers a relationship between a record and a lookup value using an external ID field and a provided value. This
     * information will be used during commitWork() to make the lookup reference requested when inserted to the database.
     *
     * @param   record              An existing or newly created record
     * @param   relatedToField      A SObjectField reference to the lookup field that relates the two records together
     * @param   externalIdField     A SObjectField reference to a field on the target SObject that is marked as isExternalId
     * @param   externalId          An Object representing the targeted value of the externalIdField in said lookup
     *
     * Usage Example: uow.registerRelationship(recordSObject, record_sobject__c.relationship_field__c, lookup_sobject__c.external_id__c, 'abc123');
     *
     * Wraps putSObject, creating a new instance of the lookup sobject using the external id field and value.
     */
    public void registerRelationship( SObject record, Schema.SObjectField relatedToField, Schema.SObjectField externalIdField, Object externalId ){
        registerRelationship( record, relatedToField, externalIdField, externalId, null );
    }
    public void registerRelationship( SObject record, Schema.SObjectField relatedToField, Schema.SObjectField externalIdField, Object externalId, DMLActions specificDMLAction ){
        // NOTE: Due to the lack of ExternalID references on Standard Objects, this method can not be provided a standardized Unit Test. - Rick Parker
        Schema.SObjectType sObjType = record.getSObjectType();

        // Validate whether sObjectType to populate Relation on is part of New or Update list, else throw Exception
        if( !m_sObjectTypes.contains( sObjType ) ){
            throw new UnitOfWorkException( 'You can\'t register a Relationship to a sObjectType which is not implemented for this unit of work: ' + String.valueOf( sObjType ) );
        }

        // Instantiate IRelationship and add to Map
        addToRelationshipsMap(
            sObjType,
            new RelationshipByExternalId( record, relatedToField, externalIdField, externalId, specificDMLAction )
        );
    }

    /**
     * Registers a relationship between a record and a Messaging.Email where the record has yet to be inserted to the database.
     * This information will be used during commitWork() to make the references only when related records have been
     * inserted to the database.
     *
     * @param   email       Single email message instance
     * @param   relatedTo   A SObject instance (yet to be committed to the database)
     */
    public void registerRelationship( Messaging.SingleEmailMessage email, SObject relatedTo ){
        addToRelationshipsMap( Operations.SEND_EMAIL, new EmailRelationship( email, relatedTo ) );
    }

    /**
     * Registers a relationship between a record and a Approval.ProcessRequest where the record has yet to be inserted to the database.
     * This information will be used during commitWork() to make the references only when related records have been
     * inserted to the database.
     *
     * @param   process     Process submit request instance
     * @param   relatedTo   A SObject instance (yet to be committed to the database)
     */
    public void registerRelationship( Approval.ProcessRequest process, SObject relatedTo ){
        addToRelationshipsMap( Operations.PROCESS_APPROVAL_PROCESS, new ApprovalRelationship( process, relatedTo ) );
    }

    /**
     * Centralised method to add relationshipWrapper to Relation Map by SObjectType
     * - When no Relationships yet configured for SObjectType, put new List of IRelations for specific SObjectType containing new Relationship
     * - When already Relationships configured for SObjectType, add new Relationship to List
     *
     * @param sObjType              The SObjectType for which the relationship is being registered
     * @param relationshipWrapper   The relationship instance to be registered
     */
    private void addToRelationshipsMap( Schema.SObjectType sObjType, IRelationship relationshipWrapper ){
        List<IRelationship> relations = m_relationships.get( sObjType );
        if( relations == null ){
            m_relationships.put( sObjType, new List<IRelationship>{ relationshipWrapper } );
        } else{
            relations.add( relationshipWrapper );
        }
    }

    /**
     * Centralised method to add relationshipWrapper to Relation Map by SObjectType
     * - When no Relationships yet configured for Operations, put new List of IRelations for specific SObjectType containing new Relationship
     * - When already Relationships configured for Operations, add new Relationship to List
     *
     * @param operation             The DML Operation for which the relationship is being registered
     * @param relationshipWrapper   The relationship instance to be registered
     */
    private void addToRelationshipsMap( Operations operation, IRelationship relationshipWrapper ){
        List<IRelationship> relations = m_relationshipsOperations.get( operation );
        if( relations == null ){
            m_relationshipsOperations.put( operation, new List<IRelationship>{ relationshipWrapper } );
        } else{
            relations.add( relationshipWrapper );
        }
    }

    /**
     * Registration of DML Options and All Or None
     */
    /**
     * Registers DML options which should be used for a sObject type when inserting. This will be applied for all
     * records of the same sObject type within UOW
     *
     * @param   sType       SObject type to apply the DML options to.
     * @param   options     The DML options to be applied to the records being inserted.
     */
    public void registerNewDmlOptions( Schema.SObjectType sType, Database.DMLOptions options ){
        m_newDmlOptions.put( sType, options );
    }

    /**
     * Registers DML options which should be used for a sObject type when updating. This will be applied for all
     * records of the same sObject type within UOW.
     *
     * @param   sType       SObject type to apply the DML options to.
     * @param   options     The DML options to be applied to the records being updated.
     */
    public void registerDirtyDmlOptions( Schema.SObjectType sType, Database.DMLOptions options ){
        m_dirtyDmlOptions.put( sType, options );
    }

    /**
     * Sets DML AllOrNone Option when inserting existing records for a given SObjectType
     * Will automatically enable SaveResults in case partial-success is allowed (allOrNone = false)
     *
     * @param   sType       SObject type to apply the all or none value to.
     * @param   allOrNone   True if all records should succeed, otherwise best effort will be used.
     */
    public void registerNewAllOrNone( Schema.SObjectType sType, Boolean allOrNone ){
        if( !m_newDmlOptions.containsKey( sType ) ){
            m_newDmlOptions.put( sType, new Database.DMLOptions() );
        }

        Database.DMLOptions options = m_newDmlOptions.get( sType );
        options.optAllOrNone = allOrNone;
        if( !allOrNone ){
            this.setSaveResultsRequired( true );
        }
    }

    /**
     * Sets DML AllOrNone Option when updating existing records for a given SObjectType
     * Will automatically enable SaveResults in case partial-success is allowed (allOrNone = false)
     *
     * @param   sType       SObject type to apply the all or none value to.
     * @param   allOrNone   True if all records should succeed, otherwise best effort will be used.
     */
    public void registerDirtyAllOrNone( Schema.SObjectType sType, Boolean allOrNone ){
        if( !m_dirtyDmlOptions.containsKey( sType ) ){
            m_dirtyDmlOptions.put( sType, new Database.DMLOptions() );
        }

        Database.DMLOptions options = m_dirtyDmlOptions.get( sType );
        options.optAllOrNone = allOrNone;
        if( !allOrNone ){
            this.setSaveResultsRequired( true );
        }
    }

    /**
     * Sets DML AllOrNone Option when deleting existing records for a given SObjectType
     * Will automatically enable SaveResults in case partial-success is allowed (allOrNone = false)
     *
     * @param   sType       SObject type to apply the all or none value to.
     * @param   allOrNone   True if all records should succeed, otherwise best effort will be used.
     */
    public void registerDeletedAllOrNone( Schema.SObjectType sType, Boolean allOrNone ){
        m_deletedAllOrNone.put( sType, allOrNone );
        if( !allOrNone ){
            this.setSaveResultsRequired( true );
        }
    }

    /**
     * Sets DML AllOrNone Option when undeleting existing records for a given SObjectType
     * Will automatically enable SaveResults in case partial-success is allowed (allOrNone = false)
     *
     * @param   sType       SObject type to apply the all or none value to.
     * @param   allOrNone   True if all records should succeed, otherwise best effort will be used.
     */
    public void registerUndeletedAllOrNone( Schema.SObjectType sType, Boolean allOrNone ){
        m_undeletedAllOrNone.put( sType, allOrNone );
        if( !allOrNone ){
            this.setSaveResultsRequired( true );
        }
    }

    /**
     * Method to allow verification on calling class to determine whether anything was registered to be committed
     *
     * @return Boolean     True when work has been registered, False when no work has been registered
     */
    public Boolean hasWork(){
        return
            ( constructorDefinedSObjectTypesList && constructorDefinedHasWork )
            || ( !constructorDefinedSObjectTypesList && !m_sObjectTypes.isEmpty() )
            || !m_operationObjects.isEmpty()
            || !m_workList.isEmpty();
    }

    /**
     * Takes all the work that has been registered with the UnitOfWork and commits it to the database
     * For SaveResults, set setSaveResultsRequired( true ); and fetch results by e.g. getNewResults( Schema.SObjectType)
     */
    public void commitWork(){
        // If we have no work then return early to save DML statements; note when any DML action is registered, sObject is always added to sObjectTypes
        if( !this.hasWork() ){
            System.debug( LoggingLevel.INFO, 'fflib - UnitOfWork had no work to perform, while commitWork() was called' );
            return;
        }

        // For re-used UOWs, make sure SaveResults are reset before enriched with new results
        resetSaveResults();

        // Wrap the work in its own transaction
        Savepoint sp = !Test.isRunningTest() ? Database.setSavepoint() : null;
        Boolean wasSuccessful = false;
        Integer sObjectsSize = m_sObjectTypes.size();

        try{
            // Publish all Events before other DMLs are performed
            if( !m_publishBeforeListByType.isEmpty() ){
                for( Integer i = 0; i < sObjectsSize; i++ ){
                    Schema.SObjectType sObjType = m_sObjectTypes[ i ];
                    performAction( DMLActions.dPUB_BEFORE, sObjType, m_publishBeforeListByType.get( sObjType ) );
                }
            }

            // Insert all of the priority new records by type
            if( !m_newPriorityListByType.isEmpty() ){
                for( Integer i = 0; i < sObjectsSize; i++ ){
                    Schema.SObjectType sObjType = m_sObjectTypes[ i ];
                    performAction( DMLActions.dNEW_PRIO, sObjType, m_newPriorityListByType.get( sObjType ) );
                }
            }

            // Update all of the priority records by type
            if( !m_dirtyPriorityMapByType.isEmpty() ){
                for( Integer i = 0; i < sObjectsSize; i++ ){
                    Schema.SObjectType sObjType = m_sObjectTypes[ i ];
                    // Validate whether SObjectType registered for Dirty-DML to prevent null-pointer due to Map<String, SObject> structure
                    if( m_dirtyPriorityMapByType.containsKey( sObjType ) ){
                        performAction( DMLActions.dUPDATE_PRIO, sObjType, m_dirtyPriorityMapByType.get( sObjType ).values() );
                    }
                }
            }

            // Delete all of the priority delete records by type (in reverse dependency order)
            if( !m_deletedPriorityListByType.isEmpty() ){
                for( Integer i = ( sObjectsSize - 1 ); i >= 0; i-- ){
                    Schema.SObjectType sObjType = m_sObjectTypes[ i ];
                    performAction( DMLActions.dDELETE_PRIO, sObjType, m_deletedPriorityListByType.get( sObjType ) );
                }
            }

            // Insert Immediate by type
            if( !m_newImmediateListByType.isEmpty() ){
                for( Integer i = 0; i < sObjectsSize; i++ ){
                    Schema.SObjectType sObjType = m_sObjectTypes[ i ];
                    performAction( DMLActions.dNEW_IMMEDIATE, sObjType, m_newImmediateListByType.get( sObjType ) );
                }
            }

            // Insert by type
            if( !m_newListByType.isEmpty() ){
                for( Integer i = 0; i < sObjectsSize; i++ ){
                    Schema.SObjectType sObjType = m_sObjectTypes[ i ];
                    performAction( DMLActions.dNEW, sObjType, m_newListByType.get( sObjType ) );
                }
            }

            // Update Immediate by type
            if( !m_dirtyImmediateListByType.isEmpty() ){
                for( Integer i = 0; i < sObjectsSize; i++ ){
                    Schema.SObjectType sObjType = m_sObjectTypes[ i ];
                    performAction( DMLActions.dUPDATE_IMMEDIATE, sObjType, m_dirtyImmediateListByType.get( sObjType ) );
                }
            }

            // Update by type
            if( !m_dirtyMapByType.isEmpty() ){
                for( Integer i = 0; i < sObjectsSize; i++ ){
                    Schema.SObjectType sObjType = m_sObjectTypes[ i ];
                    // Validate whether SObjectType registered for Dirty-DML to prevent null-pointer due to Map<String, SObject> structure
                    if( m_dirtyMapByType.containsKey( sObjType ) ){
                        performAction( DMLActions.dUPDATE, sObjType, m_dirtyMapByType.get( sObjType ).values() );
                    }
                }
            }

            // Delete Immediate by type (in reverse dependency order)
            if( !m_deletedImmediateListByType.isEmpty() ){
                for( Integer i = ( sObjectsSize - 1 ); i >= 0; i-- ){
                    Schema.SObjectType sObjType = m_sObjectTypes[ i ];
                    performAction( DMLActions.dDELETE_IMMEDIATE, sObjType, m_deletedImmediateListByType.get( sObjType ) );
                }
            }

            // Delete by type (in reverse dependency order)
            if( !m_deletedListByType.isEmpty() ){
                for( Integer i = ( sObjectsSize - 1 ); i >= 0; i-- ){
                    Schema.SObjectType sObjType = m_sObjectTypes[ i ];
                    performAction( DMLActions.dDELETE, sObjType, m_deletedListByType.get( sObjType ) );
                }
            }

            // Undelete by type
            if( !m_undeletedListByType.isEmpty() ){
                for( Integer i = 0; i < sObjectsSize; i++ ){
                    Schema.SObjectType sObjType = m_sObjectTypes[ i ];
                    performAction( DMLActions.dUNDELETE, sObjType, m_undeletedListByType.get( sObjType ) );
                }
            }

            // Empty recycle bin for records by type (in reverse dependency order)
            if( !m_emptyRecycleBinListByType.isEmpty() ){
                for( Integer i = ( sObjectsSize - 1 ); i >= 0; i-- ){
                    Schema.SObjectType sObjType = m_sObjectTypes[ i ];
                    performAction( DMLActions.dEMPTY_RECBIN, sObjType, m_emptyRecycleBinListByType.get( sObjType ) );
                }
            }

            // Check whether there are additional Operations to be performed (e.g. SendEmail or ApprovalProcess)
            if( !m_operationObjects.isEmpty() ){
                List<Operations> registeredOperations = new List<Operations>( m_operationObjects.keySet() );
                for( Integer i = 0, j = registeredOperations.size(); i < j; i++ ){
                    Operations op = registeredOperations[ i ];
                    performAction( op, m_operationObjects.get( op ) );
                }
            }

            // Generic work
            if( !m_workList.isEmpty() ){
                for( Integer i = 0, j = m_workList.size(); i < j; i++ ){
                    m_workList[ i ].doWork();
                }
            }

            this.validateAllRelationshipsResolved();

            // mark tracker to indicate success
            wasSuccessful = true;
        } catch( Exception e ){
            // Rollback
            if( sp != null ){
                Database.rollback( sp );
            }

            // Throw exception on to caller
            throw e;
        } finally{
            if( wasSuccessful ){
                if( !m_publishAfterSuccessListByType.isEmpty() ){
                    for( Integer i = 0; i < sObjectsSize; i++ ){
                        Schema.SObjectType sObjType = m_sObjectTypes[ i ];
                        performAction( DMLActions.dPUB_AFTER_SUCCESS, sObjType, m_publishAfterSuccessListByType.get( sObjType ) );
                    }
                }
            } else{
                if( !m_publishAfterFailureListByType.isEmpty() ){
                    for( Integer i = 0; i < sObjectsSize; i++ ){
                        Schema.SObjectType sObjType = m_sObjectTypes[ i ];
                        performAction( DMLActions.dPUB_AFTER_FAILURE, sObjType, m_publishAfterFailureListByType.get( sObjType ) );
                    }
                }
            }

            // Clear all work done (except SaveResults) to prevent accidental duplicate transactions when same UOW is re-used
            resetWork();
        }
    }

    /**
     * Centralised method to perform a DML Action
     * - Performance wise, only checks DMLOptions or AllOrNone when records available
     * - Maintenance wise, prevents duplication of code, both in IDML classes and in commitWork();
     * - Logic wise, always perform DML Actions within a try-catch and debug in case of an exception and store to SaveResultsMap
     *
     * @param action        The DML Action to be performed
     * @param sObjType      The SObjectType of the records to be processed
     * @param records       The list of SObject records to be processed
     */
    private void performAction( DMLActions action, SObjectType sObjType, List<SObject> records ){
        if( records == null || records.isEmpty() ){
            return;
        }

        if( m_relationships.containsKey( sObjType ) ){
            List<IRelationship> sObjRelations = m_relationships.get( sObjType );
            for( Integer i = 0, j = sObjRelations.size(); i < j; i++ ){
                IRelationship relWrapper = sObjRelations[ i ];

                // Only when related record is in this DML Batch, resolve relation
                if( records.contains( ( SObject ) relWrapper.getRecord() ) ){
                    relWrapper.resolve( action );
                }
            }
        }

        List<Object> saveResults;
        try{
            if( ACTIONS_DMLOPTIONS.contains( action ) ){ // insert & updates
                saveResults = m_dml.performDMLAction( action, records, ( Database.DMLOptions ) dmlOptionsPerAction.get( action ).get( sObjType ), fflib_Database.getAccessLevel( this.m_securityContext ) );
            } else if( ACTIONS_ALLORNONE.contains( action ) ){ // delete & undelete
                saveResults = m_dml.performDMLAction( action, records, ( Boolean ) dmlOptionsPerAction.get( action ).get( sObjType ), fflib_Database.getAccessLevel( this.m_securityContext ) );
            } else{ // publishEvents & emptyRecycleBin & registersImmediate
                saveResults = m_dml.performDMLAction( action, records, fflib_Database.getAccessLevel( this.m_securityContext ) );
            }
        } catch( Exception ex ){
            debug( ex, records );
        }
        // When SaveResults retrieved (insert, update, delete or undelete) and set to be required, then add to Action-SObjectType specific Map
        if( this.saveResultsRequired && saveResults != null ){
            // DMLAction-SObjectType combinations should be performed in once, so no need to check for existing data in the Map
            SAVERESULTS_PER_DMLACTION.get( action ).put( sObjType, saveResults );
        }
    }

    /**
     * Centralised method to perform a DML operation not related to an SObject or Database-method (like Email and/or Approval Processes)
     * - Resolves potential relations and calls DML Proxy
     *
     * @param operation     The DML Operation to be performed
     * @param records       The list of records/instances to be processed
     */
    @TestVisible
    private void performAction( Operations operation, List<Object> records ){
        if( records == null || records.isEmpty() ){
            return;
        }

        if( m_relationshipsOperations.containsKey( operation ) ){
            List<IRelationship> sObjRelations = m_relationshipsOperations.get( operation );
            for( Integer i = 0, j = sObjRelations.size(); i < j; i++ ){
                sObjRelations[ i ].resolve();
            }
        }

        List<Object> saveResults;
        try{
            saveResults = m_dml.performOperation( operation, records );
        } catch( Exception ex ){
            debug( ex, records );
        }
        // When SaveResults retrieved (insert, update, delete or undelete) and set to be required, then add to Action-SObjectType specific Map
        if( this.saveResultsRequired && saveResults != null ){
            // Operations should be performed in once, so no need to check for existing data in the Map
            SAVERESULTS_PER_OPERATION.put( operation, saveResults );
        }
    }

    /**
     * Internal centralized method to debug an Exception during DML Actions
     * - Dumps the transaction data that caused the exception
     * - Dumps the Exception message, cause and stacktrace
     * - When DmlException, dumps the DML FieldNames and Messages per failed record
     * - Rethrows the original Exception to the caller
     *
     * @param ex                The Exception thrown during DML Action
     * @param transactionData   The data that caused the exception
     */
    private void debug( Exception ex, Object transactionData ){
        System.debug( LoggingLevel.ERROR,
            'fflib - ========================\n\nDumping failing transaction:\n\n'
            + JSON.serializePretty( transactionData )
            + '\n\n========================'
        );

        System.debug( LoggingLevel.ERROR, 'fflib - Message: ' + ex.getMessage() );
        System.debug( LoggingLevel.ERROR, 'fflib - Cause: ' + ex.getCause() );
        System.debug( LoggingLevel.ERROR, 'fflib - StackTrace: ' + ex.getStackTraceString() );

        if( ex instanceof DmlException ){
            DmlException dex = ( DmlException ) ex;
            for( Integer i = 0, j = dex.getNumDml(); i < j; i++ ){
                System.debug( LoggingLevel.ERROR, 'fflib - DML Fields (' + i + '): ' + dex.getDmlFieldNames( i ) );
                System.debug( LoggingLevel.ERROR, 'fflib - DML Message (' + i + '): ' + dex.getDmlMessage( i ) );
            }
        }

        throw ex;
    }

    /**
     * Method to ensure all Relationships were properly resolved
     * - Relations are only resolved when the relation-record is part of the DML-batch-scope
     * - In the past there was sometimes buggy behaviour with the 'contains()' method when comparing objects, causing mismatches
     * This method should ensure relations that are expected to be resolved are in fact resolved
     * Note, only applies to SObject-relations and not Operations as that resolve-logic doesn't compare instances
     */
    private void validateAllRelationshipsResolved(){
        for( SObjectType objWithRelationship : m_relationships.keySet() ){
            List<IRelationship> sObjTypeRelationships = m_relationships.get( objWithRelationship );
            for( Integer i = 0, j = sObjTypeRelationships.size(); i < j; i++ ){
                if( !sObjTypeRelationships[ i ].wasResolved() ){
                    IRelationship rel = sObjTypeRelationships[ i ];
                    throw new UnitOfWorkException( 'The relationship was not resolved ' + rel );
                }
            }
        }
    }

    /**
     * Method to explicitly allow to store or ignore SaveResults (default disabled for performance reasoning) during commitWork()
     * Note, SaveResults are only expected to be needed when DMLOptions.AllOrNone is set to false,
     * otherwise the transaction will fail at the first record failure and the DMLException shares the cause.
     *
     * @param enabled   True to store SaveResults, False to skip logic for SaveResults
     */
    public void setSaveResultsRequired( Boolean enabled ){
        this.saveResultsRequired = enabled;

        // If SaveResults are required to be stored, construct the Maps to allow population
        if( enabled ){
            this.m_newSaveResults               = new Map<Schema.SObjectType, List<Database.SaveResult>>();
            this.m_dirtySaveResults             = new Map<Schema.SObjectType, List<Database.SaveResult>>();
            this.m_deletedSaveResults           = new Map<Schema.SObjectType, List<Database.DeleteResult>>();
            this.m_undeletedSaveResults         = new Map<Schema.SObjectType, List<Database.UndeleteResult>>();
            this.m_emptyRecycleBinSaveResults   = new Map<Schema.SObjectType, List<Database.EmptyRecycleBinResult>>();
            this.m_publishSaveResults           = new Map<Schema.SObjectType, List<Database.SaveResult>>();

            this.SAVERESULTS_PER_DMLACTION = new Map<DMLActions, Map<Schema.SObjectType, List<Object>>>{
                DMLActions.dNEW                  => m_newSaveResults,
                DMLActions.dNEW_IMMEDIATE        => m_newSaveResults,
                DMLActions.dNEW_PRIO             => m_newSaveResults,
                DMLActions.dUPDATE               => m_dirtySaveResults,
                DMLActions.dUPDATE_IMMEDIATE     => m_dirtySaveResults,
                DMLActions.dUPDATE_PRIO          => m_dirtySaveResults,
                DMLActions.dDELETE               => m_deletedSaveResults,
                DMLActions.dDELETE_IMMEDIATE     => m_deletedSaveResults,
                DMLActions.dDELETE_PRIO          => m_deletedSaveResults,
                DMLActions.dUNDELETE             => m_undeletedSaveResults,
                DMLActions.dEMPTY_RECBIN         => m_emptyRecycleBinSaveResults,
                DMLActions.dPUB_BEFORE           => m_publishSaveResults,
                DMLActions.dPUB_AFTER_SUCCESS    => m_publishSaveResults,
                DMLActions.dPUB_AFTER_FAILURE    => m_publishSaveResults
            };
            this.SAVERESULTS_PER_OPERATION = new Map<Operations, List<Object>>();
        }
    }

    /**
     * @param sObjType The SObjectType for which to retrieve Insertion SaveResults
     * @return SaveResults for inserts on given SObjectType. null when no DMLs performed for that SObjectType, or storeSaveResults is false
     */
    public List<Database.SaveResult> getNewResults( Schema.SObjectType sObjType ){
        return this.m_newSaveResults?.get( sObjType );
    }

    /**
     * @param sObjType The SObjectType for which to retrieve Update SaveResults
     * @return SaveResults for updates on given SObjectType. null when no DMLs performed for that SObjectType, or storeSaveResults is false
     */
    public List<Database.SaveResult> getDirtyResults( Schema.SObjectType sObjType ){
        return this.m_dirtySaveResults?.get( sObjType );
    }

    /**
     * @param sObjType The SObjectType for which to retrieve DeletedResults
     * @return DeleteResults for deletes on given SObjectType. null when no DMLs performed for that SObjectType, or storeSaveResults is false
     */
    public List<Database.DeleteResult> getDeletedResults( Schema.SObjectType sObjType ){
        return this.m_deletedSaveResults?.get( sObjType );
    }

    /**
     * @param sObjType The SObjectType for which to retrieve UndeleteResults
     * @return UndeleteResults for undeletes on given SObjectType. null when no DMLs performed for that SObjectType, or storeSaveResults is false
     */
    public List<Database.UndeleteResult> getUndeletedResults( Schema.SObjectType sObjType ){
        return this.m_undeletedSaveResults?.get( sObjType );
    }

    /**
     * @param sObjType The SObjectType for which to retrieve EmptyRecycleBinResults
     * @return EmptyRecycleBinResult for emptyRecycleBins on given SObjectType. null when no DMLs performed for that SObjectType, or storeSaveResults is false
     */
    public List<Database.EmptyRecycleBinResult> getEmptyRecycleBinResults( Schema.SObjectType sObjType ){
        return this.m_emptyRecycleBinSaveResults?.get( sObjType );
    }

    /**
     * @param sObjType The SObjectType for which to retrieve Publish SaveResults
     * @return SaveResults for Published Events on given Event SObjectType. null when no DMLs performed for that SObjectType, or storeSaveResults is false
     */
    public List<Database.SaveResult> getPublishResults( Schema.SObjectType sObjType ){
        return this.m_publishSaveResults?.get( sObjType );
    }

    /**
     * @return SaveResults for Send Emails. null when no Email Operation performed, or storeSaveResults is false
     */
    public List<Messaging.SendEmailResult> getEmailResults(){
        return ( List<Messaging.SendEmailResult> ) SAVERESULTS_PER_OPERATION?.get( Operations.SEND_EMAIL );
    }

    /**
     * @return SaveResults for Approval Processes. null when no Approval Operation performed, or storeSaveResults is false
     */
    public List<Approval.ProcessResult> getApprovalProcessResults(){
        return ( List<Approval.ProcessResult> ) SAVERESULTS_PER_OPERATION?.get( Operations.PROCESS_APPROVAL_PROCESS );
    }

    /**
     * Clears all of the registered work within the unit of work instance to allow reusing the unit of work
     */
    public void resetWork(){
        // Reset ordered list of SObjects available on this UnitOfWork - unless provided by constructor
        if( !constructorDefinedSObjectTypesList ){
            m_sObjectTypes.clear();
            m_sObjectTypesStrings.clear();
        } else{
            constructorDefinedHasWork = false;
        }

        // Reset work for New, Dirty, Delete and such
        m_newListByType.clear();
        m_newImmediateListByType.clear();
        m_newPriorityListByType.clear();
        m_dirtyMapByType.clear();
        m_dirtyImmediateListByType.clear();
        m_dirtyPriorityMapByType.clear();
        m_deletedListByType.clear();
        m_deletedImmediateListByType.clear();
        m_deletedPriorityListByType.clear();
        m_undeletedListByType.clear();
        m_emptyRecycleBinListByType.clear();
        m_publishBeforeListByType.clear();
        m_publishAfterSuccessListByType.clear();
        m_publishAfterFailureListByType.clear();
        m_operationObjects.clear();

        // Reset DMLOptions
        m_newDmlOptions.clear();
        m_dirtyDmlOptions.clear();
        m_deletedAllOrNone.clear();
        m_undeletedAllOrNone.clear();

        // Reset Relationship structures
        m_relationships.clear();
        m_relationshipsOperations.clear();

        // Reset WorkList
        m_workList.clear();
    }

    /**
     * Clears all SaveResults from (potential) previous commitWork() calls
     * In contrast to workLists, SaveResults lists are initiated within performDMLAction() only when a DML is performed
     */
    public void resetSaveResults(){
        if( this.saveResultsRequired ){
            m_newSaveResults.clear();
            m_dirtySaveResults.clear();
            m_deletedSaveResults.clear();
            m_undeletedSaveResults.clear();
            m_emptyRecycleBinSaveResults.clear();
            m_publishSaveResults.clear();
            SAVERESULTS_PER_OPERATION.clear();
        }
    }

    /**
     * Interface for Relationship implementations
     * Followed by different implementations
     */
    @TestVisible
    private interface IRelationship{
        // Method to Resolve the Relationship by putting some relatedRecord details on the (child) record
        void resolve();
        // Method to allow this Relation to only be resolved for a specific DMLAction
        void resolve( DMLActions currentAction );
        // Method to allow verification whether the (child) record is part of the provided SObject-list
        Object getRecord();
        // Method to verify whether the Relationship was resolved
        Boolean wasResolved();
    }

    @TestVisible
    private class Relationship implements IRelationship{
        // Relationship variables
        private SObject record;
        private Schema.SObjectField parentField;
        @TestVisible private SObject parentRecord;
        // Controller variables
        private DMLActions restrictedTo;
        private Boolean isResolved = false;

        public Relationship( SObject record, Schema.SObjectField parentField, SObject relatedToRecord, DMLActions dmlAction ){
            this.record = record;
            this.parentField = parentField;
            this.parentRecord = relatedToRecord;
            this.restrictedTo = dmlAction;
        }

        public Object getRecord(){
            return this.record;
        }

        public void resolve( DMLActions currentAction ){
            if( this.restrictedTo == null || this.restrictedTo == currentAction ){
                this.resolve();
            }
        }
        public void resolve(){
            if( this.isResolved ){
                System.debug( LoggingLevel.INFO, 'fflib - Relationship for ' + parentField + ' was already resolved before for ' + JSON.serializePretty( record ) );
                return;
            }
            this.record.put( this.parentField, this.parentRecord.Id );
            this.isResolved = true;
        }
        public Boolean wasResolved(){
            return this.isResolved;
        }
    }

    @TestVisible
    private class RelationshipByExternalId implements IRelationship{
        // Relationship variables
        @TestVisible private SObject record;
        @TestVisible private Schema.SObjectField parentField;
        @TestVisible private Schema.SObjectType parentSObjectType;
        @TestVisible private String relationshipName;
        @TestVisible private Schema.SObjectField parentExternalIdField;
        @TestVisible private Object externalIdValue;
        // Controller variables
        @TestVisible private DMLActions restrictedTo;
        @TestVisible private Boolean isResolved = false;

        @TestVisible private RelationshipByExternalId(){} // Simple constructor to allow creation in orgs without ExternalId setup to validate correct resolve() logic
        public RelationshipByExternalId( SObject record, Schema.SObjectField relatedToField, Schema.SObjectField externalIdField, Object externalId, DMLActions dmlAction ){
            if( relatedToField == null || externalIdField == null ){
                throw new UnitOfWorkException( 'Invalid argument: relatedToField or externalIdField is not provided.' );
            }

            String relationshipName = relatedToField.getDescribe().getRelationshipName();
            if( String.isBlank( relationshipName ) ){
                throw new UnitOfWorkException( 'Invalid argument: relatedToField. Field supplied is not a relationship field.' );
            }

            List<Schema.SObjectType> relatedObjects = relatedToField.getDescribe().getReferenceTo();
            Schema.SObjectType relatedObject = relatedObjects[ 0 ];

            String externalIdFieldName = externalIdField.getDescribe().getName();
            Boolean relatedHasExternalIdField = relatedObject.getDescribe().fields.getMap().keySet().contains( externalIdFieldName.toLowerCase() );
            Boolean externalIdFieldIsValid = externalIdField.getDescribe().isExternalId();

            if( !relatedHasExternalIdField ){
                throw new UnitOfWorkException( 'Invalid argument: externalIdField. Field supplied is not a known field on the target sObject.' );
            }

            if( !externalIdFieldIsValid ){
                throw new UnitOfWorkException( 'Invalid argument: externalIdField. Field supplied is not a marked as an External Identifier.' );
            }

            this.record = record;
            this.parentField = relatedToField;
            this.parentSObjectType = relatedObject;
            this.relationshipName = relationshipName;
            this.parentExternalIdField = externalIdField;
            this.externalIdValue = externalId;
            this.restrictedTo = dmlAction;
        }

        public Object getRecord(){
            return this.record;
        }

        public void resolve( DMLActions currentAction ){
            if( this.restrictedTo == null || this.restrictedTo == currentAction ){
                this.resolve();
            }
        }
        public void resolve(){
            if( this.isResolved ){
                System.debug( LoggingLevel.INFO, 'fflib - Relationship for ' + parentField + ' was already resolved before for ' + JSON.serializePretty( record ) );
                return;
            }
            SObject relationshipObject = this.parentSObjectType.newSObject();
            relationshipObject.put( parentExternalIdField.getDescribe().getName(), this.externalIdValue );
            this.record.putSObject( this.relationshipName, relationshipObject );
            this.isResolved = true;
        }
        public Boolean wasResolved(){
            return this.isResolved;
        }
    }

    @TestVisible
    private class EmailRelationship implements IRelationship{
        private Messaging.SingleEmailMessage record;
        private SObject relatedToRecord;
        private Boolean isResolved = false;

        public EmailRelationship( Messaging.SingleEmailMessage email, SObject relatedToRecord ){
            this.record = email;
            this.relatedToRecord = relatedToRecord;
        }

        public Object getRecord(){
            return this.record;
        }

        // No need to implement isResolved, as Email-resolve is only called once
        public void resolve(){
            this.record.setWhatId( this.relatedToRecord.Id );
            this.isResolved = true;
        }

        // Required functions for IRelationship
        public void resolve( DMLActions currentAction ){
            throw new UnitOfWorkException( 'EmailRelationships are performed outside DMLActions scope and should therefore not be resolved for a specific DMLAction' );
        }

        public Boolean wasResolved(){
            return this.isResolved;
        }
    }

    @TestVisible
    private class ApprovalRelationship implements IRelationship{
        private Approval.ProcessRequest record; // either of type ProcessSubmitRequest or ProcessWorkitemRequest
        private SObject relatedToRecord;
        private Boolean isResolved = false;

        public ApprovalRelationship( Approval.ProcessRequest process, SObject relatedToRecord ){
            this.record = process;
            this.relatedToRecord = relatedToRecord;
        }

        public Object getRecord(){
            return this.record;
        }

        // No need to implement isResolved, as Approval-resolve is only called once
        public void resolve(){
            if( this.record instanceof Approval.ProcessSubmitRequest ){
                ( ( Approval.ProcessSubmitRequest ) this.record ).setObjectId( this.relatedToRecord.Id );
                this.isResolved = true;
            } else if( this.record instanceof Approval.ProcessWorkitemRequest ){
                ( ( Approval.ProcessWorkitemRequest ) this.record ).setWorkitemId( this.relatedToRecord.Id );
                this.isResolved = true;
            }
        }

        // Required functions for IRelationship
        public void resolve( DMLActions currentAction ){
            throw new UnitOfWorkException( 'ApprovalRelationships are performed outside DMLActions scope and should therefore not be resolved for a specific DMLAction' );
        }

        public Boolean wasResolved(){
            return this.isResolved;
        }
    }


    /**
     * Interface for non-SObjectType related Work, to be performed during commitWork()
     * Followed by different implementations
     */
    public interface IDoWork{
        void doWork();
    }

    /**
     * UnitOfWork Exception
     */
    public class UnitOfWorkException extends Exception{}
}