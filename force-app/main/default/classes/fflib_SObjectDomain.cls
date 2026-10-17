/**
 * Copyright (c), FinancialForce.com, inc
 * Copyright (c) 2019, Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
/**
 * Base class aiding in the implementation of a Domain Model around SObject collections
 * 
 * Domain (software engineering). "a set of common requirements, terminology, and functionality 
 * for any software program constructed to solve a problem in that field",
 * http://en.wikipedia.org/wiki/Domain_(software_engineering)
 *
 * Domain Model, "An object model of the domain that incorporates both behavior and data.", 
 * "At its worst business logic can be very complex. Rules and logic describe many different "
 * "cases and slants of behavior, and it's this complexity that objects were designed to work with..." 
 * Martin Fowler, EAA Patterns
 * http://martinfowler.com/eaaCatalog/domainModel.html
 */
@NamespaceAccessible
public virtual with sharing class fflib_SObjectDomain extends fflib_SObjects implements fflib_ISObjectDomain{

    /**
     * CORE PARAMETERS
     */

    // Private static
    private static Map<String, Set<String>> processedMap = new Map<String, Set<String>>();

    // Private unit of work instance
    private fflib_ISObjectUnitOfWork uow;
    private Map<TriggerEvent, List<Type>> handlerMap = new Map<TriggerEvent, List<Type>>();
    private static Map<SObjectType, String> keyFieldPerSObjectType = new Map<SObjectType, String>();

    /**
     * Provides access to the data represented by this domain class
     */
    @NamespaceAccessible
    public List<SObject> records{
        get{
            return getRecords();
        }
        private set{
            objects = value;
        }
    }

    /**
     * Provides access to Trigger.oldMap and allowing it to be mocked in unit-tests
     */
    @TestVisible
    protected Map<Id, SObject> existingRecords{
        get{
            if( existingRecords == null ){
                if( System.Test.isRunningTest() & testFactory.database.hasRecords() ){
                    // If in test context and records are in the mock database use those instead of Trigger.oldMap
                    existingRecords = testFactory.database.oldRecords;
                } else{
                    existingRecords = Trigger.oldMap;
                }
            }

            return existingRecords;

        }
        private set;
    }

    /**
     * Exposes the configuration for this domain class instance
     */
    @NamespaceAccessible
    public Configuration configuration{ get; private set; }

    /**
     * Useful during unit testing to assert at a more granular and robust level for errors raised during the various trigger events
     *
     * @deprecated: This property has been moved to fflib_SObjects
     */
    @NamespaceAccessible
    public static fflib_SObjectDomain.ErrorFactory errorFactory{ get; private set; }

    /**
     * Useful during unit testing to access mock support for database inserts and updates (testing without DML)
     */
    @NamespaceAccessible
    public static TestFactory testFactory{ get; private set; }

    /**
     * Retains instances of domain classes implementing trigger stateful
     */
    private static Map<Type, List<fflib_SObjectDomain>> triggerStateByClass;

    /**
     * Retains the trigger tracking configuration used for each domain
     */
    private static Map<Type, TriggerEventState> triggerEventByClass;

    // TODO: To be moved to parent fflib_SObjects -> https://github.com/deloitte-engineering/dfflib/issues/3
    static{
        errorFactory = new fflib_SObjectDomain.ErrorFactory();
        testFactory = new TestFactory();
        triggerStateByClass = new Map<Type, List<fflib_SObjectDomain>>();
        triggerEventByClass = new Map<Type, TriggerEventState>();
    }

    /**
     * Constructs the domain class with the data on which to apply the behaviour implemented within
     *
     * @param	sObjectList		A concrete list (e.g. List<Account> vs List<SObject>) of records

     */
    @NamespaceAccessible
    public fflib_SObjectDomain( List<SObject> sObjectList ){
        this( sObjectList, sObjectList.getSObjectType() );
    }

    /**
     * Constructs the domain class with the data and type on which to apply the behaviour implemented within
     *
     * @param	sObjectList		A list (e.g. List<Opportunity>, List<Account>, etc.) of records
     * @param	sObjectType		The Schema.SObjectType of the records contained in the list
     *
     * @remark	Will support List<SObject> but all records in the list will be assumed to be of
     *			the type specified in sObjectType
     */
    @NamespaceAccessible
    public fflib_SObjectDomain( List<SObject> sObjectList, SObjectType sObjectType ){
        super( sObjectList, sObjectType );
        // Configure the Domain object instance
        configuration = new Configuration();
        // Create a new unit of work instance
        this.uow = fflib.unitOfWork.newInstance();
    }

    /**
     * Constructs the domain class with the data on which to apply the behaviour implemented within, with an optional
     * unit of work instance being provided.
     * Child class must call this constructor immediately to initialize the domain layer correctly
     *
     * @param   sObjectList     SObjects within the trigger context which needs to be initialized in the domain layer
     * @param   uow             Unit of work instance which can be shared across all handlers
     */
    @NamespaceAccessible
    public fflib_SObjectDomain( List<SObject> sObjectList, fflib_ISObjectUnitOfWork uow ){
        this( sObjectList );
        // After configure, the Domain object instance, enable trigger state.
        configuration.enableTriggerState();
        this.uow = uow;
    }

    /**
     * Method that registers an event with the specific handler type. Domain layers should call this method to register
     * a handler which should be fired in a trigger context. This should be called from within the domain layers constructor
     *
     * @param   tEvent          Trigger event which should be registered for the handler
     * @param   handlerType     The class type of the handler which will be used to instantiate the class.
     */
    protected void registerHandler( TriggerEvent tEvent, Type handlerType ){
        if( !handlerMap.containsKey( tEvent ) ){
            handlerMap.put( tEvent, new List<Type>() );
        }

        handlerMap.get( tEvent ).add( handlerType );
    }

    /**
     * Override this to apply defaults to the records, this is called by the handleBeforeInsert method
     */
    @NamespaceAccessible
    public virtual void onApplyDefaults(){}

    /**
     * Override this to apply general validation to be performed during insert or update, called by the handleAfterInsert and handleAfterUpdate methods
     */
    @NamespaceAccessible
    public virtual void onValidate(){}

    /**
     * Override this to apply validation to be performed during insert, called by the handleAfterUpdate method
     */
    @NamespaceAccessible
    public virtual void onValidate( Map<Id, SObject> existingRecords ){}

    /**
     * Override this to perform processing during the before insert phase, this is called by the handleBeforeInsert method
     */
    @NamespaceAccessible
    public virtual void onBeforeInsert(){
        execute( TriggerEvent.BEFORE_INSERT, records, null );
    }

    /**
     * Override this to perform processing during the before update phase, this is called by the handleBeforeUpdate method
     */
    @NamespaceAccessible
    public virtual void onBeforeUpdate( Map<Id, SObject> existingRecords ){
        execute( TriggerEvent.BEFORE_UPDATE, records, existingRecords );
    }

    /**
     * Override this to perform processing during the before delete phase, this is called by the handleBeforeDelete method
     */
    @NamespaceAccessible
    public virtual void onBeforeDelete(){
        execute( TriggerEvent.BEFORE_DELETE, records, null );
    }

    /**
     * Override this to perform processing during the after insert phase, this is called by the handleAfterInsert method
     */
    @NamespaceAccessible
    public virtual void onAfterInsert(){
        execute( TriggerEvent.AFTER_INSERT, records, null );
    }

    /**
     * Override this to perform processing during the after update phase, this is called by the handleAfterUpdate method
     */
    @NamespaceAccessible
    public virtual void onAfterUpdate( Map<Id, SObject> existingRecords ){
        execute( TriggerEvent.AFTER_UPDATE, records, existingRecords );
    }

    /**
     * Override this to perform processing during the after delete phase, this is called by the handleAfterDelete method
     */
    @NamespaceAccessible
    public virtual void onAfterDelete(){
        execute( TriggerEvent.AFTER_DELETE, records, null );
    }

    /**
     * Override this to perform processing during the after undelete phase, this is called by the handleAfterDelete method
     */
    @NamespaceAccessible
    public virtual void onAfterUndelete(){
        execute( TriggerEvent.AFTER_UNDELETE, records, null );
    }

    /**
     * Base handler for the Apex Trigger event Before Insert, calls the onApplyDefaults method, followed by onBeforeInsert
     */
    @NamespaceAccessible
    public virtual void handleBeforeInsert(){
        onApplyDefaults();
        onBeforeInsert();
    }

    /**
     * Base handler for the Apex Trigger event Before Update, calls the onBeforeUpdate method
     */
    @NamespaceAccessible
    public virtual void handleBeforeUpdate( Map<Id, SObject> existingRecords ){
        onBeforeUpdate( existingRecords );
    }

    /**
     * Base handler for the Apex Trigger event Before Delete, calls the onBeforeDelete method
     */
    @NamespaceAccessible
    public virtual void handleBeforeDelete(){
        onBeforeDelete();
    }

    /**
     * Base handler for the Apex Trigger event After Insert, checks object security and calls the onValidate and onAfterInsert methods
     *
     * @throws	DomainException if the current user context is not able to create records
     */
    @NamespaceAccessible
    public virtual void handleAfterInsert(){
        if( configuration.EnforcingTriggerCRUDSecurity && !sObjectDescribe.isCreateable() ){
            throw new DomainException( 'Permission to create an ' + sObjectDescribe.getName() + ' denied.' );
        }

        onValidate();
        onAfterInsert();
    }

    /**
     * Base handler for the Apex Trigger event After Update, checks object security and calls the onValidate, onValidate(Map<Id,SObject>) and onAfterUpdate methods
     *
     * @throws	DomainException if the current user context is not able to update records
     */
    @NamespaceAccessible
    public virtual void handleAfterUpdate( Map<Id, SObject> existingRecords ){
        if( configuration.EnforcingTriggerCRUDSecurity && !sObjectDescribe.isUpdateable() ){
            throw new DomainException( 'Permission to update an ' + sObjectDescribe.getName() + ' denied.' );
        }

        if( configuration.OldOnUpdateValidateBehaviour ){
            onValidate();
        }

        onValidate( existingRecords );
        onAfterUpdate( existingRecords );
    }

    /**
     * Base handler for the Apex Trigger event After Delete, checks object security and calls the onAfterDelete method
     *
     * @throws	DomainException if the current user context is not able to delete records
     */
    @NamespaceAccessible
    public virtual void handleAfterDelete(){
        if( configuration.EnforcingTriggerCRUDSecurity && !sObjectDescribe.isDeletable() ){
            throw new DomainException( 'Permission to delete an ' + sObjectDescribe.getName() + ' denied.' );
        }

        onAfterDelete();
    }

    /**
     * Base handler for the Apex Trigger event After Undelete, checks object security and calls the onAfterUndelete method
     *
     * @throws	DomainException if the current user context is not able to delete records
     */
    @NamespaceAccessible
    public virtual void handleAfterUndelete(){
        if( configuration.EnforcingTriggerCRUDSecurity && !sObjectDescribe.isUndeletable() ){
            throw new DomainException( 'Permission to undelete an ' + sObjectDescribe.getName() + ' denied.' );
        }

        onAfterUndelete();
    }

    /**
     * Returns the SObjectType this Domain class represents
     * 
     * @return	SObjectType that represents this domain class
     */
    @NamespaceAccessible
    public SObjectType sObjectType(){
        return getSObjectType();
    }

    /**
     * Detects whether any values in context records have changed for given fields as strings
     *
     * @return	List<SObject> that have changes in the specified fields
     */
    @NamespaceAccessible
    public List<SObject> getChangedRecords( Set<String> fieldNames ){
        List<SObject> changedRecords = new List<SObject>();
        for( SObject newRecord : records ){
            Id recordId = ( Id ) newRecord.get( 'Id' );
            if( this.existingRecords == null || !this.existingRecords.containsKey( recordId ) ){
                continue;
            }

            SObject oldRecord = this.existingRecords.get( recordId );
            for( String fieldName : fieldNames ){
                if( oldRecord.get( fieldName ) != newRecord.get( fieldName ) ){
                    changedRecords.add( newRecord );
                    break;  // Prevents the records from being added multiple times
                }
            }
        }

        return changedRecords;
    }

    /**
     * Detects whether any values in context records have changed for given fields as tokens
     *
     * @return	List<SObject> that have changes in the specified fields.
     */
    @NamespaceAccessible
    public List<SObject> getChangedRecords( Set<Schema.SObjectField> fieldNames ){
        List<SObject> changedRecords = new List<SObject>();
        for( SObject newRecord : records ){
            Id recordId = ( Id ) newRecord.get( 'Id' );
            if( this.existingRecords == null || !this.existingRecords.containsKey( recordId ) ){
                continue;
            }
            SObject oldRecord = this.existingRecords.get( recordId );
            for( Schema.SObjectField fieldDescribe : fieldNames ){
                if( oldRecord.get( fieldDescribe ) != newRecord.get( fieldDescribe ) ){
                    changedRecords.add( newRecord );
                    break;  // Prevents the records from being added multiple times
                }
            }
        }

        return changedRecords;
    }

    /**
     * Interface used to aid the triggerHandler in constructing instances of Domain classes
     */
    @NamespaceAccessible
    public interface IConstructable{
        fflib_SObjectDomain construct( List<SObject> sObjectList );
    }

    /**
     * Interface used to aid the triggerHandler in constructing instances of Domain classes
     */
    @NamespaceAccessible
    public interface IConstructable2 extends IConstructable{
        fflib_SObjectDomain construct( List<SObject> sObjectList, SObjectType sObjectType );
    }

    /**
     * For Domain classes implementing the ITriggerStateful interface returns the instance 
     *   of the domain class being shared between trigger invocations, returns null if
     *   the Domain class trigger has not yet fired or the given domain class does not implement
     *   the ITriggerStateful interface. Note this method is sensitive to recursion, meaning
     *   it will return the applicable domain instance for the level of recursion
     *
     * @return	fflib_SObjectDomain instance of the domain class being shared between trigger invocations
     */
    @NamespaceAccessible
    public static fflib_SObjectDomain getTriggerInstance( Type domainClass ){
        List<fflib_SObjectDomain> domains = triggerStateByClass.get( domainClass );
        if( domains == null || domains.size() == 0 ){
            return null;
        }

        return domains[ domains.size() - 1 ];
    }

    /**
     * Method constructs the given Domain class with the current Trigger context 
     * before calling the applicable override methods such as beforeInsert, beforeUpdate etc.
     */
    @NamespaceAccessible
    public static void triggerHandler( Type domainClass ){
        // Process the trigger context
        if( System.Test.isRunningTest() & testFactory.database.hasRecords() ){
            // If in test context and records in the mock database delegate initially to the mock database trigger handler
            testFactory.database.testTriggerHandler( domainClass );
        } else{
            // Process the runtime Apex Trigger context
            triggerHandler( domainClass,
                Trigger.isBefore,
                Trigger.isAfter,
                Trigger.isInsert,
                Trigger.isUpdate,
                Trigger.isDelete,
                Trigger.isUndelete,
                Trigger.new,
                Trigger.oldMap );
        }
    }

    private static Map<Type, Type> domainClassToImpl = new Map<Type, Type>();

    /**
     * Calls the applicable override methods such as beforeInsert, beforeUpdate etc. based on a Trigger context
     */
    private static void triggerHandler( Type domainClass, Boolean isBefore, Boolean isAfter, Boolean isInsert, Boolean isUpdate, Boolean isDelete, Boolean isUndelete, List<SObject> newRecords, Map<Id, SObject> oldRecordsMap ){
        // After phase of trigger will reuse prior instance of domain class if ITriggerStateful implemented 
        fflib_SObjectDomain domainObject = isBefore ? null : popTriggerInstance( domainClass, isDelete ? oldRecordsMap.values() : newRecords );
        if( domainObject == null ){
            // Construct the domain class constructor class
            Type constructableClass;

            if( !domainClassToImpl.containsKey( domainClass ) ){
                String domainClassName = domainClass.getName();

                // Make sure constructed class always refers to Constructor class even when not specified
                constructableClass = ( domainClassName.endsWith( 'Constructor' ) )
                    ? Type.forName( domainClassName )
                    : Type.forName( domainClassName + '.Constructor' );

                domainClassToImpl.put( domainClass, constructableClass );
            }

            constructableClass = domainClassToImpl.get( domainClass );
            IConstructable domainConstructor = ( IConstructable ) constructableClass.newInstance();

            // Construct the domain class with the appropriate record set
            if( isInsert ){
                domainObject = domainConstructor.construct( newRecords );
            } else if( isUpdate ){
                domainObject = domainConstructor.construct( newRecords );
            } else if( isDelete ){
                domainObject = domainConstructor.construct( oldRecordsMap.values() );
            } else if( isUndelete ){
                domainObject = domainConstructor.construct( newRecords );
            }

            // Should this instance be reused on the next trigger invocation?
            if( domainObject.configuration.TriggerStateEnabled ){
                // Push this instance onto the stack to be popped during the after phase
                pushTriggerInstance( domainClass, domainObject );
            }
        }

        // has this event been disabled?
        if( !getTriggerEvent( domainClass ).isEnabled( isBefore, isAfter, isInsert, isUpdate, isDelete, isUndelete ) ){
            return;
        }

        // Invoke the applicable handler
        if( isBefore ){
            if( isInsert ){
                domainObject.handleBeforeInsert();
            } else if( isUpdate ){
                domainObject.handleBeforeUpdate( oldRecordsMap );
            } else if( isDelete ){
                domainObject.handleBeforeDelete();
            }
        } else{
            if( isInsert ){
                domainObject.handleAfterInsert();
            } else if( isUpdate ){
                domainObject.handleAfterUpdate( oldRecordsMap );
            } else if( isDelete ){
                domainObject.handleAfterDelete();
            } else if( isUndelete ){
                domainObject.handleAfterUndelete();
            }
        }
    }

    /**
     * Pushes to the stack of domain classes per type a domain object instance
     */
    private static void pushTriggerInstance( Type domainClass, fflib_SObjectDomain domain ){
        List<fflib_SObjectDomain> domains = triggerStateByClass.get( domainClass );
        if( domains == null ){
            triggerStateByClass.put( domainClass, domains = new List<fflib_SObjectDomain>() );
        }
        domains.add( domain );
    }

    /**
     * Pops from the stack of domain classes per type a domain object instance and updates the record set
     * 
     * @return	fflib_SObjectDomain instance as result of popping from the list of trigger instances
     */
    private static fflib_SObjectDomain popTriggerInstance( Type domainClass, List<SObject> records ){
        List<fflib_SObjectDomain> domains = triggerStateByClass.get( domainClass );
        if( domains == null || domains.size() == 0 ){
            return null;
        }
        fflib_SObjectDomain domain = domains.remove( domains.size() - 1 );
        domain.records = records;
        return domain;
    }

    @NamespaceAccessible
    public static TriggerEventState getTriggerEvent( Type domainClass ){
        if( !triggerEventByClass.containsKey( domainClass ) ){
            triggerEventByClass.put( domainClass, new TriggerEventState() );
        }

        return triggerEventByClass.get( domainClass );
    }

    /**
     * Method that implements the logic for the executing of the trigger handlers in a form which is suitable for the framework,
     * whilst improving unit test capabilities
     *
     * @param   event               The trigger event currently being executed
     * @param   records             The records within the trigger context
     * @param   existingRecords     Previous versions of the records within the trigger context. Will be null for
     *                              before insert event
     */
    @NamespaceAccessible
    public virtual void execute( TriggerEvent event, List<SObject> records, Map<Id, SObject> existingRecords ){
        List<Type> handlerTypes = handlerMap.get( event );

        // If any trigger handlers have been registered for all events then add them all
        if( handlerMap.containsKey( TriggerEvent.ALL ) ){
            handlerTypes.addAll( handlerMap.get( TriggerEvent.ALL ) );
        }

        // If no handlers are defined for this event, we effectively don't do anything
        if( handlerTypes == null || handlerTypes.isEmpty() ){
            return;
        }

        // Preparation for the initialize, process and finalize phases
        List<Handler> handlers = new List<Handler>();
        existingRecords = existingRecords ?? new Map<Id, SObject>();
        TriggerState state = new TriggerState( records, existingRecords.values() );
        Map<Type, Boolean> handlersToTrigger = new Map<Type, Boolean>();

        // Instantiate the handlers registered for the current event
        for( Integer i = 0, j = handlerTypes.size(); i < j; i++ ){
            Type handlerType = handlerTypes[ i ];

            if( isHandlerEnabled( handlerType ) ){
                Handler handler = ( Handler ) handlerType.newInstance();
                handler.setHandlerType( handlerType );
                handlers.add( handler );
                handlersToTrigger.put( handlerType, true );
            }
        }

        // Verify if the trigger handler is correctly registered and the trigger handler is actually listening
        // for the request event
        for( Integer i = 0, j = handlers.size(); i < j; i++ ){
            verifyTriggerEventSupported( handlers[ i ], event );
        }

        // Determine if we need to run the initialize, process and finalize phases of the trigger handler
        // This is a performance saver for trigger handlers which implement FireOnce. I.e. we've processed all of the
        // records exactly once, we don't need to initialize or finalize the handlers again.
        if( event != TriggerEvent.BEFORE_INSERT ){
            for( Integer i = 0, j = handlers.size(); i < j; i++ ){
                Handler handler = handlers[ i ];
                String key = event.name() + handler.getHandlerType().getName();

                // We've not processed this handler for this trigger event before
                if( !processedMap.containsKey( key ) ){
                    continue;
                }

                // One or more records have been processed before, we need to check if we have any records which
                // need to go through the trigger handler
                if( handler instanceof FireOnce ){
                    // Extract all of the record primary values from the domain
                    Set<String> recordPrimaryKeyValues = new Set<String>();
                    for( Integer k = 0, l = records.size(); k < l; k++ ){
                        SObject record = records[ k ];
                        recordPrimaryKeyValues.add( getPrimaryKeyValue( record ) );
                    }

                    // If the processMap contains all of the record ID's then we must have processed all records
                    // and we do not need to run this handler again
                    handlersToTrigger.put( handler.getHandlerType(), !processedMap.get( key ).containsAll( recordPrimaryKeyValues ) );
                }
            }
        }

        // Initialize all of the handlers with the trigger state and a unit of work
        for( Integer i = 0, j = handlers.size(); i < j; i++ ){
            Handler handler = handlers[ i ];

            if( handlersToTrigger.get( handler.getHandlerType() ) ){
                handler.useDomain( this );
                handler.setTriggerEvent( event );

                if( handler.isEnabled() ){
                    handler.initialize( state, uow );
                }
            }
        }

        // Execute each record by calling the handlers process method
        for( Integer i = 0, j = handlers.size(); i < j; i++ ){
            Handler handler = handlers[ i ];

            // Skip the handler if it is disabled
            if( !handler.isEnabled() ){
                continue;
            }

            // Skip the handler if we do not have any records to process
            if( !handlersToTrigger.get( handler.getHandlerType() ) ){
                continue;
            }

            for( SObject record : records ){
                // Prepare the processed map to ensure that this handler is defined for the current trigger event
                String key = event.name() + handler.getHandlerType().getName();

                if( !processedMap.containsKey( key ) ){
                    processedMap.put( key, new Set<String>() );
                }

                // Only process the record for new records or if it hasn't been processed before
                Boolean processed = false;

                String recordKey = getPrimaryKeyValue( record );
                // When record not yet processed, call handler-process including previous Object, only for non-PlatformEvents
                if( recordKey == null || !processedMap.get( key ).contains( recordKey ) ){
                    SObject prev = ( recordKey instanceof Id ) ? existingRecords.get( recordKey ) : null;
                    processed = handler.process( record, prev, uow );
                }

                // Register that this record was processed for the handler
                if( handler instanceof FireOnce && recordKey != null && processed ){
                    processedMap.get( key ).add( recordKey );
                }
            }
        }

        // Finalize all of the handlers
        for( Integer i = 0, j = handlers.size(); i < j; i++ ){
            if( handlersToTrigger.get( handlers[ i ].getHandlerType() ) ){
                if( handlers[ i ].isEnabled() ){
                    handlers[ i ].finalize( state, uow );
                }
            }
        }

        // Write any changes to the database
        uow.commitWork();
    }

    /**
     * Gets the primary key value for a record that's being processed.
     * For regular Objects this is the Id. For platform events this is the replayId.
     * @param record    Record being processed to get the primary key value for (Id or ReplayId)
     * @return          Primary key value as a string.
     */
    private String getPrimaryKeyValue( SObject record ){
        SObjectType recordSObjectType = record.getSObjectType();
        String recordKeyField = keyFieldPerSObjectType.get( recordSObjectType );

        if( String.isBlank( recordKeyField ) ){
            String sObjectName = recordSObjectType.getDescribe().getName();
            recordKeyField = ( sObjectName.endsWith( '__e' ) ) ? 'ReplayId' : 'Id';
            keyFieldPerSObjectType.put( recordSObjectType, recordKeyField );
        }

        return String.valueOf( record.get( recordKeyField ) );
    }

    /**
     * Method that checks if the trigger handler is enabled via the use of custom settings. This is here to allow data stewards to
     * disable functionality either for performance reasons or to disable functionality not required for a migration.
     *
     * @param   handlerType     The handler type to verify
     * @return  Boolean containing the status of the handler
     */
    private Boolean isHandlerEnabled( Type handlerType ){
        // TODO: add a custom meta object for switches
        return true;
    }

    /**
     * Method that verifies that a trigger is actually listening to the registered trigger event specified when it was registered
     * with the sObject domain
     *
     * @param   handler     The trigger handler instance to check supports a given trigger event
     * @param   tEvent      The trigger event which is currently being handled
     */
    private void verifyTriggerEventSupported( Handler handler, TriggerEvent tEvent ){
        // In case the handler is not an instance of AllEvents, and its instance defers from the trigger event type
        // E.g. tEvent = TriggerEvent.BEFORE_INSERT && handler instanceof BeforeUpdate
        // Throw formatted exception
        if( !( handler instanceof AllEvents ) && (
            ( tEvent == TriggerEvent.BEFORE_INSERT && !( handler instanceof BeforeInsert ) ) ||
            ( tEvent == TriggerEvent.BEFORE_UPDATE && !( handler instanceof BeforeUpdate ) ) ||
            ( tEvent == TriggerEvent.BEFORE_DELETE && !( handler instanceof BeforeDelete ) ) ||
            ( tEvent == TriggerEvent.AFTER_INSERT && !( handler instanceof AfterInsert ) ) ||
            ( tEvent == TriggerEvent.AFTER_UPDATE && !( handler instanceof AfterUpdate ) ) ||
            ( tEvent == TriggerEvent.AFTER_DELETE && !( handler instanceof AfterDelete ) ) ||
            ( tEvent == TriggerEvent.AFTER_UNDELETE && !( handler instanceof AfterUndelete ) ) ) ){
            throw new TriggerHandlerException(
                String.format(
                    'Handler {0} does not support the trigger event {1}',
                    new List<String>{
                        handler.getHandlerType().getName(),
                        tEvent.name()
                    }
                )
            );
        }
    }

    /**
     * Method that facilitates testing the trigger handlers. This will allow running individual trigger handlers with a given
     * state for a specific trigger event
     *
     * @param   handlerType         The class type of the handler being tested
     * @param   tEvent              The trigger event being simulated
     * @param   existingRecords     Map containing the previous versions of the records being passed into the trigger handler
     * @param   uow                 Mock unit of work instance
     * @return  List of booleans which indicate whether the records were processed or not
     */
    @TestVisible
    private List<Boolean> runHandler( Type handlerType, TriggerEvent tEvent, Map<Id, SObject> existingRecords, fflib_ISObjectUnitOfWork uow ){
        List<Boolean> processResults = new List<Boolean>();
        existingRecords = existingRecords ?? new Map<Id, SObject>();
        TriggerState state = new TriggerState( records, existingRecords.values() );

        Handler handler = ( Handler ) handlerType.newInstance();
        handler.setHandlerType( handlerType );
        handler.setTriggerEvent( tEvent );
        verifyTriggerEventSupported( handler, tEvent );
        handler.useDomain( this );
        handler.initialize( state, uow );

        for( Integer i = 0, j = records.size(); i < j; i++ ){
            SObject record = records[ i ];
            String recordKey = getPrimaryKeyValue( record );
            SObject prev = ( recordKey instanceof Id ) ? existingRecords.get( record.Id ) : null;
            processResults.add( handler.process( record, prev, uow ) );
        }

        handler.finalize( state, uow );
        return processResults;
    }

    /**
     * INNER & AUXILIARY CLASSES/INTERFACES
     */

    @NamespaceAccessible
    public class TriggerEventState{
        @NamespaceAccessible
        public Boolean BeforeInsertEnabled{ get; private set; }
        @NamespaceAccessible
        public Boolean BeforeUpdateEnabled{ get; private set; }
        @NamespaceAccessible
        public Boolean BeforeDeleteEnabled{ get; private set; }

        @NamespaceAccessible
        public Boolean AfterInsertEnabled{ get; private set; }
        @NamespaceAccessible
        public Boolean AfterUpdateEnabled{ get; private set; }
        @NamespaceAccessible
        public Boolean AfterDeleteEnabled{ get; private set; }
        @NamespaceAccessible
        public Boolean AfterUndeleteEnabled{ get; private set; }

        @NamespaceAccessible
        public TriggerEventState(){
            this.enableAll();
        }

        // Before trigger attribute
        @NamespaceAccessible
        public TriggerEventState enableBeforeInsert(){
            BeforeInsertEnabled = true;
            return this;
        }
        @NamespaceAccessible
        public TriggerEventState enableBeforeUpdate(){
            BeforeUpdateEnabled = true;
            return this;
        }
        @NamespaceAccessible
        public TriggerEventState enableBeforeDelete(){
            BeforeDeleteEnabled = true;
            return this;
        }

        @NamespaceAccessible
        public TriggerEventState disableBeforeInsert(){
            BeforeInsertEnabled = false;
            return this;
        }
        @NamespaceAccessible
        public TriggerEventState disableBeforeUpdate(){
            BeforeUpdateEnabled = false;
            return this;
        }
        @NamespaceAccessible
        public TriggerEventState disableBeforeDelete(){
            BeforeDeleteEnabled = false;
            return this;
        }

        // After trigger attribute
        @NamespaceAccessible
        public TriggerEventState enableAfterInsert(){
            AfterInsertEnabled = true;
            return this;
        }
        @NamespaceAccessible
        public TriggerEventState enableAfterUpdate(){
            AfterUpdateEnabled = true;
            return this;
        }
        @NamespaceAccessible
        public TriggerEventState enableAfterDelete(){
            AfterDeleteEnabled = true;
            return this;
        }
        @NamespaceAccessible
        public TriggerEventState enableAfterUndelete(){
            AfterUndeleteEnabled = true;
            return this;
        }


        @NamespaceAccessible
        public TriggerEventState disableAfterInsert(){
            AfterInsertEnabled = false;
            return this;
        }
        @NamespaceAccessible
        public TriggerEventState disableAfterUpdate(){
            AfterUpdateEnabled = false;
            return this;
        }
        @NamespaceAccessible
        public TriggerEventState disableAfterDelete(){
            AfterDeleteEnabled = false;
            return this;
        }
        @NamespaceAccessible
        public TriggerEventState disableAfterUndelete(){
            AfterUndeleteEnabled = false;
            return this;
        }

        @NamespaceAccessible
        public TriggerEventState enableAll(){
            return this.enableAllBefore().enableAllAfter();
        }

        @NamespaceAccessible
        public TriggerEventState disableAll(){
            return this.disableAllBefore().disableAllAfter();
        }

        @NamespaceAccessible
        public TriggerEventState enableAllBefore(){
            return this.enableBeforeInsert().enableBeforeUpdate().enableBeforeDelete();
        }

        @NamespaceAccessible
        public TriggerEventState disableAllBefore(){
            return this.disableBeforeInsert().disableBeforeUpdate().disableBeforeDelete();
        }

        @NamespaceAccessible
        public TriggerEventState enableAllAfter(){
            return this.enableAfterInsert().enableAfterUpdate().enableAfterDelete().enableAfterUndelete();
        }

        @NamespaceAccessible
        public TriggerEventState disableAllAfter(){
            return this.disableAfterInsert().disableAfterUpdate().disableAfterDelete().disableAfterUndelete();
        }

        @NamespaceAccessible
        public Boolean isEnabled( Boolean isBefore, Boolean isAfter, Boolean isInsert, Boolean isUpdate, Boolean isDelete, Boolean isUndelete ){
            if( isBefore ){
                if( isInsert ){
                    return BeforeInsertEnabled;
                } else if( isUpdate ){
                    return BeforeUpdateEnabled;
                } else if( isDelete ){
                    return BeforeDeleteEnabled;
                }
            } else if( isAfter ){
                if( isInsert ){
                    return AfterInsertEnabled;
                } else if( isUpdate ){
                    return AfterUpdateEnabled;
                } else if( isDelete ){
                    return AfterDeleteEnabled;
                } else if( isUndelete ){
                    return AfterUndeleteEnabled;
                }
            }

            return true; // shouldn't ever get here!
        }
    }

    /**
     * Fluent style Configuration system for Domain class creation
     */
    @NamespaceAccessible
    public class Configuration{
        /** 
         * Backwards compatibility mode for handleAfterUpdate routing to onValidate()
         */
        @NamespaceAccessible
        public Boolean OldOnUpdateValidateBehaviour{ get; private set; }
        /**
         * True if the base class is checking the users CRUD requirements before invoking trigger methods
         */
        @NamespaceAccessible
        public Boolean EnforcingTriggerCRUDSecurity{ get; private set; }

        /**
         * Enables reuse of the same Domain instance between before and after trigger phases (subject to recursive scenarios)
         */
        @NamespaceAccessible
        public Boolean TriggerStateEnabled{ get; private set; }

        /**
         * Default configuration 
         */
        @NamespaceAccessible
        public Configuration(){
            EnforcingTriggerCRUDSecurity = true; // Default is true for backwards compatibility
            TriggerStateEnabled = false;
            OldOnUpdateValidateBehaviour = false; // Breaking change, but felt to better practice
        }

        /**
         * See associated property
         * 
         * @return	Configuration instance.
         */
        @NamespaceAccessible
        public Configuration enableTriggerState(){
            TriggerStateEnabled = true;
            return this;
        }

        /**
         * See associated property
         * 
         * @return	Configuration instance.
         */
        @NamespaceAccessible
        public Configuration disableTriggerState(){
            TriggerStateEnabled = false;
            return this;
        }

        /**
         * See associated property
         * 
         * @return	Configuration instance.
         */
        @NamespaceAccessible
        public Configuration enforceTriggerCRUDSecurity(){
            EnforcingTriggerCRUDSecurity = true;
            return this;
        }

        /**
         * See associated property
         * 
         * @return	Configuration instance.
         */
        @NamespaceAccessible
        public Configuration disableTriggerCRUDSecurity(){
            EnforcingTriggerCRUDSecurity = false;
            return this;
        }

        /**
         * See associated property
         * 
         * @return	Configuration instance.
         */
        @NamespaceAccessible
        public Configuration enableOldOnUpdateValidateBehaviour(){
            OldOnUpdateValidateBehaviour = true;
            return this;
        }

        /**
         * See associated property
         * 
         * @return	Configuration instance.
         */
        @NamespaceAccessible
        public Configuration disableOldOnUpdateValidateBehaviour(){
            OldOnUpdateValidateBehaviour = false;
            return this;
        }
    }

    /**
     * General exception class for the domain layer
     */
    @NamespaceAccessible
    public class DomainException extends Exception{}

    /**
     * Ensures logging of errors in the Domain context for later assertions in tests
     *
     * @deprecated: This property has been moved to fflib_SObjects
     */
    @NamespaceAccessible
    public override String error( String message, SObject record ){
        return fflib_SObjectDomain.errorFactory.error( this, message, record );
    }

    /**
     * Ensures logging of errors in the Domain context for later assertions in tests
     *
     * @deprecated: This property has been moved to fflib_SObjects
     */
    @NamespaceAccessible
    public override String error( String message, SObject record, SObjectField field ){
        return fflib_SObjectDomain.errorFactory.error( this, message, record, field );
    }

    /**
     * Ensures logging of errors in the Domain context for later assertions in tests
     *
     * @deprecated: This property has been moved to fflib_SObjects
     */
    @NamespaceAccessible
    public class ErrorFactory{
        private List<Error> errorList = new List<Error>();

        private ErrorFactory(){}

        @NamespaceAccessible
        public String error( String message, SObject record ){
            return error( null, message, record );
        }

        private String error( fflib_SObjectDomain domain, String message, SObject record ){
            ObjectError objectError = new ObjectError();
            objectError.domain = domain;
            objectError.message = message;
            objectError.record = record;
            errorList.add( objectError );

            return message;
        }

        @NamespaceAccessible
        public String error( String message, SObject record, SObjectField field ){
            return error( null, message, record, field );
        }

        private String error( fflib_SObjectDomain domain, String message, SObject record, SObjectField field ){
            FieldError fieldError = new FieldError();
            fieldError.domain = domain;
            fieldError.message = message;
            fieldError.record = record;
            fieldError.field = field;
            errorList.add( fieldError );

            return message;
        }

        @NamespaceAccessible
        public List<Error> getAll(){
            return errorList.clone();
        }

        @NamespaceAccessible
        public void clearAll(){
            errorList.clear();
        }
    }

    /**
     * Ensures logging of errors in the Domain context for later assertions in tests
     *
     * @deprecated: This property has been moved to fflib_SObjects
     */
    @NamespaceAccessible
    public virtual class FieldError extends ObjectError{
        @NamespaceAccessible
        public SObjectField field;

        @NamespaceAccessible
        public FieldError(){}
    }

    /**
     * Ensures logging of errors in the Domain context for later assertions in tests
     *
     * @deprecated: This property has been moved to fflib_SObjects
     */
    @NamespaceAccessible
    public virtual class ObjectError extends Error{
        @NamespaceAccessible
        public SObject record;

        @NamespaceAccessible
        public ObjectError(){}
    }

    /**
     * Ensures logging of errors in the Domain context for later assertions in tests
     *
     * @deprecated: This property has been moved to fflib_SObjects
     */
    @NamespaceAccessible
    public abstract class Error{
        @NamespaceAccessible
        public String message;
        @NamespaceAccessible
        public fflib_SObjectDomain domain;
    }

    /**
     * Exception which is thrown if there is a configuration or state issue with a trigger handler
     */
    private class TriggerHandlerException extends Exception{
    }

    /**
     * Enum listing out all of the possible trigger events
     */
    public enum TriggerEvent{
        BEFORE_INSERT,
        BEFORE_UPDATE,
        BEFORE_DELETE,
        AFTER_INSERT,
        AFTER_UPDATE,
        AFTER_DELETE,
        AFTER_UNDELETE,
        ALL
    }

    /**
     * A instance of this class will be injected into the initialize and finalize phases of every trigger handler. It
     * allows the trigger handler to preload or bulk perform actions
     */
    @NamespaceAccessible
    public class TriggerState{
        @NamespaceAccessible
        public final List<SObject> currentList;
        @NamespaceAccessible
        public final List<SObject> originalList;

        @NamespaceAccessible
        public TriggerState( List<SObject> currentList, List<SObject> originalList ){
            this.currentList = currentList;
            this.originalList = originalList;
        }
    }

    /**
     * All trigger handlers must implement this interface.
     */
    @NamespaceAccessible
    public interface Handler{
        Boolean isEnabled();
        void enable();
        void disable();
        void setHandlerType( Type handlerType );
        Type getHandlerType();
        void useDomain( fflib_SObjectDomain domain );
        void setTriggerEvent( TriggerEvent tEvent );
        void initialize( TriggerState state, fflib_ISObjectUnitOfWork uow );
        Boolean process( SObject current, SObject previous, fflib_ISObjectUnitOfWork uow );
        void finalize( TriggerState state, fflib_ISObjectUnitOfWork uow );
        String error( String message, SObject record );
        String error( String message, SObject record, SObjectField field );
    }

    /**
     * Base trigger handler which can be extended by child handlers. This saves the developers from writing all of the
     * methods and only have to specify the methods required for the handler.
     */
    @NamespaceAccessible
    public abstract class BaseHandler implements Handler{
        private fflib_SObjectDomain domain;
        private TriggerEvent tEvent;
        private Type handlerType;
        private Boolean enabled = true;

        /**
         * Allows the adaptor to inject the sObject domain into the handler to allow registering errors.
         */
        @NamespaceAccessible
        public void useDomain( fflib_SObjectDomain domain ){
            this.domain = domain;
        }

        /**
         * Initialize phase of the trigger handler.
         */
        @NamespaceAccessible
        public virtual void initialize( TriggerState state, fflib_ISObjectUnitOfWork uow ){}

        /**
         * Processes a single record within a trigger context.
         */
        @NamespaceAccessible
        public virtual Boolean process( SObject current, SObject previous, fflib_ISObjectUnitOfWork uow ){
            return true;
        }

        /**
         * Finalize phase of the trigger handler.
         */
        @NamespaceAccessible
        public virtual void finalize( TriggerState state, fflib_ISObjectUnitOfWork uow ){
        }

        /**
         * Ensures logging of errors in the Domain context for later assertions in tests
         */
        @NamespaceAccessible
        public String error( String message, SObject record ){
            return this.domain.error( message, record );
        }

        /**
         * Ensures logging of errors in the Domain context for later assertions in tests
         */
        @NamespaceAccessible
        public String error( String message, SObject record, SObjectField field ){
            return this.domain.error( message, record, field );
        }

        /**
         * Allows the domain to set the trigger event which is currently being handled.
         */
        @NamespaceAccessible
        public void setTriggerEvent( TriggerEvent tEvent ){
            this.tEvent = tEvent;
        }

        /**
         * Allows the trigger handler to retrieve the trigger event which is currently being handled.
         */
        @NamespaceAccessible
        public TriggerEvent getTriggerEvent(){
            return tEvent;
        }

        @NamespaceAccessible
        public Boolean isBefore(){
            return tEvent == TriggerEvent.BEFORE_DELETE || tEvent == TriggerEvent.BEFORE_INSERT || tEvent == TriggerEvent.BEFORE_UPDATE;
        }
        @NamespaceAccessible
        public Boolean isAfter(){
            return tEvent == TriggerEvent.AFTER_DELETE || tEvent == TriggerEvent.AFTER_INSERT || tEvent == TriggerEvent.AFTER_UNDELETE || tEvent == TriggerEvent.AFTER_UPDATE;
        }

        @NamespaceAccessible
        public Boolean isDelete(){
            return tEvent == TriggerEvent.BEFORE_DELETE || tEvent == TriggerEvent.AFTER_DELETE;
        }
        @NamespaceAccessible
        public Boolean isInsert(){
            return tEvent == TriggerEvent.BEFORE_INSERT || tEvent == TriggerEvent.AFTER_INSERT;
        }
        @NamespaceAccessible
        public Boolean isUndelete(){
            return tEvent == TriggerEvent.AFTER_UNDELETE;
        }
        @NamespaceAccessible
        public Boolean isUpdate(){
            return tEvent == TriggerEvent.BEFORE_UPDATE || tEvent == TriggerEvent.AFTER_UPDATE;
        }

        /**
         * Sets the handler type this class is an instance of.
         */
        @NamespaceAccessible
        public void setHandlerType( Type handlerType ){
            this.handlerType = handlerType;
        }

        /**
         * Returns the type of the handler.
         */
        @NamespaceAccessible
        public Type getHandlerType(){
            return handlerType;
        }

        /**
         * Allows the trigger handler access to the domain.
         */
        @NamespaceAccessible
        public fflib_SObjectDomain getDomain(){
            return domain;
        }

        @NamespaceAccessible
        public void disable(){
            enabled = false;
        }

        @NamespaceAccessible
        public void enable(){
            enabled = true;
        }

        @NamespaceAccessible
        public Boolean isEnabled(){
            return enabled;
        }
    }

    /**
     * Handlers should implement this interface if they wish to use the functionality whereby the handlers are only
     * fired once per record.
     */
    @NamespaceAccessible
    public interface FireOnce{}

    /**
     * Interface which should be implemented by trigger handlers to indicate which trigger event they are listening for.
     */
    @NamespaceAccessible
    public interface BeforeInsert{}

    /**
     * Interface which should be implemented by trigger handlers to indicate which trigger event they are listening for.
     */
    @NamespaceAccessible
    public interface BeforeUpdate{}

    /**
     * Interface which should be implemented by trigger handlers to indicate which trigger event they are listening for.
     */
    @NamespaceAccessible
    public interface BeforeDelete{}

    /**
     * Interface which should be implemented by trigger handlers to indicate which trigger event they are listening for.
     */
    @NamespaceAccessible
    public interface AfterInsert{}

    /**
     * Interface which should be implemented by trigger handlers to indicate which trigger event they are listening for.
     */
    @NamespaceAccessible
    public interface AfterUpdate{}

    /**
     * Interface which should be implemented by trigger handlers to indicate which trigger event they are listening for.
      */
    @NamespaceAccessible
    public interface AfterDelete{}

    /**
     * Interface which should be implemented by trigger handlers to indicate which trigger event they are listening for.
     */
    @NamespaceAccessible
    public interface AfterUndelete{}

    /**
     * Interface which should be implemented by trigger handlers to indicate which trigger event they are listening for.
     */
    @NamespaceAccessible
    public interface AllEvents{}

    /**
     * INNER & AUXILIARY TESTING CLASSES
     */

    /**
     * Provides test context mocking facilities to unit tests testing domain classes
     */
    @NamespaceAccessible
    public class TestFactory{
        @NamespaceAccessible
        public MockDatabase database = new MockDatabase();

        private TestFactory(){}
    }

    /**
     * Class used during Unit testing of Domain classes, can be used (not exclusively) to speed up test execution and focus testing
     */
    @NamespaceAccessible
    public class MockDatabase{
        private Boolean isInsert = false;
        private Boolean isUpdate = false;
        private Boolean isDelete = false;
        private Boolean isUndelete = false;
        private List<SObject> records = new List<SObject>();
        private Map<Id, SObject> oldRecords = new Map<Id, SObject>();

        private MockDatabase(){}

        private void testTriggerHandler( Type domainClass ){
            // Mock Before
            triggerHandler( domainClass, true, false, isInsert, isUpdate, isDelete, isUndelete, records, oldRecords );

            // Mock After
            triggerHandler( domainClass, false, true, isInsert, isUpdate, isDelete, isUndelete, records, oldRecords );
        }

        @NamespaceAccessible
        public void onInsert( List<SObject> records ){
            this.isInsert = true;
            this.isUpdate = false;
            this.isDelete = false;
            this.isUndelete = false;
            this.records = records;
        }

        @NamespaceAccessible
        public void onUpdate( List<SObject> records, Map<Id, SObject> oldRecords ){
            this.isInsert = false;
            this.isUpdate = true;
            this.isDelete = false;
            this.records = records;
            this.isUndelete = false;
            this.oldRecords = oldRecords;
        }

        @NamespaceAccessible
        public void onDelete( Map<Id, SObject> records ){
            this.isInsert = false;
            this.isUpdate = false;
            this.isDelete = true;
            this.isUndelete = false;
            this.oldRecords = records;
        }

        @NamespaceAccessible
        public void onUndelete( List<SObject> records ){
            this.isInsert = false;
            this.isUpdate = false;
            this.isDelete = false;
            this.isUndelete = true;
            this.records = records;
        }

        @NamespaceAccessible
        public Boolean hasRecords(){
            return records != null && records.size() > 0 || oldRecords != null && oldRecords.size() > 0;
        }
    }

    /**
     * Test domain class (ideally this would be in the test class, however Type.newInstance does not see such classes)
     */
    @NamespaceAccessible
    public with sharing class TestSObjectDomain extends fflib_SObjectDomain{
        private String someState;

        @NamespaceAccessible
        public TestSObjectDomain( List<Opportunity> sObjectList ){
            // Domain classes are initialised with lists to enforce bulkification throughout
            super( sObjectList );
        }

        @NamespaceAccessible
        public TestSObjectDomain( List<Opportunity> sObjectList, SObjectType sObjectType ){
            // Domain classes are initialised with lists to enforce bulkification throughout
            super( sObjectList, sObjectType );
        }

        @NamespaceAccessible
        public override void onApplyDefaults(){
            // Not required in production code
            super.onApplyDefaults();

            // Apply defaults to Testfflib_SObjectDomain
            for( Opportunity opportunity : ( List<Opportunity> ) records ){
                opportunity.CloseDate = System.today().addDays( 30 );
            }
        }

        @NamespaceAccessible
        public override void onValidate(){
            // Not required in production code
            super.onValidate();

            // Validate Testfflib_SObjectDomain
            for( Opportunity opp : ( List<Opportunity> ) records ){
                if( opp.Type != null && opp.Type.startsWith( 'Existing' ) && opp.AccountId == null ){
                    opp.AccountId.addError( error( 'You must provide an Account for Opportunities for existing Customers.', opp, Opportunity.AccountId ) );
                }
            }
        }

        @NamespaceAccessible
        public override void onValidate( Map<Id, SObject> existingRecords ){
            // Not required in production code	
            super.onValidate( existingRecords );

            // Validate changes to fflib_SObjectDomainTest
            for( Opportunity opp : ( List<Opportunity> ) records ){
                Opportunity existingOpp = ( Opportunity ) existingRecords.get( opp.Id );
                if( opp.Type != existingOpp.Type ){
                    opp.Type.addError( error( 'You cannot change the Opportunity type once it has been created.', opp, Opportunity.Type ) );
                }
            }
        }

        @NamespaceAccessible
        public override void onBeforeDelete(){
            // Not required in production code
            super.onBeforeDelete();

            // Validate changes to fflib_SObjectDomainTest
            for( Opportunity opp : ( List<Opportunity> ) records ){
                opp.addError( error( 'You cannot delete this Opportunity.', opp ) );
            }
        }

        @NamespaceAccessible
        public override void onAfterUndelete(){
            // Not required in production code
            super.onAfterUndelete();
        }

        @NamespaceAccessible
        public override void onBeforeInsert(){
            // Assert this variable is null in the after insert (since this domain class is stateless)
            someState = 'This should not survice the trigger after phase';
        }

        @NamespaceAccessible
        public override void onAfterInsert(){
            // This is a stateless domain class, so should not retain anything betweet before and after
            System.Assert.isNull( someState );
        }
    }

    /**
     * Typically an inner class to the domain class, supported here for test purposes
     */
    @NamespaceAccessible
    public class TestSObjectDomainConstructor implements fflib_SObjectDomain.IConstructable{
        @NamespaceAccessible
        public fflib_SObjectDomain construct( List<SObject> sObjectList ){
            return new TestSObjectDomain( sObjectList );
        }
    }

    /**
     * Test domain class (ideally this would be in the test class, however Type.newInstance does not see such classes)
     */
    @NamespaceAccessible
    public with sharing class TestSObjectStatefulDomain extends fflib_SObjectDomain{
        @NamespaceAccessible
        public String someState;

        @NamespaceAccessible
        public TestSObjectStatefulDomain( List<Opportunity> sObjectList ){
            super( sObjectList );

            // Ensure this instance is re-used in the after trigger phase (subject to recursive scenarios)		
            configuration.enableTriggerState();
        }

        @NamespaceAccessible
        public override void onBeforeInsert(){
            // This must always be null, as we do not reuse domain instances within recursive scenarios (different record sets)
            System.Assert.isNull( someState );

            // Process records			 
            List<Opportunity> newOpps = new List<Opportunity>();
            for( Opportunity opp : ( List<Opportunity> ) records ){
                // Set some state sensitive to the incoming records
                someState = 'Error on Record ' + opp.Name;

                // Create a new Opportunity record to trigger recursive code path?
                if( opp.Name.equals( 'Test Recursive 1' ) ){
                    newOpps.add( new Opportunity ( Name = 'Test Recursive 2', Type = 'Existing Account' ) );
                }
            }

            // If testing recursively emulate an insert 	
            if( newOpps.size() > 0 ){
                // This will force recursion and thus validate via the above assert results in a new domain instance
                fflib_SObjectDomain.testFactory.database.onInsert( newOpps );
                fflib_SObjectDomain.triggerHandler( fflib_SObjectDomain.TestSObjectStatefulDomainConstructor.class );
            }
        }

        @NamespaceAccessible
        public override void onAfterInsert(){
            // Use the state set in the before insert (since this is a stateful domain class)
            if( someState != null ){
                for( Opportunity opp : ( List<Opportunity> ) records ){
                    opp.addError( error( someState, opp ) );
                }
            }
        }
    }

    /**
     * Typically an inner class to the domain class, supported here for test purposes
     */
    @NamespaceAccessible
    public class TestSObjectStatefulDomainConstructor implements fflib_SObjectDomain.IConstructable{
        @NamespaceAccessible
        public fflib_SObjectDomain construct( List<SObject> sObjectList ){
            return new TestSObjectStatefulDomain( sObjectList );
        }
    }

    /**
     * Test domain class (ideally this would be in the test class, however Type.newInstance does not see such classes)
     */
    @NamespaceAccessible
    public with sharing class TestSObjectOnValidateBehaviour extends fflib_SObjectDomain{
        @NamespaceAccessible
        public TestSObjectOnValidateBehaviour( List<Opportunity> sObjectList ){
            super( sObjectList );

            // Enable old behaviour based on the test Opportunity name passed in 
            if( sObjectList[ 0 ].Name == 'Test Enable Old Behaviour' ){
                configuration.enableOldOnUpdateValidateBehaviour();
            }
        }

        @NamespaceAccessible
        public override void onValidate(){
            // Throw exception to give the test something to assert on
            throw new DomainException( 'onValidate called' );
        }
    }

    /**
     * Typically an inner class to the domain class, supported here for test purposes
     */
    @NamespaceAccessible
    public class TestSObjectOnValidateBehaviourConstructor implements fflib_SObjectDomain.IConstructable{
        @NamespaceAccessible
        public fflib_SObjectDomain construct( List<SObject> sObjectList ){
            return new TestSObjectOnValidateBehaviour( sObjectList );
        }
    }

    /**
     * Test domain class (ideally this would be in the test class, however Type.newInstance does not see such classes)
     */
    @NamespaceAccessible
    public with sharing class TestSObjectChangedRecords
        extends fflib_SObjectDomain{
        @NamespaceAccessible
        public TestSObjectChangedRecords( List<Opportunity> sObjectList ){
            super( sObjectList );
        }
    }

    /**
     * Typically an inner class to the domain class, supported here for test purposes
     */
    @NamespaceAccessible
    public class TestSObjectChangedRecordsConstructor implements fflib_SObjectDomain.IConstructable{
        @NamespaceAccessible
        public fflib_SObjectDomain construct( List<SObject> sObjectList ){
            return new TestSObjectChangedRecords( sObjectList );
        }
    }

    /**
     * Test domain class (ideally this would be in the test class, however Type.newInstance does not see such classes)
     */
    @NamespaceAccessible
    public with sharing class TestSObjectDisableBehaviour extends fflib_SObjectDomain{
        @NamespaceAccessible
        public TestSObjectDisableBehaviour( List<Opportunity> sObjectList ){
            super( sObjectList );
        }

        @NamespaceAccessible
        public override void onAfterInsert(){
            // Throw exception to give the test something to assert on
            throw new DomainException( 'onAfterInsert called' );
        }

        @NamespaceAccessible
        public override void onBeforeInsert(){
            // Throw exception to give the test something to assert on
            throw new DomainException( 'onBeforeInsert called' );
        }

        @NamespaceAccessible
        public override void onAfterUpdate( Map<Id, SObject> existing ){
            // Throw exception to give the test something to assert on
            throw new DomainException( 'onAfterUpdate called' );
        }

        @NamespaceAccessible
        public override void onBeforeUpdate( Map<Id, SObject> existing ){
            // Throw exception to give the test something to assert on
            throw new DomainException( 'onBeforeUpdate called' );
        }

        @NamespaceAccessible
        public override void onAfterDelete(){
            // Throw exception to give the test something to assert on
            throw new DomainException( 'onAfterDelete called' );
        }

        @NamespaceAccessible
        public override void onBeforeDelete(){
            // Throw exception to give the test something to assert on
            throw new DomainException( 'onBeforeDelete called' );
        }

        @NamespaceAccessible
        public override void onAfterUndelete(){
            // Throw exception to give the test something to assert on
            throw new DomainException( 'onAfterUndelete called' );
        }
    }

    /**
     * Typically an inner class to the domain class, supported here for test purposes
     */
    @NamespaceAccessible
    public class TestSObjectDisableBehaviourConstructor implements fflib_SObjectDomain.IConstructable{
        @NamespaceAccessible
        public fflib_SObjectDomain construct( List<SObject> sObjectList ){
            return new TestSObjectDisableBehaviour( sObjectList );
        }
    }
}