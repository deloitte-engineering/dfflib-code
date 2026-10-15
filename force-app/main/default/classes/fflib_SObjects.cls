/**
 * Copyright (c), FinancialForce.com, inc
 * Copyright (c), Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
/**
 *  Core domain class for a homogeneous collection of SObject records, encapsulating reusable domain behavior and business operations that apply to records of a single SObject type.
 *  Unlike the base Domain class (#fflib_SObjectDomain), this class does not handle trigger event dispatching. It is intended for domain logic that can be invoked independently or from services,
 *  and is fully testable in isolation via factory and mocks framework
 */
@NamespaceAccessible
public virtual with sharing class fflib_SObjects extends fflib_Objects implements fflib_ISObjects{

    /**
     * TODO: Class constructors added for full compatibility with parent interfaces fflib_ISObjects -> fflib_IObjects -> fflib_IDomain, to be revised with the consolidation of the base fflib_SObjectDomain implementation
     *  with the fflib_IDomain construction
     *  Git issue -> https://github.com/deloitte-engineering/dfflib/issues/3
     */
    /**
     * Derived from the records provided during construction, provides the native describe for the standard or custom object
     */
    @NamespaceAccessible
    public Schema.DescribeSObjectResult sObjectDescribe{ get; private set; }

    /**
     * Useful during unit testing to assert at a more granular and robust level for errors raised during the various trigger events
     **/
    @NamespaceAccessible
    public static ErrorFactory errorFactory{ get; private set; }

    static{
        errorFactory = new ErrorFactory();
    }

    @NamespaceAccessible
    public fflib_SObjects( List<SObject> records ){
        super( records );
    }

    @NamespaceAccessible
    public fflib_SObjects( List<SObject> records, Schema.SObjectType sObjectType ){
        super( records );
        // Capture SObjectType describe for this domain class
        sObjectDescribe = fflib_SObjectDescribe.getDescribe( sObjectType ).getDescribe();
    }

    private Integer numRecords { get {
        if( numRecords == null ){
            numRecords = this.getRecords().size();
        }
        return numRecords;
    } private set; }

    /**
     * Alternative to the Records property, provided to support mocking of Domain classes
     *
     * @return	List<SObject> representing the list of records in context
     */
    @NamespaceAccessible
    public virtual List<SObject> getRecords(){
        return ( List<SObject> ) getObjects();
    }

    @NamespaceAccessible
    public virtual override Object getType(){
        return getSObjectType();
    }

    /**
     * Returns the SObjectType this Domain class represents
     *
     * @return	SObjectType that represents this domain class
     */
    @NamespaceAccessible
    public virtual SObjectType getSObjectType(){
        return sObjectDescribe.getSObjectType();
    }

    /**
	 * Adds an error message to the records in the domain
	 *
	 * @param message The error message to add to each record
	 */
    @NamespaceAccessible
    public virtual void addError( String message ){
        List<SObject> records = getRecords();
        for( Integer i = 0; i < this.numRecords; i++ ){
            SObject record = records[ i ];
            record.addError( error( message, record ) );
        }
    }

    /**
     * Adds an error message to the a field records in the domain
     *
     * @param field The field where the error should be reported
     * @param message The error message to add to the given field on each record
     */
    @NamespaceAccessible
    public virtual void addError( Schema.SObjectField field, String message ){
        List<SObject> records = getRecords();
        for( Integer i = 0; i < this.numRecords; i++ ){
            SObject record = records[ i ];
            record.addError( field, error( message, record, field ) );
        }
    }

    /**
     * Clear the field value on all the records of the domain
     * @param field The field to nullify
     */
    @NamespaceAccessible
    public virtual void clearField( Schema.SObjectField field ){
        clearFields( new Set<Schema.SObjectField>{ field } );
    }

    /**
     * Clear the field values on all the records of the domain
     * @param fields The fields to nullify
     */
    @NamespaceAccessible
    public virtual void clearFields( Set<Schema.SObjectField> fields ){
        List<SObject> records = getRecords();
        for( Integer i = 0; i < this.numRecords; i++ ){
            SObject record = records[ i ];
            for( SObjectField field : fields ){
                record.put( field, null );
            }
        }
    }

    /**
     * Ensures logging of errors in the Domain context for later assertions in tests
     *
     * @param message
     * @param record
     *
     * @return Returns the Error message
     **/
    @NamespaceAccessible
    protected virtual String error( String message, SObject record ){
        return fflib_SObjects.errorFactory.error( this, message, record );
    }

    /**
     * Ensures logging of errors in the Domain context for later assertions in tests
     *
     * @param message
     * @param record
     * @param field
     *
     * @return Returns the Error message
     **/
    @NamespaceAccessible
    protected virtual String error( String message, SObject record, Schema.SObjectField field ){
        return fflib_SObjects.errorFactory.error( this, message, record, field );
    }

    /**
     * Collection efficiency retrieval methods
     */
    /**
     * METHODS: ID RETRIEVAL
     */
    /**
     * @return Set of Id's for all records in the domain
     */
    @NamespaceAccessible
    public virtual Set<Id> getRecordIds(){
        return new Map<Id, SObject>( getRecords() ).keySet();
    }

    /**
     * Method to 'pluck' Id's out of a collection of SObjects via a dotted relationship path.
     * Supports any depth of relationship (e.g. 'Owner.ContactId' or 'Parent.Owner.ManagerId'),
     * short-circuiting to no value whenever an intermediate relationship is unpopulated.
     *
     * @param fieldWithDotRelation The dotted relationship path (e.g. 'Owner.ContactId') to pluck the Id's from
     *
     * @return Set of Id's populated from the resolved relationship field, excluding null values
     */
    @NamespaceAccessible
    public virtual Set<Id> getParentIdFieldValues( String fieldWithDotRelation ){
        dfflib_Utils.verifyNotBlank( fieldWithDotRelation, 'fieldWithDotRelation' );

        Set<Id> result = new Set<Id>();
        List<String> relationshipParts = fieldWithDotRelation.split( '\\.' );
        Integer lastIndex = relationshipParts.size() - 1;
        List<SObject> records = getRecords();
        for( Integer i = 0; i < this.numRecords; i++ ){
            SObject current = records[ i ];
            for( Integer p = 0; p < lastIndex && current != null; p++ ){
                current = current.getSObject( relationshipParts[ p ] );
            }
            Id foundId = ( Id ) current?.get( relationshipParts[ lastIndex ] );
            if( foundId != null ){
                result.add( foundId );
            }
        }
        return result;
    }

    
    /**
     * METHODS: UNIQUE VALUES IN SPECIFIC FIELD
     */

    /**
     * Method to 'pluck' Id's out of a collection of SObjects, from a given Id field
     *
     * @param field The Id  SObjectField
     *
     * @return Return a set with all the Id values of the given field, including null values
     */
    @TestVisible
    @NamespaceAccessible
    protected Set<Id> getIdFieldValues( Schema.SObjectField field ){
        return getIdFieldValues( field, true );
    }

    /**
     * Method to 'pluck' Id's out of a collection of SObjects, from a given Id field
     *
     * @param field The Id field to fetch values from
     * @param includeNulls Set to true to include null values in the returned set
     *
     * @return Set of (unique) Id's populated from the given field
     */
    @TestVisible
    @NamespaceAccessible
    protected Set<Id> getIdFieldValues( Schema.SObjectField field, Boolean includeNulls ){
        dfflib_Utils.verifyNotNull( field, 'field' );
        dfflib_Utils.verifyNotNull( includeNulls, 'includeNulls' );

        Set<Id> result = new Set<Id>();
        List<SObject> records = getRecords();
        for( Integer i = 0; i < this.numRecords; i++ ){
            Id foundId = ( Id ) records[ i ].get( field );
            if( foundId != null || includeNulls ){
                result.add( foundId );
            }
        }
        return result;
    }

    /**
     * @param field The SObjectField reference of the type String
     *
     * @return Return a set with all the String values of the given field, including null/blank values
     */
    @TestVisible
    @NamespaceAccessible
    protected Set<String> getStringFieldValues( Schema.SObjectField field ){
        return getStringFieldValues( field, true );
    }

    /**
     * @param field The SObjectField reference of the type String
     * @param includeNulls Set to false to exclude null/blank values from the returned set
     *
     * @return Return a set with the String values of the given field
     */
    @TestVisible
    @NamespaceAccessible
    protected Set<String> getStringFieldValues( Schema.SObjectField field, Boolean includeNulls ){
        dfflib_Utils.verifyNotNull( field, 'field' );
        dfflib_Utils.verifyNotNull( includeNulls, 'includeNulls' );

        Set<String> result = new Set<String>();
        List<SObject> records = getRecords();
        for( Integer i = 0; i < this.numRecords; i++ ){
            String foundString = ( String ) records[ i ].get( field );
            if( String.isNotBlank( foundString ) || includeNulls ){
                result.add( foundString );
            }
        }
        return result;
    }

    /**
     * @param field The SObjectField reference
     *
     * @return Return a set with all the values of the given field
     */
    @TestVisible
    @NamespaceAccessible
    protected virtual Set<Object> getFieldValues( Schema.SObjectField field ){
        Set<Object> result = new Set<Object>();
        List<SObject> records = getRecords();
        for( Integer i = 0; i < this.numRecords; i++ ){
            result.add( records[ i ].get( field ) );
        }
        return result;
    }

    /**
     * METHODS: RECORD FILTERING FROM LIST BY FIELD VALUES
     */

    /**
     * @param field The Schema.SObjectField to compare against the given value
     * @param value The given value of the records field to include in the return
     *
     * @return A list with only the SObjects where the given field has the provided value
     */
    @NamespaceAccessible
    protected virtual List<SObject> getRecordsByFieldValue( Schema.SObjectField field, Object value ){
        return getRecordsByFieldValues( field, new Set<Object>{ value } );
    }

    /**
     * @param field The Schema.SObjectField to compare against the given value
     * @param values The given values of the records field to include in the return
     *
     * @return A list with only the SObjects where the given field value is part of the provided values
     */
    @NamespaceAccessible
    protected virtual List<SObject> getRecordsByFieldValues( Schema.SObjectField field, Set<Object> values ){
        dfflib_Utils.verifyNotNull( field, 'identifierField' );
        dfflib_Utils.verifyNotNull( values, 'identifierValues' );

        List<SObject> result = new List<SObject>();
        List<SObject> records = getRecords();
        for( Integer i = 0; i < this.numRecords; i++ ){
            SObject record = records[ i ];
            if( values.contains( record.get( field ) ) ){
                result.add( record );
            }
        }
        return result;
    }

    /**
     * @param field The Schema.SObjectField to check its value for a Blank value
     *
     * @return A list with only the SObjects where the given field value is either null or '')
     */
    @NamespaceAccessible
    protected virtual List<SObject> getRecordsWithBlankFieldValues( Schema.SObjectField field ){
        return getRecordsWithBlankFieldValues(
            new Set<Schema.SObjectField>{ field }
        );
    }

    /**
     * @param fields The Schema.SObjectFields to check their value for a Blank value
     *
     * @return A list with only the SObjects where the at least one given field value is either null or '')
     */
    @NamespaceAccessible
    protected virtual List<SObject> getRecordsWithBlankFieldValues( Set<Schema.SObjectField> fields ){
        dfflib_Utils.verifyNotNull( fields, 'identifierFields' );

        List<SObject> result = new List<SObject>();
        List<SObject> records = getRecords();
        for( Integer i = 0; i < this.numRecords; i++ ){
            SObject record = records[ i ];
            for( SObjectField field : fields ){
                if( String.isBlank( String.valueOf( record.get( field ) ) ) ){
                    result.add( record );
                    break;
                }
            }
        }
        return result;
    }

    /**
     * @param fields The Schema.SObjectFields to check their value for a Blank value
     *
     * @return A list with only the SObjects where all given field values are either null or ''
     */
    @NamespaceAccessible
    protected virtual List<SObject> getRecordsWithAllBlankFieldValues( Set<Schema.SObjectField> fields ){
        dfflib_Utils.verifyNotNull( fields, 'identifierFields' );

        List<SObject> result = new List<SObject>();
        List<SObject> records = getRecords();
        for( Integer i = 0; i < this.numRecords; i++ ){
            SObject record = records[ i ];
            Boolean allBlank = true;
            for( SObjectField field : fields ){
                if( String.isNotBlank( String.valueOf( record.get( field ) ) ) ){
                    allBlank = false;
                    break;
                }
            }
            if( allBlank ){
                result.add( record );
            }
        }
        return result;
    }

    /**
     * @param field The Schema.SObjectField to check its value for a Non-Blank value
     *
     * @return A list with only the SObjects where the given field value is not null or ''
     */
    @NamespaceAccessible
    protected virtual List<SObject> getRecordsWithNotBlankFieldValues( Schema.SObjectField field ){
        return getRecordsWithNotBlankFieldValues(
            new Set<Schema.SObjectField>{ field }
        );
    }

    /**
     * @param fields The Schema.SObjectFields to check their value for a Non-Blank value
     *
     * @return A list with only the SObjects where the at least one given field value not null or ''
     */
    @NamespaceAccessible
    protected virtual List<SObject> getRecordsWithNotBlankFieldValues( Set<Schema.SObjectField> fields ){
        dfflib_Utils.verifyNotNull( fields, 'identifierFields' );

        List<SObject> result = new List<SObject>();
        List<SObject> records = getRecords();
        for( Integer i = 0; i < this.numRecords; i++ ){
            SObject record = records[ i ];
            for( SObjectField field : fields ){
                if( String.isNotBlank( String.valueOf( record.get( field ) ) ) ){
                    result.add( record );
                    break;
                }
            }
        }
        return result;
    }

    /**
     * @param fields The Schema.SObjectFields to check their value for a Non-Blank value
     *
     * @return A list with only the SObjects where all given field values are not null or ''
     */
    @NamespaceAccessible
    protected virtual List<SObject> getRecordsWithAllNotBlankFieldValues( Set<Schema.SObjectField> fields ){
        dfflib_Utils.verifyNotNull( fields, 'identifierFields' );

        List<SObject> result = new List<SObject>();
        List<SObject> records = getRecords();
        for( Integer i = 0; i < this.numRecords; i++ ){
            SObject record = records[ i ];
            Boolean allNonBlank = true;
            for( SObjectField field : fields ){
                if( String.isBlank( String.valueOf( record.get( field ) ) ) ){
                    allNonBlank = false;
                    break;
                }
            }
            if( allNonBlank ){
                result.add( record );
            }
        }
        return result;
    }

    /**
     * METHODS: SET FIELD VALUE
     */

    /**
     * Modifies a value of a field for all records in the domain
     *
     * @param field The reference to the SObjectField to be modified
     * @param value The value to store in the given SObjectField
     */
    @NamespaceAccessible
    protected virtual void setFieldValue( Schema.SObjectField field, Object value ){
        List<SObject> records = getRecords();
        for( Integer i = 0; i < this.numRecords; i++ ){
            records[ i ].put( field, value );
        }
    }

    /**
     * @param fieldToCheck The SObjectField to match the key against in the provided map
     * @param fieldToUpdate The SObjectField to store the mapped value when the key matches the value in the fieldToUpdate field
     * @param values Map of values to store by the fieldToCheck fields value
     */
    @NamespaceAccessible
    protected virtual void setFieldValueByMap( Schema.SObjectField fieldToCheck, Schema.SObjectField fieldToUpdate, Map<Object, Object> values ){
        List<SObject> records = getRecords();
        for( Integer i = 0; i < this.numRecords; i++ ){
            SObject record = records[ i ];
            Object keyValue = record.get( fieldToCheck );
            if( values?.containsKey( keyValue ) ){
                record.put( fieldToUpdate, values.get( keyValue ) );
            }
        }
    }

    /**
     * METHODS: GROUP LIST BY RECORD VALUES
     */

    /**
     * Method to easily construct a Map from a List of SObjects, having a field from the SObject being set as key
     * E.g. used when preparing queried records to be easy accessible (grouped) by queried field
     *
     * @param identifierField                   SObjectField to be passed which value should be set as record-identifiers
     * @return                                  Map with values from identifierField in looped SObjects with a List of related SObjects
     * @throws fflib_Objects.InvalidValueException when a record has no value for the requested identifier field
     * @throws System.SObjectException          when the SObjectField doesn't belong/exist on the provided record
     */
    @NamespaceAccessible
    public Map<Object, List<SObject>> groupRecordsByFieldValue( Schema.SObjectField identifierField ){
        Map<Object, List<SObject>> returnMap = new Map<Object, List<SObject>>();
        List<SObject> records = getRecords();

        for( Integer i = 0; i < this.numRecords; i++ ){
            SObject record = records[ i ];
            Object recordKey = record.get( identifierField );

            if( recordKey == null ){
                throw new fflib_Objects.InvalidValueException( 'No value was set for ' + identifierField + ' on ' + record );
            }

            List<SObject> existingListForSameIdentifier = returnMap.get( recordKey );
            if( existingListForSameIdentifier != null ){
                existingListForSameIdentifier.add( record );
            } else{
                returnMap.put( recordKey, new List<SObject>{ record } );
            }
        }
        return returnMap;
    }

    /**
     * Ensures logging of errors in the Domain context for later assertions in tests
     **/
    @NamespaceAccessible
    public virtual class ErrorFactory{
        private List<Error> errorList = new List<Error>();

        private ErrorFactory(){ }

        @NamespaceAccessible
        public String error( String message, SObject record ){
            return error( null, message, record );
        }

        @NamespaceAccessible
        public String error( fflib_SObjects domain, String message, SObject record ){
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

        @NamespaceAccessible
        public String error( fflib_ISObjects domain, String message, SObject record, SObjectField field ){
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
     **/
    @NamespaceAccessible
    public virtual class FieldError extends ObjectError{
        @NamespaceAccessible
        public SObjectField field;

        @NamespaceAccessible
        public FieldError(){ }
    }

    /**
     * Ensures logging of errors in the Domain context for later assertions in tests
     **/
    @NamespaceAccessible
    public virtual class ObjectError extends Error{
        @NamespaceAccessible
        public SObject record;

        @NamespaceAccessible
        public ObjectError(){ }
    }

    /**
     * Ensures logging of errors in the Domain context for later assertions in tests
     **/
    @NamespaceAccessible
    public abstract class Error{
        @NamespaceAccessible
        public String message;
        @NamespaceAccessible
        public fflib_ISObjects domain;
    }
}