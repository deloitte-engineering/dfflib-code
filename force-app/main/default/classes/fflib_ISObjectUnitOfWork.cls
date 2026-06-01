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
 *  Interface listing all methods available and required for fflib_ISObjectUnitOfWork 2.0
 *
 *  Inspiration based on Apex-Commons repository from FinancialForce.com, Inc
 *
 *  @author    Reinier van den Assum (rvandenassum@deloitte.nl)
 *  @created   December 2020
 */
public interface fflib_ISObjectUnitOfWork{
    /**
     * Setter to allow changing the database security context when committing records to the database. The default is INHERIT to match the sharing context, without explicit CRUD/FLS checks.
     * This method allows to be explicit on which security context should DML operations be ran.
     *
     * @param   securityContext     Database security context of this instance
     */
    void setContext( fflib_Database.Context securityContext );

    /**
     * Register a newly created SObject instance to be inserted when commitWork is called
     *
     * @param   record      A newly created SObject instance to be inserted during commitWork
     */
    void registerNew( SObject record );
    void registerNew( List<SObject> records );

    /**
     * Register a newly created SObject instance to be inserted when commitWork is called, you may also provide a reference
     * to the parent record instance (should also be registered as new separately)
     *
     * @param   record                  A newly created SObject instance to be inserted during commitWork
     * @param   relatedToParentField    The SObjectField that associates the child record with its parent
     * @param   relatedToParentRecord   A SObject instance of the parent record (should also be registered as new separately)
     */
    void registerNew( SObject record, Schema.SObjectField relatedToParentField, SObject relatedToParentRecord );

    /**
     * For specific scenarios you may wish to register new records to be inserted into the database before other records
     * within the same transaction are inserted to enable relationships to be populated correctly. E.g. inserting a
     * parent and child record of the same sObject type could not be linked together in the same unit of work otherwise.
     *
     * @param   record                  A newly created SObject instance to be inserted during commitWork
     * @param   relatedToParentField    The SObjectField that associates the child record with its parent
     * @param   relatedToParentRecord   A SObject instance of the parent record (should also be registered as new separately)
     */
    void registerPriorityNew( SObject record, Schema.SObjectField relatedToParentField, SObject relatedToParentRecord );
    void registerPriorityNew( SObject record );
    void registerPriorityNew( List<SObject> records );

    /**
     * Method to register records to be inserted using Database.insertImmediate();
     * This is used for external, Big or special Objects (like ThirdPartyAccountLinks)
     *
     * @param record An instance of an External, Big or Special object to be inserted immediately
     */
    void registerNewImmediate( SObject record );
    void registerNewImmediate( List<SObject> records );

    /**
     * Register an existing record to be updated during the commitWork method
     *
     * @param   record  An existing record
     */
    void registerDirty( SObject record );
    void registerDirty( List<SObject> records );

    /**
     * Register specific fields on an existing record to be updated when work is committed.
     *
     * When called after registerDirty(record), only the specified fields on existing record get updated.
     * When called first time, a new clean instance is made and only the specified fields are populated.
     * When called followed by registerDirty(record), an exception is thrown, due to mismatch in memory reference.
     *  NOTE: no reference is kept in this function. When applying registerDirty( record, fields ), then altering the input record,
     *      one will have to call registerDirty( fields ) again to make sure those changes are included in the commitWork
     *
     * @param   record              An existing record
     * @param   dirtyFields         The list of fields to be updated only
     */
    void registerDirty( SObject record, List<SObjectField> dirtyFields );
    void registerDirty( List<SObject> record, List<SObjectField> dirtyFields );

    /**
     * Register an existing record to be updated, while ensuring a reference/lookup is populated before performing the update
     * Allowing a parent record to be inserted by the same UOW as the child record to be referenced to
     *
     * @param   record                  The SObject instance to be updated
     * @param   relatedToParentField    The SObjectField reference to the field that associates the child record with its parent
     * @param   relatedToParentRecord   The SObject instance of the parent record (should be registered as new separately!)
     */
    void registerDirty( SObject record, Schema.SObjectField relatedToParentField, SObject relatedToParentRecord );

