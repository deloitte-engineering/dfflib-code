/**
 * Copyright (c), FinancialForce.com, inc
 * Copyright (c), Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
@IsTest
public class fflib_SObjectMocks{
    public virtual class SObjectDomain implements fflib_ISObjectDomain{
        private fflib_ApexMocks mocks;

        public SObjectDomain( fflib_ApexMocks mocks ){
            this.mocks = mocks;
        }

        public Schema.SObjectType sObjectType(){
            return ( Schema.SObjectType ) mocks.mockNonVoidMethod( this, 'sObjectType', new List<Type>{}, new List<Object>{} );
        }

        public List<SObject> getRecords(){
            return ( List<SObject> ) mocks.mockNonVoidMethod( this, 'getRecords', new List<Type>{}, new List<Object>{} );
        }

        public Object getType(){
            return sObjectType();
        }

        public List<Object> getObjects(){
            return getRecords();
        }

        public Boolean verifyTriggerEventSupported( fflib_SObjectDomain.TriggerEvent evt ){
            return ( Boolean ) mocks.mockNonVoidMethod( this, 'verifyTriggerEventSupported', new List<Type>{ fflib_SObjectDomain.TriggerEvent.class }, new List<Object>{ evt } );
        }
    }

    public virtual class SObjectSelector implements fflib_ISObjectSelector{
        private fflib_ApexMocks mocks;

        public SObjectSelector( fflib_ApexMocks mocks ){
            this.mocks = mocks;
        }

        public Schema.SObjectType sObjectType(){
            return ( Schema.SObjectType ) mocks.mockNonVoidMethod( this, 'sObjectType', new List<Type>{}, new List<Object>{} );
        }

        public List<SObject> selectSObjectsById( Set<Id> idSet ){
            return ( List<SObject> ) mocks.mockNonVoidMethod( this, 'selectSObjectsById', new List<Type>{ Set<Id>.class }, new List<Object>{ idSet } );
        }

        /**
         * Method for selecting records for deletion.
         * @param	queryConditionString	The query criteria (F.e. Origin = 'Phone')
         * @return	Database.QueryLocator containing the selection result.
         */
        public Database.QueryLocator selectDeleteBatchRecords( String queryConditionString ){
            return ( Database.QueryLocator ) mocks.mockNonVoidMethod( this, 'selectDeleteBatchRecords', new List<Type>{}, new List<Object>{} );
        }

        /**
         * Method for querying and retrieving all SObject records associated with the relevant SObjectType in context.
         *
         * @return	List<SObject> containing the selection result.
         */
        public List<SObject> selectAllSObjectRecords(){
            return ( List<SObject> ) mocks.mockNonVoidMethod( this, 'selectAllSObjectRecords', new List<Type>{}, new List<Object>{} );
        }

        public fflib_SObjectSelector setContext( fflib_Database.Context securityContext ){
            return ( fflib_SObjectSelector ) mocks.mockNonVoidMethod( this, 'setContext', new List<Type>{ fflib_Database.Context.class }, new List<Object>{ securityContext } );
        }

        public List<SObject> executeQuery( String query ){
            return ( List<SObject> ) mocks.mockNonVoidMethod( this, 'executeQuery', new List<Type>{ String.class }, new List<Object>{ query } );
        }
        public List<SObject> executeQuery( fflib_QueryFactory qf ){
            return ( List<SObject> ) mocks.mockNonVoidMethod( this, 'executeQuery', new List<Type>{ fflib_QueryFactory.class }, new List<Object>{ qf } );
        }
        public List<SObject> executeQuery( String query, Map<String, Object> bindVariablesMap ){
            return ( List<SObject> ) mocks.mockNonVoidMethod( this, 'executeQuery', new List<Type>{ String.class, Map<String, Object>.class }, new List<Object>{ query, bindVariablesMap } );
        }
        public List<SObject> executeQuery( fflib_QueryFactory qf, Map<String, Object> bindVariablesMap ){
            return ( List<SObject> ) mocks.mockNonVoidMethod( this, 'executeQuery', new List<Type>{ fflib_QueryFactory.class, Map<String, Object>.class }, new List<Object>{ qf, bindVariablesMap } );
        }

        public List<fflib_AggregateResult> executeAggregateQuery( String query ){
            return ( List<fflib_AggregateResult> ) mocks.mockNonVoidMethod( this, 'executeAggregateQuery', new List<Type>{ String.class }, new List<Object>{ query } );
        }
        public List<fflib_AggregateResult> executeAggregateQuery( fflib_QueryFactory qf ){
            return ( List<fflib_AggregateResult> ) mocks.mockNonVoidMethod( this, 'executeAggregateQuery', new List<Type>{ fflib_QueryFactory.class }, new List<Object>{ qf } );
        }
        public List<fflib_AggregateResult> executeAggregateQuery( String query, Map<String, Object> bindVariablesMap ){
            return ( List<fflib_AggregateResult> ) mocks.mockNonVoidMethod( this, 'executeAggregateQuery', new List<Type>{ String.class, Map<String, Object>.class }, new List<Object>{ query, bindVariablesMap } );
        }
        public List<fflib_AggregateResult> executeAggregateQuery( fflib_QueryFactory qf, Map<String, Object> bindVariablesMap ){
            return ( List<fflib_AggregateResult> ) mocks.mockNonVoidMethod( this, 'executeAggregateQuery', new List<Type>{ fflib_QueryFactory.class, Map<String, Object>.class }, new List<Object>{ qf, bindVariablesMap } );
        }

        public Database.QueryLocator getQueryLocator( String query ){
            return ( Database.QueryLocator ) mocks.mockNonVoidMethod( this, 'getQueryLocator', new List<Type>{ String.class }, new List<Object>{ query } );
        }
        public Database.QueryLocator getQueryLocator( fflib_QueryFactory qf ){
            return ( Database.QueryLocator ) mocks.mockNonVoidMethod( this, 'getQueryLocator', new List<Type>{ fflib_QueryFactory.class }, new List<Object>{ qf } );
        }
        public Database.QueryLocator getQueryLocator( String query, Map<String, Object> bindVariablesMap ){
            return ( Database.QueryLocator ) mocks.mockNonVoidMethod( this, 'getQueryLocator', new List<Type>{ String.class, Map<String, Object>.class }, new List<Object>{ query, bindVariablesMap } );
        }
        public Database.QueryLocator getQueryLocator( fflib_QueryFactory qf, Map<String, Object> bindVariablesMap ){
            return ( Database.QueryLocator ) mocks.mockNonVoidMethod( this, 'getQueryLocator', new List<Type>{ fflib_QueryFactory.class, Map<String, Object>.class }, new List<Object>{ qf, bindVariablesMap } );
        }
    }

    public virtual class SObjectUnitOfWork implements fflib_ISObjectUnitOfWork{
        private fflib_ApexMocks mocks;

        public SObjectUnitOfWork( fflib_ApexMocks mocks ){
            this.mocks = mocks;
        }

        public void setContext( fflib_Database.Context securityContext ){
            mocks.mockVoidMethod( this, 'setContext', new List<Type>{ Type.forName( 'fflib_Database.Context' ) }, new List<Object>{ securityContext } );
        }

        public void registerPriorityNew( SObject record ){
            mocks.mockVoidMethod( this, 'registerPriorityNew', new List<Type>{ SObject.class }, new List<Object>{ record } );
        }
        public void registerPriorityNew( List<SObject> records ){
            mocks.mockVoidMethod( this, 'registerPriorityNew', new List<Type>{ List<SObject>.class }, new List<Object>{ records } );
        }
        public void registerPriorityNew( SObject record, Schema.SObjectField relatedToParentField, SObject relatedToParentRecord ){
            mocks.mockVoidMethod( this, 'registerPriorityNew', new List<Type>{ SObject.class, Schema.SObjectField.class, SObject.class }, new List<Object>{ record, relatedToParentField, relatedToParentRecord } );
        }

        public void registerNew( SObject record ){
            mocks.mockVoidMethod( this, 'registerNew', new List<Type>{ SObject.class }, new List<Object>{ record } );
        }

        public void registerNew( List<SObject> records ){
            mocks.mockVoidMethod( this, 'registerNew', new List<Type>{ List<SObject>.class }, new List<Object>{ records } );
        }

        public void registerNew( SObject record, Schema.SObjectField relatedToParentField, SObject relatedToParentRecord ){
            mocks.mockVoidMethod( this, 'registerNew', new List<Type>{ SObject.class, Schema.SObjectField.class, SObject.class }, new List<Object>{ record, relatedToParentField, relatedToParentRecord } );
        }

        public void registerNewImmediate( List<SObject> records ){
            mocks.mockVoidMethod( this, 'registerNewImmediate', new List<Type>{ List<SObject>.class }, new List<Object>{ records } );
        }
        public void registerNewImmediate( SObject record ){
            mocks.mockVoidMethod( this, 'registerNewImmediate', new List<Type>{ SObject.class }, new List<Object>{ record } );
        }

        public void registerRelationship( SObject record, Schema.SObjectField relatedToField, SObject relatedTo ){
            mocks.mockVoidMethod( this, 'registerRelationship', new List<Type>{ SObject.class, Schema.SObjectField.class, SObject.class }, new List<Object>{ record, relatedToField, relatedTo } );
        }

        public void registerRelationship( SObject record, Schema.SObjectField relatedToField, SObject relatedTo, fflib_SObjectUnitOfWork.DMLActions specificDMLAction ){
            mocks.mockVoidMethod( this, 'registerRelationship', new List<Type>{ SObject.class, Schema.SObjectField.class, SObject.class }, new List<Object>{ record, relatedToField, relatedTo } );
        }

        public void registerRelationship( Messaging.SingleEmailMessage email, SObject relatedTo ){
            mocks.mockVoidMethod( this, 'registerRelationship', new List<Type>{ Messaging.SingleEmailMessage.class, SObject.class }, new List<Object>{ email, relatedTo } );
        }

        public void registerRelationship( Approval.ProcessRequest process, SObject relatedTo ){
            mocks.mockVoidMethod( this, 'registerRelationship', new List<Type>{ Approval.ProcessRequest.class, SObject.class }, new List<Object>{ process, relatedTo } );
        }

        public void registerRelationship( SObject record, Schema.SObjectField relatedToField, Schema.SObjectField externalIdField, Object externalId ){
            mocks.mockVoidMethod( this, 'registerRelationship', new List<Type>{ SObject.class, Schema.SObjectField.class, Schema.SObjectField.class, Object.class }, new List<Object>{ record, relatedToField, externalIdField, externalId } );
        }

        public void registerRelationship( SObject record, Schema.SObjectField relatedToField, Schema.SObjectField externalIdField, Object externalId, fflib_SObjectUnitOfWork.DMLActions specificDMLAction ){
            mocks.mockVoidMethod( this, 'registerRelationship', new List<Type>{ SObject.class, Schema.SObjectField.class, Schema.SObjectField.class, Object.class, fflib_SObjectUnitOfWork.DMLActions.class }, new List<Object>{ record, relatedToField, externalIdField, externalId, specificDMLAction } );
        }

        public void registerPriorityDirty( SObject record ){
            mocks.mockVoidMethod( this, 'registerPriorityDirty', new List<Type>{ SObject.class }, new List<Object>{ record } );
        }
        public void registerPriorityDirty( List<SObject> records ){
            mocks.mockVoidMethod( this, 'registerPriorityDirty', new List<Type>{ List<SObject>.class }, new List<Object>{ records } );
        }
        public void registerPriorityDirty( SObject record, Schema.SObjectField relatedToParentField, SObject relatedToParentRecord ){
            mocks.mockVoidMethod( this, 'registerPriorityDirty', new List<Type>{ SObject.class, Schema.SObjectField.class, SObject.class }, new List<Object>{ record, relatedToParentField, relatedToParentRecord } );
        }

        public void registerDirty( SObject record ){
            mocks.mockVoidMethod( this, 'registerDirty', new List<Type>{ SObject.class }, new List<Object>{ record } );
        }
        public void registerDirty( List<SObject> records ){
            mocks.mockVoidMethod( this, 'registerDirty', new List<Type>{ List<SObject>.class }, new List<Object>{ records } );
        }

        public void registerDirty( SObject record, List<SObjectField> dirtyFields ){
            mocks.mockVoidMethod( this, 'registerDirty', new List<Type>{ SObject.class, System.Type.forName( 'List<SObjectField>' ) }, new List<Object>{ record, dirtyFields } );
        }
        public void registerDirty( List<SObject> records, List<SObjectField> dirtyFields ){
            mocks.mockVoidMethod( this, 'registerDirty', new List<Type>{ List<SObject>.class, System.Type.forName( 'List<SObjectField>' ) }, new List<Object>{ records, dirtyFields } );
        }

        public void registerDirty( SObject record, Schema.SObjectField relatedToParentField, SObject relatedToParentRecord ){
            mocks.mockVoidMethod( this, 'registerDirty', new List<Type>{ SObject.class, Schema.SObjectField.class, SObject.class }, new List<Object>{ record, relatedToParentField, relatedToParentRecord } );
        }

        public void registerDirty( SObject record, List<SObjectField> dirtyFields, Schema.SObjectField relatedToParentField, SObject relatedToParentRecord ){
            mocks.mockVoidMethod( this, 'registerDirty', new List<Type>{ SObject.class, System.Type.forName( 'List<SObjectField>' ), Schema.SObjectField.class, SObject.class }, new List<Object>{ record, dirtyFields, relatedToParentField, relatedToParentRecord } );
        }

        public void registerDirtyImmediate( SObject record ){
            mocks.mockVoidMethod( this, 'registerDirtyImmediate', new List<Type>{ SObject.class }, new List<Object>{ record } );
        }
        public void registerDirtyImmediate( List<SObject> records ){
            mocks.mockVoidMethod( this, 'registerDirtyImmediate', new List<Type>{ List<SObject>.class }, new List<Object>{ records } );
        }

        public void registerUpsert( SObject record ){
            mocks.mockVoidMethod( this, 'registerUpsert', new List<Type>{ List<SObject>.class }, new List<Object>{ record } );
        }

        public void registerEmptyRecycleBin( SObject record ){
            mocks.mockVoidMethod( this, 'registerEmptyRecycleBin', new List<Type>{ List<SObject>.class }, new List<Object>{ record } );
        }

        public void registerEmptyRecycleBin( List<SObject> records ){
            mocks.mockVoidMethod( this, 'registerEmptyRecycleBin', new List<Type>{ List<SObject>.class }, new List<Object>{ records } );
        }

        public void registerUpsert( List<SObject> records ){
            mocks.mockVoidMethod( this, 'registerUpsert', new List<Type>{ List<SObject>.class }, new List<Object>{ records } );
        }

        public void registerDeleted( SObject record ){
            mocks.mockVoidMethod( this, 'registerDeleted', new List<Type>{ SObject.class }, new List<Object>{ record } );
        }

        public void registerPriorityDeleted( SObject record ){
            mocks.mockVoidMethod( this, 'registerPriorityDeleted', new List<Type>{ SObject.class }, new List<Object>{ record } );
        }
        public void registerPriorityDeleted( List<SObject> records ){
            mocks.mockVoidMethod( this, 'registerPriorityDeleted', new List<Type>{ List<SObject>.class }, new List<Object>{ records } );
        }

        public void registerDeleted( List<SObject> records ){
            mocks.mockVoidMethod( this, 'registerDeleted', new List<Type>{ List<SObject>.class }, new List<Object>{ records } );
        }

        public void registerDeletedImmediate( SObject record ){
            mocks.mockVoidMethod( this, 'registerDeletedImmediate', new List<Type>{ SObject.class }, new List<Object>{ record } );
        }
        public void registerDeletedImmediate( List<SObject> records ){
            mocks.mockVoidMethod( this, 'registerDeletedImmediate', new List<Type>{ List<SObject>.class }, new List<Object>{ records } );
        }

        public void registerPermanentlyDeleted( SObject record ){
            mocks.mockVoidMethod( this, 'registerPermanentlyDeleted', new List<Type>{ SObject.class }, new List<Object>{ record } );
        }

        public void registerPermanentlyDeleted( List<SObject> records ){
            mocks.mockVoidMethod( this, 'registerPermanentlyDeleted', new List<Type>{ SObject.class }, new List<Object>{ records } );
        }

        public void registerUndeleted( SObject record ){
            mocks.mockVoidMethod( this, 'registerUndeleted', new List<Type>{ SObject.class }, new List<Object>{ record } );
        }

        public void registerUndeleted( List<SObject> records ){
            mocks.mockVoidMethod( this, 'registerUndeleted', new List<Type>{ List<SObject>.class }, new List<Object>{ records } );
        }

        public void registerNewAllOrNone( Schema.SObjectType sType, Boolean allOrNone ){
            mocks.mockVoidMethod( this, 'registerNewAllOrNone', new List<Type>{ Type.forName( 'Schema.SObjectType' ), Boolean.class }, new List<Object>{ sType, allOrNone } );
        }

        public void registerDirtyAllOrNone( Schema.SObjectType sType, Boolean allOrNone ){
            mocks.mockVoidMethod( this, 'registerDirtyAllOrNone', new List<Type>{ Type.forName( 'Schema.SObjectType' ), Boolean.class }, new List<Object>{ sType, allOrNone } );
        }

        public void registerDeletedAllOrNone( Schema.SObjectType sType, Boolean allOrNone ){
            mocks.mockVoidMethod( this, 'registerDeletedAllOrNone', new List<Type>{ Type.forName( 'Schema.SObjectType' ), Boolean.class }, new List<Object>{ sType, allOrNone } );
        }

        public void registerUndeletedAllOrNone( Schema.SObjectType sType, Boolean allOrNone ){
            mocks.mockVoidMethod( this, 'registerUndeletedAllOrNone', new List<Type>{ Type.forName( 'Schema.SObjectType' ), Boolean.class }, new List<Object>{ sType, allOrNone } );
        }

        public void registerPublishBeforeTransaction( SObject record ){
            mocks.mockVoidMethod( this, 'registerPublishBeforeTransaction', new List<Type>{ SObject.class }, new List<Object>{ record } );
        }

        public void registerPublishBeforeTransaction( List<SObject> records ){
            mocks.mockVoidMethod( this, 'registerPublishBeforeTransaction', new List<Type>{ List<SObject>.class }, new List<Object>{ records } );
        }

        public void registerPublishAfterSuccessTransaction( SObject record ){
            mocks.mockVoidMethod( this, 'registerPublishAfterSuccessTransaction', new List<Type>{ SObject.class }, new List<Object>{ record } );
        }
        public void registerPublishAfterSuccessTransaction( List<SObject> records ){
            mocks.mockVoidMethod( this, 'registerPublishAfterSuccessTransaction', new List<Type>{ List<SObject>.class }, new List<Object>{ records } );
        }
        public void registerPublishAfterFailureTransaction( SObject record ){
            mocks.mockVoidMethod( this, 'registerPublishAfterFailureTransaction', new List<Type>{ SObject.class }, new List<Object>{ record } );
        }
        public void registerPublishAfterFailureTransaction( List<SObject> records ){
            mocks.mockVoidMethod( this, 'registerPublishAfterFailureTransaction', new List<Type>{ List<SObject>.class }, new List<Object>{ records } );
        }

        public Boolean hasWork(){
            return ( Boolean ) mocks.mockNonVoidMethod( this, 'hasWork', new List<Type>(), new List<Object>() );
        }

        public void commitWork(){
            mocks.mockVoidMethod( this, 'commitWork', new List<Type>{}, new List<Object>{} );
        }

        public void resetWork(){
            mocks.mockVoidMethod( this, 'reset', new List<Type>{}, new List<Object>{} );
        }

        public void resetSaveResults(){
            mocks.mockVoidMethod( this, 'resetSaveResults', new List<Type>{}, new List<Object>{} );
        }

        public void registerWork( fflib_SObjectUnitOfWork.IDoWork work ){
            mocks.mockVoidMethod( this, 'registerWork', new List<Type>{ fflib_SObjectUnitOfWork.IDoWork.class }, new List<Object>{ work } );
        }

        public void registerEmail( Messaging.Email email ){
            mocks.mockVoidMethod( this, 'registerEmail', new List<Type>{ Messaging.Email.class }, new List<Object>{ email } );
        }

        public void registerEmail( Messaging.SingleEmailMessage email, SObject relatedTo ){
            mocks.mockVoidMethod( this, 'registerEmail', new List<Type>{ Messaging.SingleEmailMessage.class, SObject.class }, new List<Object>{ email, relatedTo } );
        }

        public void registerApprovalProcess( Approval.ProcessRequest approvalProcess ){
            mocks.mockVoidMethod( this, 'registerApprovalProcess', new List<Type>{ Approval.ProcessRequest.class }, new List<Object>{ approvalProcess } );
        }
        public void registerApprovalProcess( Approval.ProcessRequest approvalProcess, SObject relatedTo ){
            mocks.mockVoidMethod( this, 'registerApprovalProcess', new List<Type>{ Approval.ProcessRequest.class, SObjectType.class }, new List<Object>{ approvalProcess, relatedTo } );
        }

        public void registerNewDmlOptions( Schema.SObjectType sType, Database.DMLOptions options ){
            mocks.mockVoidMethod( this, 'registerNewDmlOptions', new List<Type>{ Type.forName( 'Schema.SObjectType' ), Database.DMLOptions.class }, new List<Object>{ sType, options } );
        }

        public void registerDirtyDmlOptions( Schema.SObjectType sType, Database.DMLOptions options ){
            mocks.mockVoidMethod( this, 'registerDirtyDmlOptions', new List<Type>{ Type.forName( 'Schema.SObjectType' ), Database.DMLOptions.class }, new List<Object>{ sType, options } );
        }

        public void setSaveResultsRequired( Boolean enabled ){
            mocks.mockVoidMethod( this, 'setSaveResultsRequired', new List<Type>{ Boolean.class }, new List<Object>{ enabled } );
        }
        public List<Database.SaveResult> getNewResults( SObjectType sObjType ){
            return ( List<Database.SaveResult> ) mocks.mockNonVoidMethod( this, 'getNewResults', new List<Type>{ SObjectType.class }, new List<Object>{ sObjType } );
        }
        public List<Database.SaveResult> getDirtyResults( SObjectType sObjType ){
            return ( List<Database.SaveResult> ) mocks.mockNonVoidMethod( this, 'getDirtyResults', new List<Type>{ SObjectType.class }, new List<Object>{ sObjType } );
        }
        public List<Database.DeleteResult> getDeletedResults( SObjectType sObjType ){
            return ( List<Database.DeleteResult> ) mocks.mockNonVoidMethod( this, 'getDeletedResults', new List<Type>{ SObjectType.class }, new List<Object>{ sObjType } );
        }
        public List<Database.UndeleteResult> getUndeletedResults( SObjectType sObjType ){
            return ( List<Database.UndeleteResult> ) mocks.mockNonVoidMethod( this, 'getUndeletedResults', new List<Type>{ SObjectType.class }, new List<Object>{ sObjType } );
        }
        public List<Database.EmptyRecycleBinResult> getEmptyRecycleBinResults( SObjectType sObjType ){
            return ( List<Database.EmptyRecycleBinResult> ) mocks.mockNonVoidMethod( this, 'getEmptyRecycleBin', new List<Type>{ SObjectType.class }, new List<Object>{ sObjType } );
        }
        public List<Database.SaveResult> getPublishResults( SObjectType sObjType ){
            return ( List<Database.SaveResult> ) mocks.mockNonVoidMethod( this, 'getPublishResults', new List<Type>{ SObjectType.class }, new List<Object>{ sObjType } );
        }
        public List<Messaging.SendEmailResult> getEmailResults(){
            return ( List<Messaging.SendEmailResult> ) mocks.mockNonVoidMethod( this, 'getEmailResults', new List<Type>(), new List<Object>() );
        }
        public List<Approval.ProcessResult> getApprovalProcessResults(){
            return ( List<Approval.ProcessResult> ) mocks.mockNonVoidMethod( this, 'getApprovalProcessResults', new List<Type>(), new List<Object>() );
        }
    }
}
