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
 *
 *  @created    October 2025
 */
public virtual with sharing class fflib_SObjects extends fflib_Objects implements fflib_ISObjects{

    /**
     * TODO: Class constructors added for full compatibility with parent interfaces fflib_ISObjects -> fflib_IObjects -> fflib_IDomain, to be revised with the consolidation of the base fflib_SObjectDomain implementation
     *  with the fflib_IDomain construction
     *  Git issue -> https://github.com/deloitte-engineering/dfflib/issues/3
     */
    /**
     * Derived from the records provided during construction, provides the native describe for the standard or custom object
     */
    public Schema.DescribeSObjectResult sObjectDescribe{ get; private set; }

    /**
     * Useful during unit testing to assert at a more granular and robust level for errors raised during the various trigger events
     **/
    public static ErrorFactory errorFactory{ get; private set; }

    static{
        errorFactory = new ErrorFactory();
    }

    public fflib_SObjects( List<SObject> records ){
        super( records );
    }

    public fflib_SObjects( List<SObject> records, Schema.SObjectType sObjectType ){
        super( records );
        // Capture SObjectType describe for this domain class
        sObjectDescribe = sObjectType.getDescribe();
    }

    /**
     * Alternative to the Records property, provided to support mocking of Domain classes
     *
     * @return	List<SObject> representing the list of records in context
     */
    public virtual List<SObject> getRecords(){
        return ( List<SObject> ) getObjects();
    }

    public virtual Set<Id> getRecordIds(){
        return new Map<Id, SObject>( getRecords() ).keySet();
    }

    public virtual override Object getType(){
        return getSObjectType();
    }

    /**
     * Returns the SObjectType this Domain class represents
     *
     * @return	SObjectType that represents this domain class
     */
    public virtual SObjectType getSObjectType(){
        return sObjectDescribe.getSObjectType();
    }

    /**
	 * Adds an error message to the records in the domain
	 *
	 * @param message The error message to add to each record
	 */
    @TestVisible
    protected void addError( String message ){
        List<SObject> records = getRecords();
        for( Integer i = 0, j = records.size(); i < j; i++ ){
            records[ i ].addError( error( message, records[ i ] ) );
        }
    }

    /**
     * Adds an error message to the a field records in the domain
     *
     * @param field The field where the error should be reported
     * @param message The error message to add to the given field on each record
     */
    @TestVisible
    protected virtual void addError( Schema.SObjectField field, String message ){
        List<SObject> records = getRecords();
        for( Integer i = 0, j = records.size(); i < j; i++ ){
            records[ i ].addError( error( message, records[ i ], field ) );
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
    protected virtual String error( String message, SObject record, Schema.SObjectField field ){
        return fflib_SObjects.errorFactory.error( this, message, record, field );
    }

    /**
     * Method to easily construct a Map from a List of SObjects, having a field from the SObject being set as key
     * E.g. used when preparing queried records to be easy accessible (grouped) by queried field
     *
     * @param identifierField                   SObjectField to be passed which value should be set as record-identifiers
     * @param toLowerCase                       Boolean that will construct the map CaseSensitive or not
     * @return                                  Map with values from identifierField in looped SObjects with a List of related SObjects
     * @throws fflib.InvalidInputValueException when a record has no value for the requested identifier field
     * @throws System.SObjectException          when the SObjectField doesn't belong/exist on the provided record
     */
    public Map<String, List<SObject>> mapSObjectsListByIdentifier( Schema.SObjectField identifierField, Boolean toLowerCase ){
        Map<String, List<SObject>> returnMap = new Map<String, List<SObject>>();
        List<SObject> records = getRecords();

        for( Integer i = 0, j = records.size(); i < j; i++ ){
            // Determine record and key
            SObject record = records[ i ];
            String recordKey = toLowerCase
                ? String.valueOf( record.get( identifierField ) ).toLowerCase()
                : String.valueOf( record.get( identifierField ) );

            if( String.isBlank( recordKey ) ){
                throw new fflib.InvalidInputValueException( 'No value was set for ' + identifierField + ' on ' + record );
            }
            List<SObject> existingListsForSameIdentifier = returnMap.get( recordKey );
            if( existingListsForSameIdentifier != null ){
                existingListsForSameIdentifier.add( record );
            } else{
                returnMap.put( recordKey, new List<SObject>{ record } );
            }
        }
        return returnMap;
    }

    /**
     * Method to easily construct a Map from a List of SObjects, having a field from the SObject being set as key
     * E.g. used when preparing queried records to be easy accessible (grouped) by queried field
     *
     * @param identifierField                   SObjectField to be passed which value should be set as record-identifiers
     * @return                                  Map with values from identifierField in looped SObjects with a List of related SObjects
     * @throws fflib.InvalidInputValueException when a record has no value for the requested identifier field
     * @throws System.SObjectException          when the SObjectField doesn't belong/exist on the provided record
     */
    public Map<String, List<SObject>> mapSObjectsListByIdentifier( Schema.SObjectField identifierField ){
        return mapSObjectsListByIdentifier( identifierField, false );
    }

    /**
     * Method to easily get a subset of the provided List where records match a certain value, like filter() in JS
     *
     * @param identifierField                       SObjectField to be passed which value should be set as record-identifiers
     * @param identifierValue                       Desired filter value for the identifierField
     * @return Subset of inputList including all records which match the value for the identifier field
     * @throws System.SObjectException              When provided field doesn't exist for SObject in inputList
     * @throws fflib.InvalidInputValueException     When an SObject in inputList has no value for the identifier field
    */
    public List<SObject> filterListByFieldValue( Schema.SObjectField identifierField, Object identifierValue ){
        return filterListByFieldValues(
            identifierField, new Set<Object>{ identifierValue }
        );
    }

    /**
     * Method to easily get a subset of the provided List where records match a list of values
     *
     * @param identifierField                       SObjectField to be passed which value should be set as record-identifiers
     * @param identifierValues                      Desired filter values for the identifierField
     * @return Subset of inputList including all records which match the value for the identifier field
     * @throws System.SObjectException              When provided field doesn't exist for SObject in inputList
     * @throws fflib.InvalidInputValueException     When an SObject in inputList has no value for the identifier field
    */
    public List<SObject> filterListByFieldValues( Schema.SObjectField identifierField, Set<Object> identifierValues ){
        fflib_Objects.verifyNotNull( identifierValues, 'identifierValues' );
        fflib_Objects.verifyNotNull( identifierField, 'identifierField' );

        List<SObject> returnList = new List<SObject>();
        List<SObject> records = getRecords();

        for( Integer i = 0, j = records.size(); i < j; i++ ){
            // Determine record and key
            SObject record = records[ i ];
            String recordKey = String.valueOf( record.get( identifierField ) );
            // TODO: Discuss whether blank values should trigger an exception and hault execution, or simply log behaviour
            if( String.isBlank( recordKey ) ){
                throw new fflib.InvalidInputValueException( 'No value was set for ' + identifierField + ' on ' + record );
            }
            if( identifierValues?.contains( recordKey ) ){
                returnList.add( record );
            }
        }

        return returnList;
    }

    /**
     * Method to filter records where the given field is blank (null or empty string)
     *
     * @param identifierField   Field to check for blank values
     * @return  Filtered list of SObjects
     */
    public List<SObject> filterListByBlankFieldValues( Schema.SObjectField identifierField ){
        return filterListByBlankFieldValues(
            new Set<Schema.SObjectField>{ identifierField }
        );
    }

    /**
     * Method to filter records where at least one of the given fields is blank
     *
     * @param identifierFields  Set of fields to check
     * @return  Filtered list of SObjects
     */
    public List<SObject> filterListByBlankFieldValues( Set<Schema.SObjectField> identifierFields ){
        fflib_Objects.verifyNotNull( identifierFields, 'identifierFields' );

        List<SObject> returnList = new List<SObject>();
        List<SObject> records = getRecords();

        for( Integer i = 0, j = records.size(); i < j; i++ ){
            // Determine record
            SObject record = records[ i ];
            for( Schema.SObjectField field : identifierFields ){
                // Skip if field key is not blank or null
                if( String.isNotBlank( ( String ) record.get( field ) ) ){
                    continue;
                }

                returnList.add( record );
                break;
            }
        }

        return returnList;
    }

    /**
     * Method to filter records where all given fields are blank
     *
     * @param identifierFields  Set of fields to check
     * @return  Filtered list of SObjects
     */
    public List<SObject> filterListByAllBlankFieldValues( Set<Schema.SObjectField> identifierFields ){
        fflib_Objects.verifyNotNull( identifierFields, 'identifierFields' );
        List<SObject> returnList = new List<SObject>();
        List<SObject> records = getRecords();

        for( Integer i = 0, j = records.size(); i < j; i++ ){
            // Determine record
            SObject record = records[ i ];
            Boolean allBlank = true;
            for( Schema.SObjectField field : identifierFields ){
                // Break field iteration if not blank/null
                if( String.isNotBlank( ( String ) record.get( field ) ) ){
                    allBlank = false;
                    break;
                }
            }
            if( allBlank ){
                returnList.add( record );
            }
        }

        return returnList;
    }

    /**
     * Method to filter records where the given field is non-empty/populated
     *
     * @param identifierField   Field to check for non-empty values
     * @return  Filtered list of SObjects
     */
    public List<SObject> filterListByNonEmptyFieldValues( Schema.SObjectField identifierField ){
        return filterListByNonEmptyFieldValues(
            new Set<Schema.SObjectField>{ identifierField }
        );
    }

    /**
     * Method to filter records where at least one of the given fields is non-empty/populated
     *
     * @param identifierFields  Set of fields to check
     * @return  Filtered list of SObjects
     */
    public List<SObject> filterListByNonEmptyFieldValues( Set<Schema.SObjectField> identifierFields ){
        fflib_Objects.verifyNotNull( identifierFields, 'identifierFields' );

        List<SObject> returnList = new List<SObject>();
        List<SObject> records = getRecords();

        for( Integer i = 0, j = records.size(); i < j; i++ ){
            // Determine record
            SObject record = records[ i ];
            for( Schema.SObjectField field : identifierFields ){
                // Add record if field not blank/null, break field iteration
                if( String.isNotBlank( ( String ) record.get( field ) ) ){
                    returnList.add( record );
                    break;
                }
            }
        }

        return returnList;
    }

    /**
     * Method to filter records where all given fields are non-empty/populated
     *
     * @param SObjectList           Input list of SObjects
     * @param identifierFields      Set of fields to check
     * @return  Filtered list of SObjects
     */
    public List<SObject> filterListByAllNonEmptyFieldValues( Set<Schema.SObjectField> identifierFields ){
        fflib_Objects.verifyNotNull( identifierFields, 'identifierFields' );

        List<SObject> returnList = new List<SObject>();
        List<SObject> records = getRecords();

        for( Integer i = 0, j = records.size(); i < j; i++ ){
            // Determine record
            SObject record = records[ i ];
            Boolean allNonBlank = true;
            for( Schema.SObjectField field : identifierFields ){
                // Break field iteration if record field is blank/null
                if( String.isBlank( ( String ) record.get( field ) ) ){
                    allNonBlank = false;
                    break;
                }
            }
            if( allNonBlank ){
                returnList.add( record );
            }
        }

        return returnList;
    }

    /**
     * Used for "plucking" ID's out of a collection of SObjects. This method is intended to save time writing for loops
     * for retrieving ID's from lookup fields.
     *
     * @param records   The SObjects to pluck the ID's from (record's Id field).
     *
     * @return  Set of ID's populated from the ID's found in the collection of SObjects.
     */
    public Set<Id> pluckIds(){
        return ( new Map<Id, SObject>( getRecords() ) ).keySet();
    }

    /**
     * Used for "plucking" ID's out of a collection of SObjects. This method is intended to save time writing for loops
     * for retrieving ID's from lookup fields.
     *
     * @param records   The SObjects to pluck the ID's from.
     * @param field     The field name which will be used to retrieve the ID's from.
     *
     * @return  Set of ID's populated from the ID's found in the collection of SObjects.
     */
    public Set<Id> pluckIds( Schema.SObjectField field ){
        return pluckIds( field, false );
    }

    public Set<Id> pluckIdsFromRelationship( String fieldWithDotRelation ){
        fflib_Objects.verifyNotBlank( 'fieldWithDotRelation', fieldWithDotRelation );

        Set<Id> pluckedIds = new Set<Id>();

        for( SObject record : getRecords() ){
            Id foundId = ( Id ) record.getSObject( fieldWithDotRelation.substringBefore( '.' ) )?.get( fieldWithDotRelation.substringAfter( '.' ) );
            if( foundId != null ){
                pluckedIds.add( foundId );
            }
        }

        return pluckedIds;
    }

    /**
     * Used for "plucking" ID's out of a collection of SObjects. This method is intended to save time writing for loops
     * for retrieving ID's from lookup fields.
     *
     * @param records       The SObjects to pluck the ID's from.
     * @param field         The field name which will be used to retrieve the ID's from.
     * @param includeNulls  Set to true to include null values in the returned set.
     *
     * @return  Set of ID's populated from the ID's found in the collection of SObjects.
     */
    public Set<Id> pluckIds( Schema.SObjectField field, Boolean includeNulls ){
        fflib_Objects.verifyNotNull( field, 'field' );
        fflib_Objects.verifyNotNull( includeNulls, 'includeNulls' );

        Set<Id> pluckedIds = new Set<Id>();
        List<SObject> records = getRecords();

        for( Integer i = 0, j = records.size(); i < j; i++ ){
            Id foundId = ( Id ) records[ i ].get( field );
            if( String.isNotBlank( foundId ) || includeNulls ){
                pluckedIds.add( foundId );
            }
        }

        return pluckedIds;
    }


    /**
     * Used for "plucking" Strings out of a collection of SObjects. This method is intended to save time writing for loops
     * for retrieving strings from lookup fields.
     *
     * @param records   The SObjects to pluck the strings from.
     * @param field     The field name which will be used to retrieve the strings from.
     *
     * @return  Set of ID's populated from the strings found in the collection of SObjects.
     */
    public Set<String> pluckStrings( Schema.SObjectField field ){
        return pluckStrings( field, false );
    }


    /**
     * Used for "plucking" Strings out of a collection of SObjects. This method is intended to save time writing for loops
     * for retrieving strings from lookup fields.
     *
     * @param records       The SObjects to pluck the strings from.
     * @param field         The field name which will be used to retrieve the strings from.
     * @param includeNulls  Set to true to include null values in the returned set.
     *
     * @return  Set of ID's populated from the strings found in the collection of SObjects.
     */
    public Set<String> pluckStrings( Schema.SObjectField field, Boolean includeNulls ){
        fflib_Objects.verifyNotNull( field, 'SObjectField' );
        fflib_Objects.verifyNotNull( includeNulls, 'includeNulls' );

        Set<String> pluckedStrings = new Set<String>();
        List<SObject> records = getRecords();

        for( Integer i = 0, j = records.size(); i < j; i++ ){
            String foundString = String.valueOf( records[ i ].get( field ) );

            if( String.isNotBlank( foundString ) || includeNulls ){
                pluckedStrings.add( foundString );
            }
        }

        return pluckedStrings;
    }

    /**
     * Method to retrieve a list of Schema.PicklistEntries with label and (api) value for any object
     *
     * @param objectType            String value of the object
     * @param selectedField         String value of the picklist (multi-select) field
     * @return ple                  List containing schema's of picklist entries
     */
    public List<Schema.PicklistEntry> getPicklistValues( String objectType, String selectedField ){
        fflib_Objects.verifyNotBlank( objectType, 'objectType' );
        fflib_Objects.verifyNotBlank( selectedField, 'selectedField' );

        fflib_SObjectDescribe fflibDescribe = fflib_SObjectDescribe.getDescribe( objectType );
        if( fflibDescribe == null ){
            throw new fflib.InvalidImplementationException( 'The provided SObjectType ' + objectType + ' seems to be invalid (not found in GlobalDescribe)' );
        }

        SObjectField field = fflibDescribe.getDescribe().fields.getMap().get( selectedField.toLowerCase() );
        if( field == null ){
            throw new fflib.InvalidImplementationException( 'No ' + selectedField + ' field seems to exist on ' + objectType );
        }

        Schema.DescribeFieldResult fieldResult = field.getDescribe();
        return fieldResult.getPicklistValues();
    }

    /**
     * Method to retrieve a list of Strings with values of restricted picklists
     *
     * @param objectType            String value of the object
     * @param selectedField         String value of the picklist (multi-select) field
     * @return ple                  List containing picklist values as string
     */
    public List<String> getPicklistValuesToStrings( String objectType, String selectedField ){
        fflib_Objects.verifyNotBlank( objectType, 'objectType' );
        fflib_Objects.verifyNotBlank( selectedField, 'selectedField' );

        List<Schema.PicklistEntry> picklistValues = getPicklistValues( objectType, selectedField );
        List<String> valueStrings = new List<String>();

        for( Integer k = 0, l = picklistValues.size(); k < l; k++ ){
            Schema.PicklistEntry value = picklistValues[ k ];
            valueStrings.add( value.getLabel().toUpperCase() );
        }

        return valueStrings;
    }

    /**
     * @param sObjField     The Picklist Field in which the provided value should be checked
     * @param sObjType      The SObjectType to which the picklist belongs (unfortunately, it is not possible to easily derive from SObjectField, hence separate input)
     * @param value         The value which is checked
     * @return Boolean      TRUE when the value is a valid value for the provided picklist field, FALSE otherwise or when value was blank
     */
    public Boolean isValidPicklistValue( Schema.SObjectField sObjField, SObjectType sObjType, String value ){
        if( String.isBlank( value ) ){
            return false;
        }

        List<Schema.PicklistEntry> pickValues = getPicklistValues( String.valueOf( sObjType ), String.valueOf( sObjField ) );
        for( Integer i = 0, j = pickValues.size(); i < j; i++ ){
            PicklistEntry picklistEntry = pickValues[ i ];
            if( picklistEntry.getValue().equalsIgnoreCase( value ) ){
                return true;
            }
        }

        return false;
    }

    /**
	 * Method to clear provided field on all provided records
     *
	 * @param field     The field to nullify
	 */
    public void clearField( Schema.SObjectField field ){
        clearFields( new Set<Schema.SObjectField>{ field } );
    }

    /**
     * Method to clear provided fields on all provided records
     *
     * @param fields    The fields to nullify
     */
    public void clearFields( Set<Schema.SObjectField> fields ){
        List<SObject> records = getRecords();
        for( Integer i = 0, j = records.size(); i < j; i++ ){
            for( Schema.SObjectField field : fields ){
                records[ i ].put( field, null );
            }
        }
    }

    /**
     * Method to collect values of a given field across a list of records
     *
     * @param field     The SObjectField reference
     * @return  Return a set with all the values of the given field
     */
    public Set<Object> getFieldValues( Schema.SObjectField field ){
        Set<Object> result = new Set<Object>();
        List<SObject> records = getRecords();
        for( Integer i = 0, j = records.size(); i < j; i++ ){
            result.add( records[ i ].get( field ) );
        }

        return result;
    }


    /**
     * Method to set the same field value on all provided records
     *
     * @param field     The reference to the SObjectField to be modified
     * @param value     The value to store in the given SObjectField
     */
    public void setFieldValue( Schema.SObjectField field, Object value ){
        List<SObject> records = getRecords();
        for( Integer i = 0, j = records.size(); i < j; i++ ){
            records[ i ].put( field, value );
        }
    }

    /**
     * Method to set field values on records using a lookup map
     *
     * @param fieldToCheck      The SObjectField to match the key against in the provided map
     * @param fieldToUpdate     The SObjectField to store the mapped value when the key matches the value in the fieldToUpdate field
     * @param values            Map of values to store by the fieldToCheck fields value
     */
    public void setFieldValueByMap( Schema.SObjectField fieldToCheck, Schema.SObjectField fieldToUpdate, Map<Object, Object> values ){
        List<SObject> records = getRecords();
        for( Integer i = 0, j = records.size(); i < j; i++ ){
            Object keyValue = records[ i ].get( fieldToCheck );
            if( values?.containsKey( keyValue ) ){
                records[ i ].put( fieldToUpdate, values.get( keyValue ) );
            }
        }
    }

    /**
     * Ensures logging of errors in the Domain context for later assertions in tests
     */
    public class ErrorFactory{
        private List<Error> errorList = new List<Error>();

        private ErrorFactory(){}

        public String error( String message, SObject record ){
            return error( null, message, record );
        }

        private String error( fflib_SObjects domain, String message, SObject record ){
            ObjectError objectError = new ObjectError();
            objectError.domain = domain;
            objectError.message = message;
            objectError.record = record;
            errorList.add( objectError );

            return message;
        }

        public String error( String message, SObject record, SObjectField field ){
            return error( null, message, record, field );
        }

        private String error( fflib_ISObjects domain, String message, SObject record, SObjectField field ){
            FieldError fieldError = new FieldError();
            fieldError.domain = domain;
            fieldError.message = message;
            fieldError.record = record;
            fieldError.field = field;
            errorList.add( fieldError );

            return message;
        }

        public List<Error> getAll(){
            return errorList.clone();
        }

        public void clearAll(){
            errorList.clear();
        }
    }

    /**
     * Ensures logging of errors in the Domain context for later assertions in tests
     */
    public virtual class FieldError extends ObjectError{
        public SObjectField field;

        public FieldError(){}
    }

    /**
     * Ensures logging of errors in the Domain context for later assertions in tests
     */
    public virtual class ObjectError extends Error{
        public SObject record;

        public ObjectError(){}
    }

    /**
     * Ensures logging of errors in the Domain context for later assertions in tests
     */
    public abstract class Error{
        public String message;
        public fflib_ISObjects domain;
    }
}