    /**
     * Method to allow registering only some of the record variables fields, while also referencing a relationship to be resolved
     * Method mainly introduced to centralize both logics for dirtyFields and relationshipFields to ensure all checks are performed in all cases
     *
     * @param record                    The SObject instance to be updated
     * @param dirtyFields               Opt. list of SObjectFields specifying which fields to update in the database
     * @param relatedToParentField      Opt. SObjectField detailing the relation from this SObjectType to the parent (lookup) to populate
     * @param relatedToParentRecord     Opt. SObject referring to the parent record, which should be registeredNew separately to retrieve an ID in the UOW before update
     */
    void registerDirty( SObject record, List<SObjectField> dirtyFields, Schema.SObjectField relatedToParentField, SObject relatedToParentRecord );

    /**
     * For specific scenarios you may wish to register records to be updated into the database before other records
     * within the same transaction are inserted to enable standard required to be populated correctly.
     *
     * @param   record                  An existing SObject instance to be updated during commitWork
     * @param   relatedToParentField    The SObjectField that associates the child record with its parent
     * @param   relatedToParentRecord   A SObject instance of the parent record (should also be registered as new separately)
     */
    void registerPriorityDirty( SObject record, Schema.SObjectField relatedToParentField, SObject relatedToParentRecord );
    void registerPriorityDirty( SObject record );
    void registerPriorityDirty( List<SObject> records );

    /**
     * Method to register records to be updated using Database.updatedImmediate();
     * This is used for external, Big or special Objects (like ThirdPartyAccountLinks)
     *
     * @param record An instance of an External, Big or Special object to be updated immediately
     */
    void registerDirtyImmediate( SObject record );
    void registerDirtyImmediate( List<SObject> records );

    /**
     * Register a new or existing record to be inserted or updated during the commitWork method
     *
     * @param   record      An new or existing record
     */
    void registerUpsert( SObject record );
    void registerUpsert( List<SObject> records );

    /**
     * Register an existing record to be deleted during the commitWork method
     *
     * @param   record      An existing record
     */
    void registerDeleted( SObject record );
    void registerDeleted( List<SObject> records );

    /**
     * For specific scenarios you may wish to register records to be deleted into the database before other records
     * within the same transaction are inserted/Updated to enable standard required to be populated correctly.
     *
     * @param record An existing record
     **/
    void registerPriorityDeleted( SObject record );
    void registerPriorityDeleted( List<SObject> record );

    /**
     * Method to register records to be deleted using Database.deleteImmediate();
     * This is used for external, Big or special Objects (like ThirdPartyAccountLinks)
     *
     * @param record An instance of an External, Big or Special object to be deleted immediately
     */
    void registerDeletedImmediate( SObject record );
    void registerDeletedImmediate( List<SObject> records );

    /**
     * Register an existing record to be deleted and removed from the recycle bin during the commitWork method
     *
     * @param   record      An existing record
     */
    void registerPermanentlyDeleted( SObject record );
    void registerPermanentlyDeleted( List<SObject> records );

    /**
     * Register an deleted record to be removed from the recycle bin during the commitWork method
     *
     * @param   record      An deleted record
	 */
    void registerEmptyRecycleBin( SObject record );
    void registerEmptyRecycleBin( List<SObject> records );

    /**
     * Register an existing record to be undeleted during the commitWork method
     *
     * @param   record      An existing record
     */
    void registerUndeleted( SObject record );
    void registerUndeleted( List<SObject> records );

    /**
     * Register a newly created SObject (Platform Event) instance to be published when commitWork is called
     *
     * @param   record      A newly created SObject (Platform Event) instance to be inserted during commitWork
     */
    void registerPublishBeforeTransaction( SObject record );
    void registerPublishBeforeTransaction( List<SObject> records );

    /**
     * Register a newly created SObject (Platform Event) instance to be published when commitWork has caused an error
     *
     * @param   record      A newly created SObject (Platform Event) instance to be inserted during commitWork
     */
    void registerPublishAfterFailureTransaction( SObject record );
    void registerPublishAfterFailureTransaction( List<SObject> records );

    /**
     * Register a newly created SObject (Platform Event) instance to be published when commitWork has successfully
     * completed
     *
     * @param   record      A newly created SObject (Platform Event) instance to be inserted during commitWork
     */
    void registerPublishAfterSuccessTransaction( SObject record );
    void registerPublishAfterSuccessTransaction( List<SObject> records );

