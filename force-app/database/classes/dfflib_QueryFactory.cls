/**
 * Copyright (c), FinancialForce.com, inc
 * Copyright (c) 2019, Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
/**
 * QueryFactory provides an object-oriented way of building SOQL queries without resorting to string manipulation.
 * This class is not meant to be used as a replacement for all SOQL queries, and due to the relatively high overhead in both CPU and describe calls
 * should be used in places where highly dynamic queries, such as those that include field sets or are mutated heavily
 * in multiple locations are a good fit for use with dfflib_QueryFactory.
 * 
 * To use call construct a new instance for each query you intend to make.
 * To add additional fields to the query make use of the selectField(s) methods.
 *
 * Currently the 'WHERE' clause of the query is manipulated as a single string, and is decidedly less OO-styled than other methods.
 * This is expected to be expanded upon in the future.
 * 
 * To include one or more ORDER BY clause(s), use one of the addOrdering methods.  If not specified, the "NULLS FIRST" keywords
 * will be included by default. Constructing Ordering instances manually is discouraged.
 * 
 * Subselect Queries are supported with the subselectQuery methods.  
 * More than one sub-query can be added to a single query. An exception will thrown from the subselectQuery method
 * when there is an attempt to add a subquery to a query with an invalid relationship.
 *
 * Current limitations:
 * - Cross-object references currently require using String argument(s) to selectField(s).
 * - The behavior of serializing and deserializing a dfflib_QueryFactory instance is currently untested and undefined.
 * - There is no out-of-the-box support for dynamic selector-fields, often limiting the reuse of selector methods.
 */