    /**
     * Register a generic peace of work to be invoked during the commitWork phase
     *
     * @param   work    Work to be registered
     */
    void registerWork( fflib_SObjectUnitOfWork.IDoWork work );

    /**
     * Registers the given email to be sent during the commitWork
     *
     * @param   email   Email to be sent
     */
    void registerEmail( Messaging.Email email );
    void registerEmail( Messaging.SingleEmailMessage email, SObject relatedTo );

    /**
     * Registers the given approval process to be sent during the commitWork
     *
     * @param   approvalProcess     ApprovalProcess to be sent
     */
    void registerApprovalProcess( Approval.ProcessRequest approvalProcess );
    void registerApprovalProcess( Approval.ProcessRequest process, SObject relatedTo );

    /**
     * Register a relationship between two records that have yet to be inserted to the database. This information will be
     * used during the commitWork phase to make the references only when related records have been inserted to the database.
     *
     * @param   record              An existing or newly created record
     * @param   relatedToField      A SObjectField reference to the lookup field that relates the two records together
     * @param   relatedTo           A SObject instance (yet to be committed to the database)
     */
    void registerRelationship( SObject record, Schema.SObjectField relatedToField, SObject relatedTo );
    void registerRelationship( SObject record, Schema.SObjectField relatedToField, SObject relatedTo, fflib_SObjectUnitOfWork.DMLActions specificDMLAction );

    /**
     * Registers a relationship between a record and a lookup value using an external ID field and a provided value. This
     * information will be used during the commitWork phase to make the lookup reference requested when inserted to the database.
     *
     * @param   record              An existing or newly created record
     * @param   relatedToField      A SObjectField reference to the lookup field that relates the two records together
     * @param   externalIdField     A SObjectField reference to a field on the target SObject that is marked as isExternalId
     * @param   externalId          A Object representing the targeted value of the externalIdField in said lookup
     *
     * Usage Example: uow.registerRelationship(recordSObject, record_sobject__c.relationship_field__c, lookup_sobject__c.external_id__c, 'abc123');
     *
     * Wraps putSObject, creating a new instance of the lookup sobject using the external id field and value.
     */
    void registerRelationship( SObject record, Schema.SObjectField relatedToField, Schema.SObjectField externalIdField, Object externalId );
    void registerRelationship( SObject record, Schema.SObjectField relatedToField, Schema.SObjectField externalIdField, Object externalId, fflib_SObjectUnitOfWork.DMLActions specificDMLAction );

    /**
     * Registers a relationship between a record and a Messaging.Email where the record has yet to be inserted
     * to the database. This information will be used during the commitWork phase to make the references only when related
     * records have been inserted to the database.
     *
     * @param   email       Single email message instance
     * @param   relatedTo   A SObject instance (yet to be committed to the database)
     */
    void registerRelationship( Messaging.SingleEmailMessage email, SObject relatedTo );

    /**
     * Registers a relationship between a record and a Approval.ProcessRequest where the record has yet to be inserted
     * to the database. This information will be used during the commitWork phase to make the references only when related
     * records have been inserted to the database.
     *
     * @param   process     Single approval process message instance
     * @param   relatedTo   A SObject instance (yet to be committed to the database)
     */
    void registerRelationship( Approval.ProcessRequest process, SObject relatedTo );

    /**
     * Registers DML options which should be used for a sObject type when inserting. This will be applied for all
     * records of the same sObject type within the unit of work.
     *
     * @param   sType       SObject type to apply the DML options to.
     * @param   options     The DML options to be applied to the records being inserted.
     */
    void registerNewDmlOptions( Schema.SObjectType sType, Database.DMLOptions options );

    /**
     * Registers DML options which should be used for a sObject type when updating. This will be applied for all
     * records of the same sObject type within the unit of work.
     *
     * @param   sType       SObject type to apply the DML options to.
     * @param   options     The DML options to be applied to the records being updated.
     */
    void registerDirtyDmlOptions( Schema.SObjectType sType, Database.DMLOptions options );

    /**
     * Allows setting the behavior of all or none when inserting new records for a given sObject type within the
     * unit of work.
     *
     * @param   sType       SObject type to apply the all or none value to.
     * @param   allOrNone   True if all records should succeed, otherwise best effort will be used.
     */
    void registerNewAllOrNone( Schema.SObjectType sType, Boolean allOrNone );

    /**
     * Allows setting the behavior of all or none when updating existing records for a given sObject type within the
     * unit of work.
     *
     * @param   sType       SObject type to apply the all or none value to.
     * @param   allOrNone   True if all records should succeed, otherwise best effort will be used.
     */
    void registerDirtyAllOrNone( Schema.SObjectType sType, Boolean allOrNone );

    /**
     * Allows setting the behavior of all or none when deleting existing records for a given sObject type within the
     * unit of work.
     *
     * @param   sType       SObject type to apply the all or none value to.
     * @param   allOrNone   True if all records should succeed, otherwise best effort will be used.
     */
    void registerDeletedAllOrNone( Schema.SObjectType sType, Boolean allOrNone );

    /**
     * Allows setting the behavior of all or none when undeleting existing records for a given sObject type within the
     * unit of work.
     *
     * @param   sType           SObject type to apply the all or none value to.
     * @param   allOrNone       True if all records should succeed, otherwise best effort will be used.
     */
    void registerUndeletedAllOrNone( Schema.SObjectType sType, Boolean allOrNone );

    /**
     * @return true when any record or work was registered to be committed
     */
    Boolean hasWork();

    /**
     * Takes all the work that has been registered with the UnitOfWork and commits it to the database
     */
    void commitWork();

    /**
     * Method to explicitly allow to store or ignore SaveResults (default disabled for performance reasoning) during commitWork()
     * Note, SaveResults are only expected to be needed when DMLOptions.AllOrNone is set to false,
     * otherwise the transaction will fail at the first record failure and the DMLException shares the cause.
     * @param enabled   True to store SaveResults, False to skip logic for SaveResults
     */
    void setSaveResultsRequired( Boolean enabled );
    /**
     * @param sObjType The SObjectType for which to retrieve Insertion SaveResults
     * @return SaveResults for inserts on given SObjectType. null when no DMLs performed for that SObjectType, or storeSaveResults is false
     */
    List<Database.SaveResult> getNewResults( Schema.SObjectType sObjType );
    /**
     * @param sObjType The SObjectType for which to retrieve Update SaveResults
     * @return SaveResults for updates on given SObjectType. null when no DMLs performed for that SObjectType
     */
    List<Database.SaveResult> getDirtyResults( Schema.SObjectType sObjType );
    /**
     * @param sObjType The SObjectType for which to retrieve DeletedResults
     * @return DeleteResults for deletes on given SObjectType. null when no DMLs performed for that SObjectType
     */
    List<Database.DeleteResult> getDeletedResults( Schema.SObjectType sObjType );
    /**
     * @param sObjType The SObjectType for which to retrieve UndeleteResults
     * @return UndeleteResults for undeletes on given SObjectType. null when no DMLs performed for that SObjectType
     */
    List<Database.UndeleteResult> getUndeletedResults( Schema.SObjectType sObjType );
    /**
     * @param sObjType The SObjectType for which to retrieve EmptyRecycleBinResults
     * @return EmptyRecycleBinResult for emptyRecycleBins on given SObjectType. null when no DMLs performed for that SObjectType
     */
    List<Database.EmptyRecycleBinResult> getEmptyRecycleBinResults( Schema.SObjectType sObjType );
    /**
     * @param sObjType The SObjectType for which to retrieve Publish SaveResults
     * @return SaveResults for Published Events on given Event SObjectType. null when no DMLs performed for that SObjectType
     */
    List<Database.SaveResult> getPublishResults( Schema.SObjectType sObjType );
    /**
     * @return SaveResults for Send Emails. null when no Email Operation performed, or storeSaveResults is false
     */
    List<Messaging.SendEmailResult> getEmailResults();
    /**
     * @return SaveResults for Approval Processes. null when no Approval Operation performed, or storeSaveResults is false
     */
    List<Approval.ProcessResult> getApprovalProcessResults();

    /**
     * Clears all of the registered work within the unit of work instance to allow reusing the unit of work for
     * new work, whilst still maintaining the sObjectTypes defined.
     */
    void resetWork();
    /**
     * Clears all SaveResults from previous commitWork() calls whilst still maintaining the sObjectTypes defined.
     */
    void resetSaveResults();
}