@NamespaceAccessible
public virtual inherited sharing class dfflib_QueryFactory{
    public enum DistanceUnit{ KILOMETERS, MILES }
    public enum FLSEnforcement{ NONE, LEGACY, USER_MODE, SYSTEM_MODE }
    public enum SortOrder{ ASCENDING, DESCENDING }

    // Public to allow accessibility from dfflib_SObjectSelector Validator
    @NamespaceAccessible
    public static dfflib_QueryFactory lastQueryFactory;

    /**
     * This property is read-only and may not be set after instantiation.
     * The {@link Schema.SObjectType} token of the SObject that will be used in the FROM clause of the resultant query.
     */
    @NamespaceAccessible
    public Schema.SObjectType table{ get; private set; }

    @TestVisible
    private Set<String> fields;
    private String conditionExpression;
    private String groupByFieldName;
    private String havingExpression;
    private List<Ordering> order;
    private Integer limitCount;
    private Integer offsetCount;
    private Boolean allRows = false;
    private Boolean forView = false, forReference = false, forUpdate = false;

    /**
	 * Integrate checking for READ Field Level Security within the selectField(s) methods
	 * This can optionally be enforced (or not) by calling the setEnforceFLS method prior to calling
	 * one of the selectField or selectFieldset methods.
	 */
    @TestVisible
    private FLSEnforcement mFlsEnforcement;

    private Boolean sortSelectFields = true;


    /**
     * The relationship and subselectQueryMap variables are used to support subselect queries. 
     * Subselects can be added to a query, calling the subselectQuery method, passing in the ChildRelationship.
     */
    private Schema.ChildRelationship relationship;
    private Map<Schema.ChildRelationship, dfflib_QueryFactory> subSelectQueryMap;

    /**
     * Pattern internal variables
     */
    private static final String AGGREGATE_FUNCTION_REGEX = '^([a-zA-Z]+\\(\\s*)([a-zA-Z0-9_\\.]*)(\\s*\\)[a-zA-Z0-9 ]*)$'; // groups: 0) full, 1) function-with-bracket, 2) field, 3) alias-with-bracket (rest after)
    private static final String TYPECASTING_REGEX = '^\\(\\s*([a-zA-Z0-9_\\.]*)\\s*\\)\\s*([a-zA-Z0-9_]+)$'; // groups: 0) full, 1) cast, 2) field (rest after)
    // Static Getter to prevent the Pattern to be compiled when not relevant for Class initiation
    private static Pattern CAST_PATTERN{
        get{
            if( CAST_PATTERN == null ){
                CAST_PATTERN = Pattern.compile( TYPECASTING_REGEX );
            }
            return CAST_PATTERN;
        }
        set;
    }
    private static Pattern AGG_PATTERN{
        get{
            if( AGG_PATTERN == null ){
                AGG_PATTERN = Pattern.compile( AGGREGATE_FUNCTION_REGEX );
            }
            return AGG_PATTERN;
        }
        set;
    }

    /**
     * Method to derive FieldPath by String fieldName and validate requested Fields for existence and optionally FLS access
     *
     * @param   fieldName   Field reference to validate, potentially incl. SOQL functions, aliases and/or Cast Types
     * @return Field reference for SOQL Query, when all checks validated
     */
    @NamespaceAccessible
    public String getFieldPath( String fieldName ){
        // Enforcing FLS using the legacy heuristic requires resolving the full field path to its respective
        // Describe result to test for isAccessible on the DescribeFieldResult
        // This is computationally expensive and should be bypassed if the QueryFactory instance is not enforcing FLS
        // Starting in Summer '22, Apex can natively enforce CRUD and FLS with User Mode Operations
        // Someday, the LEGACY FLSEnforcement heuristic will be removed
        if( mFlsEnforcement == null || mFlsEnforcement == FLSEnforcement.USER_MODE || mFlsEnforcement == FLSEnforcement.SYSTEM_MODE ){
            return fieldName;
        }

        String beforeField = '';
        String afterField = '';

        // SOQL Function check - exclude function and alias from field name to allow field-checks
        Matcher aggMatcher = AGG_PATTERN.matcher( fieldName );
        if( aggMatcher.matches() ){
            beforeField = aggMatcher.group( 1 );
            fieldName = aggMatcher.group( 2 );
            afterField = aggMatcher.group( 3 );

            // If no fields within the function then return immediately, nothing to check
            if( String.isBlank( fieldName ) ){
                return beforeField + afterField;
            }
        }

        // Single field checks
        if( !fieldName.contains( '.' ) ){
            Schema.SObjectField token = fflib_SObjectDescribe.getDescribe( this.table ).getField( fieldName.toLowerCase() );
            if( token == null ){
                throw new InvalidFieldException( fieldName, this.table );
            }

            if( mFlsEnforcement == FLSEnforcement.LEGACY ){
                fflib_SecurityUtils.checkFieldIsReadable( this.table, token );
            }
            return beforeField + getFieldTokenPath( token ) + afterField;
        }

        // Relational field (containing . in fieldPath) - Validating relations
        List<String> fieldPath = new List<String>();
        Schema.SObjectType lastSObjectType = table;
        Iterator<String> i = fieldName.split( '\\.' ).iterator(); // e.g. Contact.(User)Owner.Name
        // Validate and process each field-reference
        while( i.hasNext() ){
            String field = i.next();
            Matcher typeCastMatcher = CAST_PATTERN.matcher( field );
            SObjectType castObjType;
            // Check whether FieldPath contains a specific SObjectType Cast
            if( typeCastMatcher.matches() ){
                String castObjTypeString = typeCastMatcher.group( 1 );
                field = typeCastMatcher.group( 2 );

                if( String.isBlank( castObjTypeString ) ){
                    throw new PolymorphicLookupException( 'Cannot have an empty type cast' );
                } else{
                    castObjType = Schema.getGlobalDescribe().get( castObjTypeString.toLowerCase() );
                }
            }

            Schema.SObjectField token = fflib_SObjectDescribe.getDescribe( lastSObjectType ).getField( field.toLowerCase() );
            if( token == null ){
                throw new InvalidFieldException( field, lastSObjectType );
            }

            if( token != null && mFlsEnforcement == FLSEnforcement.LEGACY ){
                fflib_SecurityUtils.checkFieldIsReadable( lastSObjectType, token );
            }

            DescribeFieldResult tokenDescribe = token.getDescribe();
            // When last field to process, simply return tokenDescribe
            if( !i.hasNext() ){
                fieldPath.add( tokenDescribe.getName() );

                // When current field is Lookup (ID and next field), validate by Describes and set values for next iteration
            } else if( tokenDescribe.getSoapType() == Schema.SoapType.ID ){
                // Add Relationship name to FieldPath for SOQL Query
                fieldPath.add( tokenDescribe.getRelationshipName() );

                // Update lastSObjectType for proper Describe retrieval of next field;
                List<Schema.SObjectType> relatedSObjectList = tokenDescribe.getReferenceTo();
                if( relatedSObjectList.isEmpty() ){
                    throw new InvalidFieldException( 'Per API 51 getReferenceTo() always returns at least one SObjectType. No retrieved for ' + field );
                    // When only one SObjectType found for this Lookup, update lastSObjectType
                } else if( relatedSObjectList.size() == 1 ){
                    lastSObjectType = relatedSObjectList[ 0 ];

                } else{
                    // When more SObjectTypes found (polymorphic Lookup field), check whether Developer specified anything, else grab first one
                    if( castObjType == null ){
                        System.debug( LoggingLevel.WARN, '*** fflib - Developer didn\'t specify cast for polymorphic field ' + field + ' so first is selected of ' + relatedSObjectList );
                        lastSObjectType = relatedSObjectList[ 0 ];

                        // When Developer specified specific CastType, validate whether Lookup can indeed be cast to that SObjectType
                    } else{
                        Boolean castObjFound = false;
                        for( Integer j = 0, k = relatedSObjectList.size(); j < k; j++ ){
                            SObjectType sObjType = relatedSObjectList[ j ];
                            if( sObjType == castObjType ){
                                lastSObjectType = sObjType;
                                castObjFound = true;
                                break;
                            }
                        }
                        if( !castObjFound ){
                            throw new PolymorphicLookupException( 'Invalid type cast for the polymorphic lookup' +
                                ' Field: ' + field + ' is never of type ' + castObjType + ', but can only be of: ' + relatedSObjectList );
                        }
                    }
                }
            } else{
                throw new NonReferenceFieldException( lastSObjectType + '.' + field + ' is not a lookup or master-detail field but is used in a cross-object query field.' );
            }
        }
        // Return field surrounding text and concatenated the individually processed fieldPaths
        return beforeField + String.join( fieldPath, '.' ) + afterField;
    }

    @TestVisible
    private static String getFieldTokenPath( Schema.SObjectField field ){
        if( field == null ){
            throw new InvalidFieldException( 'Invalid field: null' );
        }
        return field.getDescribe().getLocalName();
    }

    /**
     * dfflib_QueryFactory instances will be considered equal if they produce the same SOQL query.
     * A faster comparison will first be attempted to check if they apply to the same table, and contain the same number of fields selected.
     * This method will never return true if the provided object is not an instance of dfflib_QueryFactory
     *
     * @param   obj     The object to check equality of
     * @return  Boolean containing true/false value if the provided object is/is not an instance of dfflib_QueryFactory
     */
    @NamespaceAccessible
    public Boolean equals( Object obj ){
        if( !( obj instanceof dfflib_QueryFactory ) || ( ( dfflib_QueryFactory ) obj ).table != this.table ||
            ( ( dfflib_QueryFactory ) obj ).fields.size() != this.fields.size() ){
            return false;
        }

        return ( ( dfflib_QueryFactory ) obj ).toSOQL() == this.toSOQL();
    }

    /**
     * Construct a new dfflib_QueryFactory instance with no options other than the FROM clause
     * You *must* call selectField(s) before {@link #toSOQL} will return a valid, runnable query
     *
     * @param   table   The SObject to be used in the FROM clause of the resultant query. This sets the value of {@link #table}.
     */
    @NamespaceAccessible
    public dfflib_QueryFactory( Schema.SObjectType table ){
        this.table = table;
        fields = new Set<String>();
        order = new List<Ordering>();
        mFlsEnforcement = null;
    }

    /**
     * Construct a new dfflib_QueryFactory instance with no options other than the FROM clause and the relationship.
     * This should be used when constructing a subquery query for addition to a parent query. 
     * Objects created with this constructor cannot be added to another object using the subselectQuery method.
     * You *must* call selectField(s) before {@link #toSOQL} will return a valid, runnable query
     *
     * @param   relationship    The ChildRelationship to be used in the FROM Clause of the resultant Query
     *                          (when set overrides value of table). This sets the value of {@link #relationship} and {@link #table}.
     */
    private dfflib_QueryFactory( Schema.ChildRelationship relationship ){
        this( relationship.getChildSObject() );
        this.relationship = relationship;
    }

    /**
     * This method checks to see if the User has Read Access on {@link #table}. 
     * Asserts true if User has access.
     *
     * @return  Returns this dfflib_QueryFactory instance
     */
    @NamespaceAccessible
    public virtual dfflib_QueryFactory assertIsAccessible(){
        fflib_SecurityUtils.checkObjectIsReadable( table );
        return this;
    }

    /**
     * This method sets a flag to indicate that this query should have FLS Read
     * permission enforced.  If this method is not called, the default behavior
     * is that FLS read permission will not be checked
     *
     * @param   enforce     Whether to enforce field level security (read)
     * @return  Returns this dfflib_QueryFactory instance
     * @deprecated - legacy enforceFLS boolean will be removed, for future references, please refer to {@link dfflib_Database#Context}
     */
    @NamespaceAccessible
    public dfflib_QueryFactory setEnforceFLS( Boolean enforce ){
        return setEnforceFLS( ( ( enforce == null ) ? null : ( enforce == true ) ? FLSEnforcement.LEGACY : FLSEnforcement.NONE ) );
    }

    /**
     * Method to set the renewed FLSEnforcement enum to indicate how FLS should be enforced, instead of a Boolean
     * Note, the method is deprecated as it is recommended to migrate to dfflib_Database.Context and AccessLevel enums for FLS enforcement
     *
     * @param enforcement FLSEnforcement enum to indicate how FLS should be enforced
     * @return Returns this dfflib_QueryFactory instance
     * @deprecated - legacy enforceFLS by Boolean or FLSEnforcement enum, one should move to utilise the dfflib_Database.Context and AccessLevel enums for FLS enforcement
     */
    @NamespaceAccessible
    public dfflib_QueryFactory setEnforceFLS( FLSEnforcement enforcement ){
        this.mFlsEnforcement = enforcement;
        // Ensure that any subselect query inherits same FLS enforcement settings
        if( this.subSelectQueryMap != null && !this.subSelectQueryMap.isEmpty() ){
            for( ChildRelationship relationship : this.subSelectQueryMap.keySet() ){
                this.subSelectQueryMap.get( relationship ).setEnforceFLS( enforcement );
            }
        }
        
        return this;
    }

    /**
     * Sets a flag to indicate that this query should have ordered
     * query fields in the select statement (this at a small cost to performance).
     * If you are processing large query sets, you should switch this off
     * 
     * @param   doSort      Whether or not select fields should be sorted in the soql statement
     * @return  Returns this dfflib_QueryFactory instance
     */
    @NamespaceAccessible
    public dfflib_QueryFactory setSortSelectFields( Boolean doSort ){
        this.sortSelectFields = doSort;
        return this;
    }

    /**
     * Selects a single field from the SObject specified in {@link #table}.
     * Selecting fields is idempotent, if this field is already selected calling this method will have no additional impact
     * 
     * @param   fieldName   The API name of the field to add to the query's SELECT clause
     * @return  Returns this dfflib_QueryFactory instance
     */
    @NamespaceAccessible
    public dfflib_QueryFactory selectField( String fieldName ){
        return selectFields( new Set<String>{ fieldName } );
    }

    /**
     * Selects a field, avoiding the possible ambiguity of String API names
     * 
     * @see #selectField(String)
     * @param   field   The {@link Schema.SObjectField} to select with this query
     * @exception   InvalidFieldException() if the field is null {@code field}
     * @return  Returns this dfflib_QueryFactory instance
     */
    @NamespaceAccessible
    public dfflib_QueryFactory selectField( Schema.SObjectField field ){
        return selectFields( new Set<Schema.SObjectField>{ field } );
    }

    /**
     * Selects multiple fields. This acts the same as calling {@link #selectField(String)} multiple times
     * 
     * @param   fieldNames  The Set of field API names to select
     * @return  Returns this dfflib_QueryFactory instance
     */
    @NamespaceAccessible
    public dfflib_QueryFactory selectFields( Set<String> fieldNames ){
        return selectStringField( fieldNames.iterator() );
    }

    /**
     * Selects multiple fields. This acts the same as calling {@link #selectField(String)} multiple times
     * 
     * @param   fieldNames  The List of field API names to select
     * @return  Returns this dfflib_QueryFactory instance
     */
    @NamespaceAccessible
    public dfflib_QueryFactory selectFields( List<String> fieldNames ){
        return selectStringField( fieldNames.iterator() );
    }

    private dfflib_QueryFactory selectStringField( Iterator<String> iter ){
        while( iter.hasNext() ){
            addField( getFieldPath( iter.next() ) );
        }
        return this;
    }

    /**
     * Selects multiple fields. This acts the same as calling {@link #selectField(Schema.SObjectField)} multiple times
     * 
     * @param   fieldNames  The set of {@link Schema.SObjectField}s to select
     * @exception InvalidFieldException() if the fields are null {@code fields}
     * @return  Returns this dfflib_QueryFactory instance
     */
    @NamespaceAccessible
    public dfflib_QueryFactory selectFields( Set<Schema.SObjectField> fieldNames ){
        return selectSObjectFields( fieldNames.iterator() );
    }

    /**
     * Selects multiple fields. This acts the same as calling {@link #selectField(Schema.SObjectField)} multiple times
     * 
     * @param   fieldNames  The set of {@link Schema.SObjectField}s to select
     * @exception InvalidFieldException() if the fields are null {@code fields}
     * @return  Returns this dfflib_QueryFactory instance
     */
    @NamespaceAccessible
    public dfflib_QueryFactory selectFields( List<Schema.SObjectField> fieldNames ){
        return selectSObjectFields( fieldNames.iterator() );
    }

    private dfflib_QueryFactory selectSObjectFields( Iterator<Schema.SObjectField> iter ){
        while( iter.hasNext() ){
            Schema.SObjectField token = iter.next();
            if( token == null ){
                throw new InvalidFieldException();
            }
            if( this.mFlsEnforcement == FLSEnforcement.LEGACY ){
                fflib_SecurityUtils.checkFieldIsReadable( table, token );
            }
            addField( getFieldTokenPath( token ) );
        }
        return this;
    }

    /**
     * @see #selectFieldSet(Schema.FieldSet,Boolean)
     * @return  Returns this dfflib_QueryFactory instance
     */
    @NamespaceAccessible
    public dfflib_QueryFactory selectFieldSet( Schema.FieldSet fieldSet ){
        return selectFieldSet( fieldSet, true );
    }

    /**
     * This is equivalent to iterating the fields in the field set and calling {@link #selectField(String)} on each
     * 
     * @param   fieldSet            Select all fields included in the field set 
     * @param   allowCrossObject    If false this method will throw an exception if any fields in the field set reference fields on a related record
     * @exception InvalidFieldSetException() if the fieldset is invalid for table {@code fields}
     * @return  Returns this dfflib_QueryFactory instance
     */
    @NamespaceAccessible
    public dfflib_QueryFactory selectFieldSet( Schema.FieldSet fieldSet, Boolean allowCrossObject ){
        if( fieldSet.getSObjectType() != table ){
            throw new InvalidFieldSetException( 'Field set "' + fieldSet.getName() + '" is not for SObject type "' + table + '"' );
        }

        for( Schema.FieldSetMember field : fieldSet.getFields() ){
            if( !allowCrossObject && field.getFieldPath().contains( '.' ) ){
                throw new InvalidFieldSetException( 'Cross-object fields not allowed and field "' + field.getFieldPath() + '"" is a cross-object field.' );
            }
            addField( getFieldPath( field.getFieldPath() ) );
        }

        return this;
    }

    private void addField( String fieldPath ){
        /**
         * With the introduction of AccessLevel enums SYSTEM_MODE and USER_MODE, it no longer became necessary to use
         * DescribeFieldResult methods to resolve a selected field back to its canonical case-preserving field definition.
         * The consequence is that duplicate fields could be introduced into the SELECT clause if, for instance,
         * the Apex code called "selectField('annualrevenue')" but that same AnnualRevenue field were included via a
         * Field Set and the FieldSetMember.getFieldPath() returns "AnnualRevenue"
         * So, in the cases where AccessLevel enums are used via {@link dfflib_Database#Context}, we need to down-case all of the fields in the Set
         */
        if( mFlsEnforcement == null || mFlsEnforcement == FLSEnforcement.SYSTEM_MODE || mFlsEnforcement == FLSEnforcement.USER_MODE ){
            fieldPath = fieldPath.toLowerCase();
        }

        this.fields.add( fieldPath );
    }

    /**
     * Method that adds a TYPEOF field selection to the SELECT clause of the query.
     *
     * @param   field           Field to base the TYPEOF on. This is typically a polymorph field like 'Owner'.
     * @param   typeOfMapping   Mapping which describes what fields to get for what object type.
     * @return  This query factory instance
     */
    @NamespaceAccessible
    public dfflib_QueryFactory selectFieldsTypeOf( String field, Map<Schema.SObjectType, Set<Schema.SObjectField>> typeOfMapping ){
        String selectTypeOfClause = 'TYPEOF ' + field;
        for( Schema.SObjectType sObjType : typeOfMapping.keySet() ){
            List<String> fieldsAsStrings = new List<String>();
            for( Schema.SObjectField sObjField : typeOfMapping.get( sObjType ) ){
                fieldsAsStrings.add( String.valueOf( sObjField ) );
            }
            selectTypeOfClause += ' WHEN ' + sObjType + ' THEN ' + String.join( fieldsAsStrings, ',' );
        }
        selectTypeOfClause += ' END';

        fields.add( selectTypeOfClause );
        return this;
    }

    /**
     * Method that sets the sets the 'WHERE' clause with the condition provided
     * 
     * @param   conditionExpression     Sets the 'WHERE' clause to the string provided. Do not include the 'WHERE'
     * @return  Returns this dfflib_QueryFactory instance
     */
    @NamespaceAccessible
    public dfflib_QueryFactory setCondition( String conditionExpression ){
        this.conditionExpression = conditionExpression;
        return this;
    }

    /**
     * Method that returns the current value of the 'WHERE' clause
     * 
     * @return  The current value of the 'WHERE' clause, if any, as set by {@link #setCondition}
     */
    @NamespaceAccessible
    public String getCondition(){
        return this.conditionExpression;
    }

    /**
     * Method that sets the 'HAVING' clause with the condition provided
     *
     * <dl>
     * <dt><span><strong>NOTE:</strong></span></dt><dd>
     *     A HAVING clause can't contain any semi-join or anti-join subqueries.
     * </dd>
     * </dl>
     *
     * @param   havingExpression     Sets the 'HAVING' clause to the string provided. Do not include the 'HAVING'
     * @return  Returns this dfflib_QueryFactory instance
     */
    @NamespaceAccessible
    public dfflib_QueryFactory setHaving( String havingExpression ){
        this.havingExpression = havingExpression;

        if( String.isEmpty( this.getGroupByField() ) ){
            System.debug( LoggingLevel.WARN, '*** IMPORTANT: A \'HAVING\' clause was set on this query without a \'GROUP BY\' clause. ' +
                'The usage of this clause without a \'GROUP BY\' clause will cause a runtime exception. Please set a \'GROUP BY\' clause for the \'HAVING\' clause to be valid.' );
        }
        return this;
    }

    /**
     * Method that sets an integer count limit to the query
     * 
     * @param   limitCount  If not null causes a 'LIMIT' clause to be added to the resulting query
     * @return  Returns this dfflib_QueryFactory instance
     */
    @NamespaceAccessible
    public dfflib_QueryFactory setLimit( Integer limitCount ){
        this.limitCount = limitCount;
        return this;
    }

    /**
     * Method that returns the current value set in 'LIMIT' clause
     * 
     * @return  The current value of the 'LIMIT' clause, if any
     */
    @NamespaceAccessible
    public Integer getLimit(){
        return this.limitCount;
    }

    /**
     * Method that sets an integer value to the 'OFFSET' clause
     * 
     * @param   offsetCount     If not null causes a 'OFFSET' clause to be added to the resulting query
     * @return  Returns this dfflib_QueryFactory instance
     */
    @NamespaceAccessible
    public dfflib_QueryFactory setOffset( Integer offsetCount ){
        this.offsetCount = offsetCount;
        return this;
    }

    /**
     * Method that returns the current value of the 'OFFSET' clause
     * 
     * @return the current value of the 'OFFSET' clause, if any
     */
    @NamespaceAccessible
    public Integer getOffset(){
        return this.offsetCount;
    }

    /**
     * Method that sets flag to append 'ALL ROWS' results to the query
     *
     * @param   allRows     whether 'ALL ROWS' should be appended to the query
     * @return  Returns this dfflib_QueryFactory instance
     */
    @NamespaceAccessible
    public dfflib_QueryFactory setAllRows( Boolean allRows ){
        this.allRows = allRows;
        return this;
    }

    /**
     * Method that returns the current value of the flag for the 'ALL ROWS' clause
     * @return  the current value of the 'ALL ROWS' clause, if any.
     */
    @NamespaceAccessible
    public Boolean getAllRows(){
        return this.allRows;
    }

    /**
     * Method that sets the grouping of the query by the specified field name
     * NOTE: Automatically resets ORDER BY to prevent SOQL failure for when the default order-field (Name, Id, ...) is not in the group by clause.
     *       When one requires the default ORDER BY field to be preserved, call setGroupByField( groupByField, true );
     *
     * @param   groupByField         Field (String or SObjectField) by which the SOQL query should be GROUPed BY
     * @param   preserveOrderings    Opt. Boolean to keep default orderby fields, like when getOrderBy() method is overridden in selector implementation
     * @return  Returns this dfflib_QueryFactory instance
     */
    @NamespaceAccessible
    public dfflib_QueryFactory setGroupByField( SObjectField groupByField ){
        return this.setGroupByField( groupByField, false );
    }
    @NamespaceAccessible
    public dfflib_QueryFactory setGroupByField( SObjectField groupByField, Boolean preserveOrderings ){
        return this.setGroupByField( groupByField.getDescribe().getName(), preserveOrderings );
    }

    @NamespaceAccessible
    public dfflib_QueryFactory setGroupByField( String groupByField ){
        return this.setGroupByField( groupByField, false );
    }
    @NamespaceAccessible
    public dfflib_QueryFactory setGroupByField( String groupByField, Boolean preserveOrderings ){
        this.groupByFieldName = groupByField;
        if( preserveOrderings == false ){
            this.emptyOrdering();
        }

        return this;
    }

    /**
     * Method that returns the current value set in the 'GROUP BY' clause
     *
     * @return  The current value of the 'GROUP BY' clause field name, if any
     */
    @NamespaceAccessible
    public String getGroupByField(){
        return this.groupByFieldName;
    }

    /**
     * Method that add a specific ordering to the query, represented here by the Ordering object provided
     *
     * @param   orderingObject  An instance of {@link dfflib_QueryFactory.Ordering} to be added to the query's 'ORDER BY' clause
     * @return  Returns this dfflib_QueryFactory instance
     */
    @NamespaceAccessible
    public dfflib_QueryFactory addOrdering( Ordering orderingObject ){
        this.order.add( orderingObject );
        return this;
    }

    /**
     * Method that sets a specific ordering in the query, represented here by the Ordering object provided
     *
     * @param   orderingObject  An instance of {@link dfflib_QueryFactory.Ordering} to remove all existing
     *                          (for instance defaults) and be added to the query's 'ORDER BY' clause
     * @return  Returns this dfflib_QueryFactory instance
     */
    @NamespaceAccessible
    public dfflib_QueryFactory setOrdering( Ordering orderingObject ){
        this.order = new List<Ordering>{ orderingObject };
        return this;
    }

    /**
     * Method that returns the current state of order of the query
     *
     * @return  The list of orderings that will be used as the query's 'ORDER BY' clause. You may remove elements from
     *          the returned list, or otherwise mutate it, to remove previously added orderings
     */
    @NamespaceAccessible
    public List<Ordering> getOrderings(){
        return this.order;
    }

    /**
     * Method that returns the current set of selected fields (i.e. fields that belong to the selection of the 'SELECT' clause)
     *
     * @return  Set of selected fields
     */
    @NamespaceAccessible
    public Set<String> getSelectedFields(){
        return this.fields;
    }

    /**
     * Method that sets the 'FOR VIEW' clause of the query.
     *
     * <dl>
     * <dt><span><strong>NOTE:</strong></span></dt><dd>
     *     Use the 'FOR VIEW' only when one is sure that the
     *     retrieved records will definitely be viewed by the logged-in user, else the clause incorrectly updates the usage information for the records.
     *     Also, the user won't recognize any incorrectly updated records when they display in the recent items and the global search auto-complete lists.</dd>
     * </dl>
     *
     * @param   forView    If true, the resulting query will include 'FOR VIEW'
     * @return  Returns this dfflib_QueryFactory instance
     */
    @NamespaceAccessible
    public dfflib_QueryFactory setForView( Boolean forView ){
        this.forView = forView;
        return this;
    }

    /**
     * Method that sets the 'FOR REFERENCE' clause of the query.
     *
     * <dl>
     * <dt><span><strong>NOTE:</strong></span></dt><dd>
     *     Use the 'FOR REFERENCE' only when one is sure that the
     *     retrieved records will definitely be viewed by the logged-in user, else the clause incorrectly updates the usage information for the records.
     *     Also, the user won't recognize any incorrectly updated records when they display in the recent items and the global search auto-complete lists.</dd>
     * </dl>
     *
     * @param   forReference   If true, the resulting query will include 'FOR REFERENCE'
     * @return  Returns this dfflib_QueryFactory instance
     */
    @NamespaceAccessible
    public dfflib_QueryFactory setForReference( Boolean forReference ){
        this.forReference = forReference;
        return this;
    }

    /**
     * Method that sets the 'FOR UPDATE' clause of the query.
     *
     * <dl>
     * <dt><span><strong>NOTE:</strong></span></dt><dd>
     *     SOQL does not support 'ORDER BY' with 'FOR UPDATE' (row locking). To use locking,
     *     you must first clear any existing orderings. Use {@link #emptyOrdering()} to
     *     remove all orderings before enabling this option, or use {@link #setOrdering(Ordering)}
     *     to replace all orderings with a single one.
     * </dd>
     * </dl>
     *
     * @param   forUpdate  If true, the resulting query will include 'FOR UPDATE'.
     *                     This locks the retrieved records, preventing other transactions
     *                     from modifying them until the next DML operation or rollback.
     * @return  Returns this dfflib_QueryFactory instance
     */
    @NamespaceAccessible
    public dfflib_QueryFactory setForUpdate( Boolean forUpdate ){
        this.forUpdate = forUpdate;
        return this;
    }

    /**
     * Add a subquery query to this query. If a subquery for this relationship already exists, it will be returned.
     * If not, a new one will be created and returned
     *
     * @deprecated  Replaced by {@link #subselectQuery(String relationshipName)} and {@link #subselectQuery(ChildRelationship relationship)}
     * @exception   InvalidSubqueryRelationshipException() if this method is called on a subselectQuery or with an invalid relationship
     * @param   related     The related object type
     * @return  Returns this dfflib_QueryFactory instance
     */
    @NamespaceAccessible
    public dfflib_QueryFactory subselectQuery( SObjectType related ){
        System.debug( LoggingLevel.WARN, 'dfflib_QueryFactory.subselectQuery(Schema.SObjectType) is deprecated and will be ' +
            'removed in a future release. Use dfflib_QueryFactory.subselectQuery(String) or dfflib_QueryFactory.subselectQuery(ChildRelationship) instead.' );
        return setSubselectQuery( getChildRelationship( related ), false );
    }

    /**
     * Add a subquery query to this query. If a subquery for this relationship already exists, it will be returned.
     * If not, a new one will be created and returned
     *
     * @deprecated  Replaced by {@link #subselectQuery(String relationshipName, Boolean assertIsAccessible)} and {@link #subselectQuery(ChildRelationship relationship, Boolean assertIsAccessible)}
     * @exception   InvalidSubqueryRelationshipException() if this method is called on a subselectQuery or with an invalid relationship
     * @param   related                 The related object type
     * @param   assertIsAccessible      Indicates whether to check if the user has access to the subquery object
     * @return  Returns this dfflib_QueryFactory instance
     */
    @NamespaceAccessible
    public dfflib_QueryFactory subselectQuery( SObjectType related, Boolean assertIsAccessible ){
        System.debug( LoggingLevel.WARN, 'dfflib_QueryFactory.subselectQuery(Schema.SObjectType, Boolean) is deprecated and will be ' +
            'removed in a future release. Use dfflib_QueryFactory.subselectQuery(String, Boolean) or dfflib_QueryFactory.subselectQuery(ChildRelationship, Boolean) instead.' );
        return setSubselectQuery( getChildRelationship( related ), assertIsAccessible );
    }

    /**
     * Add a subquery query to this query. If a subquery for this relationshipName already exists, it will be returned.
     * If not, a new one will be created and returned
     *
     * @exception   InvalidSubqueryRelationshipException() if this method is called on a subselectQuery or with an invalid relationship
     * @param   relationshipName    The relationshipName to be added as a subquery
     * @return  Returns this dfflib_QueryFactory instance
     */
    @NamespaceAccessible
    public dfflib_QueryFactory subselectQuery( String relationshipName ){
        return subselectQuery( relationshipName, false );
    }

    /**
     * Add a subquery query to this query. If a subquery for this relationship already exists, it will be returned.
     * If not, a new one will be created and returned
     *
     * @exception   InvalidSubqueryRelationshipException() if this method is called on a subselectQuery or with an invalid relationship
     * @param   relationshipName        The relationshipName to be added as a subquery
     * @param   assertIsAccessible      Indicates whether to check if the user has access to the subquery object
     * @return  Returns this dfflib_QueryFactory instance
     */
    @NamespaceAccessible
    public dfflib_QueryFactory subselectQuery( String relationshipName, Boolean assertIsAccessible ){
        Schema.ChildRelationship relationship = getChildRelationship( relationshipName );
        if( relationship != null ){
            return setSubselectQuery( relationship, assertIsAccessible );
        }

        throw new InvalidSubqueryRelationshipException( 'Invalid call to subselectQuery with relationshipName = '
            + relationshipName + '.  Relationship does not exist for ' + table.getDescribe().getName() );
    }

    /**
     * Add a subquery query to this query. If a subquery for this relationshipName already exists, it will be returned.
     * If not, a new one will be created and returned
     *
     * @exception   InvalidSubqueryRelationshipException() if this method is called on a subselectQuery or with an invalid relationship
     * @param   relationship    The ChildRelationship to be added as a subquery
     * @return  Returns this dfflib_QueryFactory instance
     */
    @NamespaceAccessible
    public dfflib_QueryFactory subselectQuery( Schema.ChildRelationship relationship ){
        return subselectQuery( relationship, false );
    }

    /**
     * Add a subquery query to this query.  If a subquery for this relationship already exists, it will be returned.
     * If not, a new one will be created and returned
     *
     * @exception   InvalidSubqueryRelationshipException() if this method is called on a subselectQuery or with an invalid relationship
     * @param   relationship        The ChildRelationship to be added as a subquery
     * @param   assertIsAccessible  Indicates whether to check if the user has access to the subquery object
     * @return  Returns this dfflib_QueryFactory instance
     */
    @NamespaceAccessible
    public dfflib_QueryFactory subselectQuery( Schema.ChildRelationship relationship, Boolean assertIsAccessible ){
        return setSubselectQuery( relationship, assertIsAccessible );
    }

    /**
     * Add a subquery query to this query.  If a subquery for this relationship already exists, it will be returned.
     * If not, a new one will be created and returned
     *
     * @exception   InvalidSubqueryRelationshipException() if this method is called on a subselectQuery or with an invalid relationship
     * @param   relationship            The ChildRelationship to be added as a subquery
     * @param   assertIsAccessible      Boolean indicating if asserting is accessible
     * @return  Returns this dfflib_QueryFactory instance
     */
    private dfflib_QueryFactory setSubselectQuery( Schema.ChildRelationship relationship, Boolean assertIsAccessible ){
        if( this.subSelectQueryMap == null ){
            this.subSelectQueryMap = new Map<Schema.ChildRelationship, dfflib_QueryFactory>();
        }
        if( this.subSelectQueryMap.containsKey( relationship ) ){
            return subSelectQueryMap.get( relationship );
        }

        dfflib_QueryFactory subSelectQuery = new dfflib_QueryFactory( relationship );

        // The child queryFactory should be configured in the same way as the parent by default - can override after if required
        subSelectQuery.setSortSelectFields( sortSelectFields );
        // Child queries inherit the parent's FLS enforcement level to ensure field path resolution behaves consistently -
        // specifically, field name casing (lowercase for USER_MODE/SYSTEM_MODE vs. case-preserving for LEGACY) must match across the query hierarchy to prevent duplicate fields in SELECT clauses.
        // The database context (queryProxy) is intentionally not propagated: the parent QueryFactory owns the execution context, and child subqueries are embedded in the parent's SOQL - they cannot specify independent access levels.
        subSelectQuery.setEnforceFLS( this.mFlsEnforcement );
        if( assertIsAccessible ){
            subSelectQuery.assertIsAccessible();
        }

        subSelectQueryMap.put( relationship, subSelectQuery );
        return subSelectQuery;
    }

    /**
     * Method that returns a list of subselect queries
     *
     * @returns The list of subquery instances of dfflib_QueryFactory which will be added to the SOQL as relationship/child/sub-queries
     */
    @NamespaceAccessible
    public List<dfflib_QueryFactory> getSubselectQueries(){
        if( subSelectQueryMap != null ){
            return subSelectQueryMap.values();
        }
        return null;
    }

    /**
     * Method that gets the ChildRelationship from the table for the object type passed in
     *
     * @param   objType     The object type of the child relationship to get
     * @return  Returns the Schema.ChildRelationship from the table of the object type
     */
    private Schema.ChildRelationship getChildRelationship( SObjectType objType ){
        for( Schema.ChildRelationship childRow : table.getDescribe().getChildRelationships() ){
            // Occasionally on some standard objects (Like Contact child of Contact) do not have a relationship name
            // If there is no relationship name, we cannot query on it, so throw an exception
            if( childRow.getChildSObject() == objType && childRow.getRelationshipName() != null ){
                return childRow;
            }
        }

        throw new InvalidSubqueryRelationshipException( 'Invalid call to subselectQuery.  Invalid relationship for table ' + table + ' and objtype=' + objType );
    }

    /**
     * Method that gets the ChildRelationship from the table for the relationship name passed in
     *
     * @param   relationshipName    The name of the object's ChildRelationship on get
     * @return  Returns the Schema.ChildRelationship from the table of the relationship name passed
     */
    private Schema.ChildRelationship getChildRelationship( String relationshipName ){
        for( Schema.ChildRelationship childRow : table.getDescribe().getChildRelationships() ){
            if( childRow.getRelationshipName() == relationshipName ){
                return childRow;
            }
        }

        return null;
    }

    /**
     * Add a field to be sorted on. This may be a direct field or a field
     * related through an object lookup or master-detail relationship.
     * Use the set to store unique field names, since we only want to sort
     * by the same field one time.  The sort expressions are stored in a list
     * so that they are applied to the SOQL in the same order that they
     * were added in
     *
     * @param   fieldName   The string value of the field to be sorted on
     * @param   direction   The direction to be sorted on (ASCENDING or DESCENDING)
     * @param   nullsLast   Whether to sort null values last (NULLS LAST keyword included)
     * @return  Returns this dfflib_QueryFactory instance
     */
    @NamespaceAccessible
    public dfflib_QueryFactory addOrdering( String fieldName, SortOrder direction, Boolean nullsLast ){
        order.add(
            new Ordering( getFieldPath( fieldName ), direction, nullsLast )
        );
        return this;
    }

    /**
     * Add a field to be sorted on. This may be a direct field or a field
     * related through an object lookup or master-detail relationship.
     * Use the set to store unique field names, since we only want to sort
     * by the same field one time.  The sort expressions are stored in a list
     * so that they are applied to the SOQL in the same order that they
     * were added in
     *
     * @param    field       The SObjectfield to sort. This can only be a direct reference
     * @param    direction   The direction to be sorted on (ASCENDING or DESCENDING)
     * @param    nullsLast   Whether to sort null values last (NULLS LAST keyword included)
     * @return  Returns this dfflib_QueryFactory instance
     */
    @NamespaceAccessible
    public dfflib_QueryFactory addOrdering( SObjectField field, SortOrder direction, Boolean nullsLast ){
        order.add(
            new Ordering( getFieldTokenPath( field ), direction, nullsLast )
        );
        return this;
    }

    /**
	 * Add a field to be sorted on. This may be a direct field or a field
	 * related through an object lookup or master-detail relationship.
	 * Use the set to store unique field names, since we only want to sort
	 * by the same field one time.  The sort expressions are stored in a list
	 * so that they are applied to the SOQL in the same order that they
	 * were added in. 
	 * The "NULLS FIRST" keywords will be included by default. If "NULLS LAST"
	 * is required, use one of the overloaded addOrdering methods which include this parameter
	 *
	 * @param   fieldName   The string value of the field to be sorted on
	 * @param   direction   The direction to be sorted on (ASCENDING or DESCENDING)
	 * @return  Returns this dfflib_QueryFactory instance
	 */
    @NamespaceAccessible
    public dfflib_QueryFactory addOrdering( String fieldName, SortOrder direction ){
        order.add(
            new Ordering( getFieldPath( fieldName ), direction )
        );
        return this;
    }

    /**
     * Add a field to be sorted on. This may be a direct field or a field
     * related through an object lookup or master-detail relationship.
     * Use the set to store unique field names, since we only want to sort
     * by the same field one time.  The sort expressions are stored in a list
     * so that they are applied to the SOQL in the same order that they
     * were added in.
     * The "NULLS FIRST" keywords will be included by default. If "NULLS LAST"
     * is required, use one of the overloaded addOrdering methods which include this parameter
     *
     * @param   field       The SObjectfield to sort. This can only be a direct reference
     * @param   direction   The direction to be sorted on (ASCENDING or DESCENDING)
     * @return  Returns this dfflib_QueryFactory instance
     */
    @NamespaceAccessible
    public dfflib_QueryFactory addOrdering( SObjectField field, SortOrder direction ){
        order.add(
            new Ordering( getFieldTokenPath( field ), direction )
        );
        return this;
    }

    /**
     * Method that empties the default ordering by name/id by fflib
     */
    @NamespaceAccessible
    public void emptyOrdering(){
        this.order = new List<Ordering>();
    }

    /**
     * Remove existing ordering and set a field to be sorted on. This may be a direct field or a field
     * related through an object lookup or master-detail relationship.
     * Use the set to store unique field names, since we only want to sort
     * by the same field one time. The sort expressions are stored in a list
     * so that they are applied to the SOQL in the same order that they
     * were added in
     *
     * @param   fieldName   The string value of the field to be sorted on
     * @param   direction   The direction to be sorted on (ASCENDING or DESCENDING)
     * @param   nullsLast   Whether to sort null values last (NULLS LAST keyword included)
     * @return  Returns this dfflib_QueryFactory instance
     */
    @NamespaceAccessible
    public dfflib_QueryFactory setOrdering( String fieldName, SortOrder direction, Boolean nullsLast ){
        Ordering orderingObject = new Ordering( getFieldPath( fieldName ), direction, nullsLast );
        return setOrdering( orderingObject );
    }

    /**
     * Remove existing ordering and set a field to be sorted on.  This may be a direct field or a field
     * related through an object lookup or master-detail relationship.
     * Use the set to store unique field names, since we only want to sort
     * by the same field one time.  The sort expressions are stored in a list
     * so that they are applied to the SOQL in the same order that they
     * were added in
     *
     * @param   field       The SObjectfield to sort. This can only be a direct reference
     * @param   direction   The direction to be sorted on (ASCENDING or DESCENDING)
     * @param   nullsLast   Whether to sort null values last (NULLS LAST keyword included)
     * @return  Returns this dfflib_QueryFactory instance
     */
    @NamespaceAccessible
    public dfflib_QueryFactory setOrdering( SObjectField field, SortOrder direction, Boolean nullsLast ){
        Ordering orderingObject = new Ordering( getFieldTokenPath( field ), direction, nullsLast );
        return setOrdering( orderingObject );
    }

    /**
     * Remove existing ordering and set a field to be sorted on. This may be a direct field or a field
     * related through an object lookup or master-detail relationship.
     * Use the set to store unique field names, since we only want to sort
     * by the same field one time. The sort expressions are stored in a list
     * so that they are applied to the SOQL in the same order that they
     * were added in
     *
     * @param   fieldName   The string value of the field to be sorted on
     * @param   direction   The direction to be sorted on (ASCENDING or DESCENDING)
     * @return  Returns this dfflib_QueryFactory instance
     */
    @NamespaceAccessible
    public dfflib_QueryFactory setOrdering( String fieldName, SortOrder direction ){
        Ordering orderingObject = new Ordering( getFieldPath( fieldName ), direction );
        return setOrdering( orderingObject );
    }

    /**
     * Remove existing ordering and set a field to be sorted on. This may be a direct field or a field
     * related through an object lookup or master-detail relationship.
     * Use the set to store unique field names, since we only want to sort
     * by the same field one time. The sort expressions are stored in a list
     * so that they are applied to the SOQL in the same order that they
     * were added in
     *
     * @param   field       The SObjectfield to sort. This can only be a direct reference
     * @param   direction   The direction to be sorted on (ASCENDING or DESCENDING)
     * @return  Returns this dfflib_QueryFactory instance
     */
    @NamespaceAccessible
    public dfflib_QueryFactory setOrdering( SObjectField field, SortOrder direction ){
        Ordering orderingObject = new Ordering( getFieldTokenPath( field ), direction );
        return setOrdering( orderingObject );
    }

    /**
     * Returns a SOQL DISTANCE expression String for use in SELECT, WHERE, or ORDER BY clauses.
     * The expression uses SOQL bind variable syntax ({@code :latitude}, {@code :longitude}) so that
     * different coordinates reuse the same query plan. Ensure to pass the actual values via
     * {@link dfflib_Database#executeQuery(dfflib_QueryFactory, Map)} or {@code Database.queryWithBinds}.
     *
     * @param   field   The {@link Schema.SObjectField} token of the location or address compound field
     * @param   unit    The distance unit — {@link DistanceUnit#KILOMETERS} ('km') or {@link DistanceUnit#MILES} ('mi')
     * @return  A {@code DISTANCE( fieldName, GEOLOCATION(:latitude, :longitude), 'unit' )} expression string
     */
    @NamespaceAccessible
    public String getDistanceString( SObjectField field, DistanceUnit unit ){
        return String.format(
            'DISTANCE( {0}, GEOLOCATION(:latitude, :longitude), {1} )',
            new List<String>{
                getFieldTokenPath( field ),
                unit == DistanceUnit.KILOMETERS ? '\'km\'' : '\'mi\''
            }
        );
    }

    /**
     * Method that converts the values provided to this instance into a full SOQL string for use with Database.query
     * Check to see if subqueries queries need to be added after the field list
     *
     * @return  String representing the query to be used with Database.query()
     */
    @NamespaceAccessible
    public String toSOQL(){
        String result = 'SELECT ';
        // If no fields have been added, just add the Id field so that the query or subquery will not just fail
        if( this.fields.size() == 0 ){
            if( mFlsEnforcement == FLSEnforcement.LEGACY ){
                fflib_SecurityUtils.checkFieldIsReadable( this.table, 'Id' );
            }
            result += 'Id';
        } else{
            List<String> fieldsToQuery = new List<String>( this.fields );
            if( this.sortSelectFields ){
                fieldsToQuery.sort();
            }

            result += String.join( fieldsToQuery, ', ' );
        }

        if( this.subSelectQueryMap != null && !this.subSelectQueryMap.isEmpty() ){
            for( dfflib_QueryFactory childRow : this.subSelectQueryMap.values() ){
                result += ', (' + childRow.toSOQL() + ') ';
            }
        }

        result += ' FROM ' + ( this.relationship != null ? this.relationship.getRelationshipName() : this.table.getDescribe().getName() );
        if( this.conditionExpression != null ){
            result += ' WHERE ' + this.conditionExpression;
        }

        if( String.isNotBlank( this.groupByFieldName ) ){
            result += ' GROUP BY ' + this.groupByFieldName;

            // GROUP BY must exist for HAVING to be valid, set immediately after GROUP BY clause
            if( this.havingExpression != null ){
                result += ' HAVING ' + this.havingExpression;
            }
        } else if( this.havingExpression != null ){
            throw new dfflib_Utils.InvalidImplementationException('A \'HAVING\' clause was set on this query without a \'GROUP BY\' clause. ' +
                'Please set a \'GROUP BY\' clause for the \'HAVING\' clause to be valid.' );
        }

        if( this.order.size() > 0 ){
            result += ' ORDER BY ';
            for( Ordering orderingObject : this.order ){
                result += orderingObject.toSOQL() + ', ';
            }

            result = result.substring( 0, result.length() - 2 );
        }

        if( this.limitCount != null ){
            result += ' LIMIT ' + this.limitCount;
        }

        if( this.offsetCount != null ){
            result += ' OFFSET ' + this.offsetCount;
        }

        if( this.allRows ){
            result += ' ALL ROWS';
        }

        if( this.forView && this.forReference ){
            throw new dfflib_Utils.InvalidImplementationException( 'A query cannot be set to use both FOR VIEW and FOR REFERENCE clauses. Please choose one or the other.' );
        } else if( this.forView ){
            result += ' FOR VIEW';
        } else if( this.forReference ){
            result += ' FOR REFERENCE';
        }

        if( this.forUpdate ){
            result += ' FOR UPDATE';
        }

        // Allow unit tests to access the last instance of a query factory
        lastQueryFactory = this;

        return result;
    }

    /**
     * Create a "deep" clone of this object that can be safely mutated without affecting the cloned instance
     *
     * @return  A deep clone of this dfflib_QueryFactory
     */
    @NamespaceAccessible
    public dfflib_QueryFactory deepClone(){

        dfflib_QueryFactory clone = new dfflib_QueryFactory( this.table )
            .setLimit( this.getLimit() )
            .setOffset( this.getOffset() )
            .setCondition( this.getCondition() )
            .setAllRows( this.getAllRows() )
            .setGroupByField( this.getGroupByField() )
            .setHaving( this.havingExpression )
            .setForView( this.forView )
            .setForReference( this.forReference )
            .setForUpdate( this.forUpdate )
            .setEnforceFLS( this.mFlsEnforcement );

        Map<Schema.ChildRelationship, dfflib_QueryFactory> subQueries = this.subSelectQueryMap;
        if( subQueries != null ){
            Map<Schema.ChildRelationship, dfflib_QueryFactory> clonedSubqueries = new Map<Schema.ChildRelationship, dfflib_QueryFactory>();
            for( Schema.ChildRelationship key : subQueries.keySet() ){
                clonedSubqueries.put( key, subQueries.get( key ).deepClone() );
            }
            clone.subSelectQueryMap = clonedSubqueries;
        }

        clone.relationship = this.relationship;
        clone.order = this.order.clone();
        clone.fields = this.fields.clone();

        return clone;
    }

    @NamespaceAccessible
    public class Ordering{
        private SortOrder direction;
        private Boolean nullsLast;
        private String field;

        @NamespaceAccessible
        public Ordering( String sobjType, String fieldName, SortOrder direction ){
            this(
                fflib_SObjectDescribe.getDescribe( sobjType ).getField( fieldName ),
                direction
            );
        }

        /**
         * Construct a new ordering instance for use with {@link dfflib_QueryFactory#addOrdering}
         * Once constructed it's properties may not be modified.
         */
        @NamespaceAccessible
        public Ordering( Schema.SObjectField field, SortOrder direction ){
            this( dfflib_QueryFactory.getFieldTokenPath( field ), direction, false ); // SOQL docs state NULLS FIRST is default behavior
        }

        @NamespaceAccessible
        public Ordering( Schema.SObjectField field, SortOrder direction, Boolean nullsLast ){
            this( dfflib_QueryFactory.getFieldTokenPath( field ), direction, nullsLast );
        }

        @TestVisible
        private Ordering( String field, SortOrder direction ){
            this( field, direction, false );
        }

        @TestVisible
        private Ordering( String field, SortOrder direction, Boolean nullsLast ){
            this.direction = direction;
            this.field = field;
            this.nullsLast = nullsLast;
        }

        @NamespaceAccessible
        public String getField(){
            return this.field;
        }

        @NamespaceAccessible
        public SortOrder getDirection(){
            return direction;
        }

        @NamespaceAccessible
        public String toSOQL(){
            return field + ' ' + ( direction == SortOrder.ASCENDING ? 'ASC' : 'DESC' ) + ( nullsLast ? ' NULLS LAST ' : ' NULLS FIRST ' );
        }
    }


    @NamespaceAccessible
    public class InvalidFieldException extends Exception{
        private String fieldName;
        private Schema.SObjectType objectType;

        @NamespaceAccessible
        public InvalidFieldException( String fieldName, Schema.SObjectType objectType ){
            this.objectType = objectType;
            this.fieldName = fieldName;
            this.setMessage( 'Invalid field \'' + fieldName + '\' for object \'' + objectType + '\'' );
        }
    }

    @NamespaceAccessible
    public class InvalidFieldSetException extends Exception{}
    @NamespaceAccessible
    public class NonReferenceFieldException extends Exception{}
    @NamespaceAccessible
    public class PolymorphicLookupException extends Exception{}
    @NamespaceAccessible
    public class InvalidSubqueryRelationshipException extends Exception{}
}