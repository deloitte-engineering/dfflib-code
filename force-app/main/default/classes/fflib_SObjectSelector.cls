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
 * Class providing common database query support for abstracting and encapsulating query logic.
 * Inherits sharing, allowing extending-selectors to control whether SObjectDescribe runs in system (without) or user (with) mode.
 * Enabling to (opt.) bypass unavailable SObjectTypes like AccountTeamMembers for Community Licenses (do align with Project Salesforce Success Manager).
 * Note, SObjectSelector is an abstract class with no queries being performed, so no regression data vulnerability are expected.
 * To still run those queries with sharing enforced, one can construct the base selector with the desired security context ({@link fflib_Database.Context})
 */
public abstract class fflib_SObjectSelector implements fflib_ISObjectSelector{
    public enum DataAccess{ LEGACY, USER_MODE, SYSTEM_MODE }
    private static final Map<DataAccess, fflib_Database.Context> ACCESS_TO_CONTEXT_MAP = new Map<DataAccess, fflib_Database.Context>{
        DataAccess.LEGACY => fflib_Database.Context.INHERIT,
        DataAccess.USER_MODE => fflib_Database.Context.FULL,
        DataAccess.SYSTEM_MODE => fflib_Database.Context.NONE
    };

    /**
     * Indicates whether the sObject has the currency ISO code field for organisations which have multi-currency
     * enabled.
     */
    private Boolean CURRENCY_ISO_CODE_ENABLED{
        get{
            if( CURRENCY_ISO_CODE_ENABLED == null ){
                CURRENCY_ISO_CODE_ENABLED = describeWrapper.getFieldsMap().keySet().contains( 'currencyisocode' );
            }
            return CURRENCY_ISO_CODE_ENABLED;
        }
        set;
    }

    /**
     * Should this selector automatically include the FieldSet fields when building queries?
     */
    private Boolean m_includeFieldSetFields = false;

    /**
     * Should this selector automatically include the related FieldSet fields when building queries?
     */
    private Boolean m_includeRelatedFieldSetFields = false;

    /**
     * Enforce FLS Security. By default, no value assigned to direct FLS/CRUD checks in runtime via AccessLevel.USER_MODE
     * @deprecated - Consider using fflib_Database.Context for native platform enforcement of FLS
     */
    private Boolean m_enforceFLS;

    /**
     * Enforce CRUD Security. By default, no value assigned to direct FLS/CRUD checks in runtime via AccessLevel.USER_MODE
     * @deprecated - Consider using fflib_Database.Context for native platform enforcement of CRUD
     */
    private Boolean m_enforceCRUD;

    /**
     * Order by field
     */
    private String m_orderBy;

    @TestVisible
    private fflib_Database.Context m_securityContext;
    private fflib_Database.Context defaultSecurityContext = fflib_Database.Context.INHERIT;

    private Boolean m_sortSelectFields = false;

    /**
     * Describe helper
     */
    private fflib_SObjectDescribe describeWrapper{
        get{
            if( describeWrapper == null ){
                describeWrapper = fflib_SObjectDescribe.getDescribe( getSObjectType() );
            }
            return describeWrapper;
        }
        set;
    }

    // Inner interface implementation of QueryProxy, determines run-time sharing context
    @TestVisible
    private fflib_Database_IQuery m_queryProxy{
        get{
            if( m_queryProxy == null ){
                m_queryProxy = fflib_Database.getQueryProxy( m_securityContext ?? defaultSecurityContext );
            }

            return m_queryProxy;
        }
        set;
    }

    /**
     * Static variables
     */
    private static String DEFAULT_SORT_FIELD = 'CreatedDate';
    private static String SF_ID_FIELD = 'Id';

    /**
     * NOTE: In API version 65.0 and later, an abstract or override method requires a protected, public, or global access modifier.
     *  If one of these access modifiers isn’t explicitly included in the method declaration, then method access defaults to private.
     *  Private access is invalid for these method types because the implementing class can’t access the abstract method.
     *  Therefore, by attempting to declare an abstract or override method without an allowed access modifier, one would get the compilation error
     *  'Abstract methods require at least one of the following: global, public, protected.'
     *
     *  This implies that base methods such as getSObjectType() / getSObjectFieldList() should be:
     *      - Made visible (either public or protected) to extensions of the base class
     *      - Require an implementation by child classes (and for existing implementations of the method, to add the 'override' keyword)
     */
    /**
     * Implement this method to inform the base class of the SObject (custom or standard) to be queried
     */
    protected abstract Schema.SObjectType getSObjectType();

    /**
     * Implement this method to inform the base class of the common fields to be queried or listed by the base class methods
     */
    protected abstract List<Schema.SObjectField> getSObjectFieldList();

    /**
     * Allows selectors to select fields from related sObjects. Similar to getSObjectFieldList(), it works
     * with strings to be able to traverse through relationships.
     *
     * @return  Set of strings containing individual related field paths.
     */
    protected virtual Set<String> getRelatedFieldSet(){
        return new Set<String>();
    }

    /**
     * Constructs the Selector with the default settings. Security context to be provided through SelectorFactory or explicitly
     */
    public fflib_SObjectSelector(){}

    /**
     * Constructs the Selector with the default settings enforcing the provided security context
     * (sortFields: true, includeFieldSetFields: false, includeRelatedFieldSetFields: false)
     *
     * @param   securityContext         Database security context
     */
    public fflib_SObjectSelector( fflib_Database.Context securityContext ){
        this.setContext( securityContext );
    }

    /**
     * Constructs the Selector
     *
     * @param   includeFieldSetFields   Set to true if the Selector queries are to include Fieldset fields as well
     */
    public fflib_SObjectSelector( Boolean includeFieldSetFields ){
        this( includeFieldSetFields, null, null, false, false );
    }

    /**
     * @param includeFieldSetFields   Set to true if the Selector queries are to include Fieldset fields as well
     * @param access Legacy enum to specify the data access mode for this query
     * @deprecated Legacy backward-compatibility constructor, suggestion to migrate to fflib_Database.Context securityContext
     */
    public fflib_SObjectSelector( Boolean includeFieldSetFields, DataAccess access ){
        this( includeFieldSetFields, null, null, false, false, ACCESS_TO_CONTEXT_MAP.get( access ) );
    }

    /**
     * Constructs the Selector
     *
     * Note: With the introduction of {@link fflib_Database.Context}, selector constructors no longer enforce CRUD security by default.
     * Instead, sharing rules and FLS/CRUD checks will be performed in the context of the running user in run-time (by means of AccessLevel.USER_MODE).
     *
     * @param   includeFieldSetFields   Set to true if the Selector queries are to include Fieldset fields as well
     * @param   securityContext         Database security context
     */
    public fflib_SObjectSelector( Boolean includeFieldSetFields, fflib_Database.Context securityContext ){
        this( includeFieldSetFields, null, null, false, false, securityContext );
    }

    /**
     * Constructs the Selector. It sorts selected fields by default
     *
     * @param   includeFieldSetFields   Set to true if the Selector queries are to include Fieldset fields as well
     * @param   enforceCRUD             Enforce CRUD security
     * @param   enforceFLS              Enforce Field Level Security
     * @deprecated - Consider using fflib_Database.Context for native platform enforcement of CRUD and FLS
     */
    public fflib_SObjectSelector( Boolean includeFieldSetFields, Boolean enforceCRUD, Boolean enforceFLS ){
        this( includeFieldSetFields, enforceCRUD, enforceFLS, false, false );
    }

    /**
     * Constructs the Selector
     *
     * @param includeFieldSetFields     Set to true if the Selector queries are to include Fieldset fields as well
     * @param enforceCRUD               Enforce CRUD security
     * @param enforceFLS                Enforce Field Level Security
     * @param sortSelectFields          Set to false if selecting many columns to skip sorting select fields and improve performance
     * @deprecated - Consider using fflib_Database.Context for native platform enforcement of CRUD and FLS
     **/
    public fflib_SObjectSelector( Boolean includeFieldSetFields, Boolean enforceCRUD, Boolean enforceFLS, Boolean sortSelectFields ){
        this( includeFieldSetFields, enforceCRUD, enforceFLS, sortSelectFields, false );
    }
    public fflib_SObjectSelector( Boolean includeFieldSetFields, Boolean sortSelectFields, fflib_Database.Context securityContext ){
        this( includeFieldSetFields, null, null, sortSelectFields, false, securityContext );
    }

    public fflib_SObjectSelector( Boolean includeFieldSetFields, Boolean sortSelectFields, Boolean includeRelatedFieldSetFields, fflib_Database.Context securityContext ){
        this( includeFieldSetFields, null, null, sortSelectFields, includeRelatedFieldSetFields, securityContext );
    }

    /**
     * Constructs the Selector.
     *
     * @param   includeFieldSetFields           Set to true if the Selector queries are to include Fieldset fields as well
     * @param   enforceCRUD                     Enforce CRUD security
     * @param   enforceFLS                      Enforce Field Level Security
     * @param   sortSelectFields                Set to false if selecting many columns to skip sorting select fields and improve performance
     * @param   includeRelatedFieldSetFields    Set to true if the Selector queries are to include related Fieldset fields as well
     * @deprecated - Consider using fflib_Database.Context for native platform enforcement of CRUD and FLS
     */
    public fflib_SObjectSelector( Boolean includeFieldSetFields, Boolean enforceCRUD, Boolean enforceFLS, Boolean sortSelectFields, Boolean includeRelatedFieldSetFields ){
        this.m_includeFieldSetFields = includeFieldSetFields;
        this.m_enforceCRUD = enforceCRUD;
        this.m_enforceFLS = enforceFLS;
        this.m_sortSelectFields = sortSelectFields;
        this.m_includeRelatedFieldSetFields = includeRelatedFieldSetFields;
    }
    /**
     * @deprecated Legacy backward-compatibility constructor, suggestion to migrate to fflib_Database.Context
     */
    public fflib_SObjectSelector( Boolean includeFieldSetFields, Boolean enforceCRUD, Boolean enforceFLS, Boolean sortSelectFields, Boolean includeRelatedFieldSetFields, DataAccess access ){
        this( includeFieldSetFields, enforceCRUD, enforceFLS, sortSelectFields, includeRelatedFieldSetFields, ACCESS_TO_CONTEXT_MAP.get( access ) );
    }
    public fflib_SObjectSelector( Boolean includeFieldSetFields, Boolean enforceCRUD, Boolean enforceFLS, Boolean sortSelectFields, Boolean includeRelatedFieldSetFields, fflib_Database.Context securityContext ){
        this( includeFieldSetFields, enforceCRUD, enforceFLS, sortSelectFields, includeRelatedFieldSetFields );
        this.setContext( securityContext );
    }

    /**
     * Virtual method to provide a list of FieldSets that can optionally drive inclusion of additional fields in the base queries
     *
     * @return  List<Schema.FieldSet> to be provided optionally to base queries
     */
    public virtual List<Schema.FieldSet> getSObjectFieldSetList(){
        return null;
    }

    /**
     * Override this method to control the default ordering of records returned by the base queries,
     * defaults to the name field of the object if it is not encrypted or CreatedDate if there the object has createdDated or Id.
     *
     * @return  String representing the ordering of records to include in base queries.
     */
    public virtual String getOrderBy(){
        if( m_orderBy == null ){
            Schema.SObjectField nameField = describeWrapper.getNameField();
            if( nameField != null && !nameField.getDescribe().isEncrypted() ){
                m_orderBy = nameField.getDescribe().getName();
            } else{
                m_orderBy = DEFAULT_SORT_FIELD;
                try{
                    if( describeWrapper.getField( m_orderBy ) == null ){
                        m_orderBy = SF_ID_FIELD;
                    }
                } catch( fflib_QueryFactory.InvalidFieldException ex ){
                    m_orderBy = SF_ID_FIELD;
                }
            }
        }
        return m_orderBy;
    }


    /**
     * Setter to enforce FLS Security
     *
     * @return  This fflib_SObjectSelector instance
     * @deprecated - Consider using fflib_Database.Context for native platform enforcement of CRUD and FLS
     */
    public fflib_SObjectSelector enforceFLS(){
        m_enforceFLS = true;
        return this;
    }

    /**
     * Setter to automatically include the FieldSet fields when building queries
     *
     * @return  This fflib_SObjectSelector instance
     */
    public fflib_SObjectSelector includeFieldSetFields(){
        this.m_includeFieldSetFields = true;
        return this;
    }

    /**
     * Setter to automatically include the related FieldSet fields when building queries
     *
     * @return  This fflib_SObjectSelector instance
     */
    public fflib_SObjectSelector includeRelatedFieldSetFields(){
        this.m_includeRelatedFieldSetFields = true;
        return this;
    }

    /**
     * Setter to ignore CRUD security
     *
     * @return  This fflib_SObjectSelector instance
     * @deprecated - Consider using fflib_Database.Context for native platform enforcement of CRUD and FLS
     */
    public fflib_SObjectSelector ignoreCRUD(){
        this.m_enforceCRUD = false;
        return this;
    }

    public fflib_SObjectSelector unsortedSelectFields(){
        this.m_sortSelectFields = false;
        return this;
    }

    /**
     * @param access enum DataAccess to specify the data access mode for this query
     * @return This fflib_SObjectSelector instance
     * @deprecated Legacy backward-compatibility method, suggestion to migrate to fflib_Database.Context
     */
    public fflib_SObjectSelector setDataAccess( DataAccess access ){
        this.setContext( ACCESS_TO_CONTEXT_MAP.get( access ) );

        // You can't mix and match the legacy enforceFls and assertCRUD with the SYSTEM_MODE or USER_MODE
        if( access != DataAccess.LEGACY ){
            ignoreCRUD();
            m_enforceFLS = false;
        }

        return this;
    }

    /**
     * Getter that returns TRUE if this Selector instance has been instructed by the caller to include Field Set fields
     *
     * @return  Boolean determining if Field Set fields are to be included
     */
    public Boolean isIncludeFieldSetFields(){
        return m_includeFieldSetFields;
    }

    /**
     * Getter that returns TRUE if this Selector instance has been instructed by the caller to include related Field Set fields
     *
     * @return  Boolean determining if related Field Set fields are to be included
     */
    public Boolean isIncludeRelatedFieldSetFields(){
        return m_includeRelatedFieldSetFields;
    }

    /**
     * Getter that returns TRUE if this Selector is enforcing FLS
     *
     * @return  Boolean determining if selector is enforcing FLS
     * @deprecated - Consider using fflib_Database.Context for native platform enforcement of CRUD and FLS
     */
    public Boolean isEnforcingFLS(){
        return m_enforceFLS;
    }

    /**
     * Getter that returns TRUE if this Selector is enforcing CRUD Security
     *
     * @return  Boolean determining if selector is enforcing CRUD
     * @deprecated - Consider using fflib_Database.Context for native platform enforcement of CRUD and FLS
     */
    public Boolean isEnforcingCRUD(){
        return m_enforceCRUD;
    }

    /**
     * Getter that returns current database security context
     *
     * @return  This instance's database context fflib_Database.Context
     */
    public fflib_Database.Context getContext(){
        return m_securityContext ?? defaultSecurityContext;
    }

    /**
     * Getter that returns TRUE if this Selector is sorting selected fields
     *
     * @return  Boolean determining if selected fields are to be sorted
     */
    public Boolean isSortingSelectedFields(){
        return m_sortSelectFields;
    }

    /**
     * Getter that returns the string representation of the SObject this selector represents
     *
     * @return  String representation of the SObject this selector represents
     */
    public String getSObjectName(){
        return describeWrapper.getDescribe().getName();
    }

    /**
     * Setter for database security model. Allows to switch flexibly between sharing modes for the same selector instance, as well as enforce CRUD/FLS checks in query runtime.
     * This setter restricts initialization of the database context to either instance constructors or factory implementations provided from in {@link fflib_Application.SelectorFactory}.
     *
     * @param   securityContext     Database security model for this selector instance
     * @return  Returns this instance
     */
    public fflib_SObjectSelector setContext( fflib_Database.Context securityContext ){
        if( this.m_securityContext == null ){
            this.m_securityContext = securityContext;
            this.m_queryProxy = fflib_Database.getQueryProxy( securityContext );

            return this;
        } else{
            throw new InvalidContextAssignmentException(
                'Database security context can only be defined when constructing a new selector instance! Please provide a valid fflib_Database.Context when creating a new instance of a selector class.'
            );
        }
    }

    /**
     * Public access for the getSObjectType during Mock registration
     *   (adding public to the existing method broken base class API backwards compatibility)
     *
     * @return  This instance's SObjectType
     */
    public SObjectType getSObjectType2(){
        return getSObjectType();
    }

    /**
     * Public access for the getSObjectType during Mock registration
     *   (adding public to the existing method broken base class API backwards compatibility)
     *
     * @return  This instance's SObjectType
     */
    public SObjectType sObjectType(){
        return getSObjectType();
    }

    /**
     * Performs a SOQL query,
     *   - Selecting the fields described via getSObjectFieldsList and getSObjectFieldSetList (if included)
     *   - From the SObject described by getSObjectType
     *   - Where the Id's match those provided in the set
     *   - Ordered by the fields returned via getOrderBy
     *
     * @param   idSet   Set<Id> to be matched
     * @return  A list of SObject's.
     */
    public virtual List<SObject> selectSObjectsById( Set<Id> idSet ){
        return this.executeQuery( buildQuerySObjectById(), new Map<String, Object>{ 'idSet' => idSet } );
    }

    /**
     * Performs a SOQL query,
     *   - Selecting the fields described via getSObjectFieldsList and getSObjectFieldSetList (if included)
     *   - From the SObject described by getSObjectType
     *   - Where the Id's match those provided in the set
     *   - Ordered by the fields returned via getOrderBy
     *
     * @param   idSet   Set<Id> to be matched
     * @return  A QueryLocator (typically for use in a Batch Apex job).
     */
    public virtual Database.QueryLocator queryLocatorById( Set<Id> idSet ){
        return this.getQueryLocator( buildQuerySObjectById(), new Map<String, Object>{ 'idSet' => idSet } );
    }


    /**
     * Method for selecting records for deletion.
     *
     * @param 	queryConditionString	The query criteria (F.e. Origin = 'Phone')
     * @return  List of records for deletion.
     */
    public Database.QueryLocator selectDeleteBatchRecords( String queryConditionString ){
        fflib_Objects.verifyNotBlank( queryConditionString, 'queryConditionString' );

        fflib_QueryFactory query = newQueryFactory();
        query.setCondition( String.escapeSingleQuotes( queryConditionString ).replace( '\\', '' ) );

        return this.getQueryLocator( query.toSOQL() );
    }

    /**
     * Method for querying and retrieving all SObject records associated with the relevant SObjectType in context by:
     *   - Selecting the fields described via getSObjectFieldsList() and getSObjectFieldSetList() (if included);
     *   - From the SObject described by getSObjectType();
     *   - Ordered by the fields returned via default getOrderBy().
     *
     * @return List of SObject records
     */
    public List<SObject> selectAllSObjectRecords(){
        return this.executeQuery( newQueryFactory().toSOQL() );
    }

    /**
     * Method to configure a QueryFactory with the Selectors object, fields, fieldsets and default order by
     *
     * @return  fflib_QueryFactory instance configured with default settings
     */
    public fflib_QueryFactory newQueryFactory(){
        return newQueryFactory( this.m_enforceCRUD, this.m_enforceFLS, true, this.m_includeRelatedFieldSetFields );
    }

    /**
     * Method to configure a QueryFactory with the Selectors object, fields, fieldsets and default order by
     *
     * @param   includeSelectorFields   Boolean whether selected fields should be included
     * @return  fflib_QueryFactory instance configured with provided settings
     */
    public fflib_QueryFactory newQueryFactory( Boolean includeSelectorFields ){
        return newQueryFactory( this.m_enforceCRUD, this.m_enforceFLS, includeSelectorFields, this.m_includeRelatedFieldSetFields );
    }
    public fflib_QueryFactory newQueryFactory( Boolean includeSelectorFields, Boolean includeRelatedFieldSetFields ){
        return newQueryFactory( this.m_enforceCRUD, this.m_enforceFLS, includeSelectorFields, includeRelatedFieldSetFields );
    }

    /**
     * Return a QueryFactory configured with the Selectors object, fields, fieldsets and default order by
     * CRUD and FLS read security will be checked if the corresponding inputs are true (overrides that defined in the selector)
     *
     * @param   assertCRUD              Boolean whether to assert CRUD
     * @param   enforceFLS              Boolean whether to enforce FLS
     * @param   includeSelectorFields   Boolean whether selected fields should be included
     * @return  fflib_QueryFactory instance configured with provided settings
     * @deprecated - Consider using fflib_Database.Context for native platform enforcement of CRUD and FLS
     */
    public fflib_QueryFactory newQueryFactory( Boolean assertCRUD, Boolean enforceFLS, Boolean includeSelectorFields ){
        return this.newQueryFactory( assertCRUD, enforceFLS, includeSelectorFields, this.m_includeRelatedFieldSetFields );
    }


    private fflib_QueryFactory newQueryFactory( Boolean assertCRUD, Boolean enforceFLS, Boolean includeSelectorFields, DataAccess access ){
        fflib_QueryFactory qf = newQueryFactory( assertCRUD, enforceFLS, includeSelectorFields );
        if( access == DataAccess.USER_MODE ){
            qf.setEnforceFLS( fflib_QueryFactory.FLSEnforcement.USER_MODE );
        } else if( access == DataAccess.SYSTEM_MODE ){
            qf.setEnforceFLS( fflib_QueryFactory.FLSEnforcement.SYSTEM_MODE );
        }
        return qf;
    }

    /**
     * Return a QueryFactory configured with the Selectors object, fields, fieldSets, related fieldSets and default order by
     * CRUD and FLS read security will be checked if the corresponding inputs are true (overrides that defined in the selector).
     *
     * @param   assertCRUD                      Boolean whether to assert CRUD
     * @param   enforceFLS                      Boolean whether to enforce FLS
     * @param   includeSelectorFields           Boolean whether selected fields should be included
     * @param   includeRelatedFieldSetFields    Boolean whether related field set fields should be included
     * @return  fflib_QueryFactory instance configured with provided settings
     * @deprecated - Consider using fflib_Database.Context for native platform enforcement of CRUD and FLS
     */
    public fflib_QueryFactory newQueryFactory( Boolean assertCRUD, Boolean enforceFLS, Boolean includeSelectorFields, Boolean includeRelatedFieldSetFields ){
        // Construct QueryFactory around the given SObject
        return configureQueryFactory(
            new fflib_QueryFactory( getSObjectType2() ), assertCRUD, enforceFLS, includeSelectorFields, includeRelatedFieldSetFields
        );
    }

    /**
     * Adds the selectors fields to the given QueryFactory using the given relationship path as a prefix
     */
    public void configureQueryFactoryFields( fflib_QueryFactory queryFactory, String relationshipFieldPath ){
        // Add fields from selector prefixing the relationship path
        for( SObjectField field : getSObjectFieldList() ){
            queryFactory.selectField( relationshipFieldPath + '.' + field.getDescribe().getName() );
        }
        for( String field : getRelatedFieldSet() ){
            queryFactory.selectField( relationshipFieldPath + '.' + field );
        }
        // Automatically select the CurrencyIsoCode for MC orgs (unless the object is a known exception to the rule)
        if( UserInfo.isMultiCurrencyOrganization() && CURRENCY_ISO_CODE_ENABLED ){
            queryFactory.selectField( relationshipFieldPath + '.CurrencyIsoCode' );
        }
    }

    /**
     * Method that adds a subselect QueryFactory based on this selector to the given QueryFactory, returns the child QueryFactory
     *
     * @param   parentQueryFactory  Parent QueryFactory instance
     * @return  The parent QueryFactory instance
     */
    public fflib_QueryFactory addQueryFactorySubselect( fflib_QueryFactory parentQueryFactory ){
        return addQueryFactorySubselect( parentQueryFactory, true );
    }

    /**
     * Method that adds a subselect QueryFactory based on this selector to the given QueryFactory, returns the child QueryFactory
     *
     * @param   parentQueryFactory      Parent QueryFactory instance
     * @param   includeSelectorFields   Boolean whether to include selected fields
     * @return  The parent QueryFactory instance
     */
    public fflib_QueryFactory addQueryFactorySubselect( fflib_QueryFactory parentQueryFactory, Boolean includeSelectorFields ){
        fflib_QueryFactory subSelectQueryFactory = parentQueryFactory.subselectQuery( getSObjectType2() );
        return configureQueryFactory( subSelectQueryFactory, m_enforceCRUD, m_enforceFLS, includeSelectorFields, m_includeRelatedFieldSetFields );
    }

    /**
     * Adds a subselect QueryFactory based on this selector to the given QueryFactor.
     *
     * @param   parentQueryFactory  Parent QueryFactory instance
     * @return  Configured QueryFactory based on provided instance
     * @deprecated - Consider using fflib_Database.Context for native platform enforcement of CRUD and FLS
     */
    public fflib_QueryFactory addQueryFactorySubselectNoAccess( fflib_QueryFactory parentQueryFactory ){
        fflib_QueryFactory subSelectQueryFactory = parentQueryFactory.subselectQuery( getSObjectType2() );
        return configureQueryFactory( subSelectQueryFactory, false, false, true, false );
    }

    /**
     * Method that adds a subselect QueryFactory based on this selector to the given QueryFactor
     *
     * @param   parentQueryFactory      Parent QueryFactory instance
     * @param   relationshipName        Relationship to be set on subselect
     * @return  The parent QueryFactory instance
     */
    public fflib_QueryFactory addQueryFactorySubselect( fflib_QueryFactory parentQueryFactory, String relationshipName ){
        return addQueryFactorySubselect( parentQueryFactory, relationshipName, true );
    }

    /**
	 * Method that adds a subselect QueryFactory based on this selector to the given QueryFactor, but without access checks.
	 *
     * @param   parentQueryFactory      Parent QueryFactory instance
     * @param   relationshipName        Relationship to be set on subselect
     * @param   includeSelectorFields   Boolean whether to include selected fields
     * @return  The parent QueryFactory instance
     * @deprecated - Consider using fflib_Database.Context for native platform enforcement of CRUD and FLS
	 */
    public fflib_QueryFactory addQueryFactorySubselectNoAccessChecks( fflib_QueryFactory parentQueryFactory, String relationshipName, Boolean includeSelectorFields ){
        fflib_QueryFactory subSelectQueryFactory = parentQueryFactory.subselectQuery( relationshipName );
        return configureQueryFactory( subSelectQueryFactory, false, false, includeSelectorFields, false );
    }

    /**
     * Method that adds a subselect QueryFactory based on this selector to the given QueryFactor
     *
     * @param   parentQueryFactory      Parent QueryFactory instance
     * @param   relationshipName        Relationship to be set on subselect
     * @param   includeSelectorFields   Boolean whether to include selected fields
     * @return  The parent QueryFactory instance
     */
    public fflib_QueryFactory addQueryFactorySubselect( fflib_QueryFactory parentQueryFactory, String relationshipName, Boolean includeSelectorFields ){
        fflib_QueryFactory subSelectQueryFactory = parentQueryFactory.subselectQuery( relationshipName );
        return configureQueryFactory( subSelectQueryFactory, m_enforceCRUD, m_enforceFLS, includeSelectorFields, m_includeRelatedFieldSetFields );
    }

    /**
     * Constructs the default SOQL query for this selector, see selectSObjectsById and queryLocatorById
     *
     * @return  String representing the SOQL expression
     */
    protected String buildQuerySObjectById(){
        return newQueryFactory().setCondition( 'Id in :idSet' ).toSOQL();
    }

    /**
     * Configures a QueryFactory instance according to the configuration of this selector.
     */
    @TestVisible
    private fflib_QueryFactory configureQueryFactory( fflib_QueryFactory queryFactory, Boolean assertCRUD, Boolean enforceFLS, Boolean includeSelectorFields, Boolean includeRelatedFieldSetFields ){
        // Note: Boolean controlling CRUD/FLS enforcement to be deprecated. De-facto supported model moving forward will be usage of AccessLevel modes via fflib_Database.Context enums
        if( assertCRUD == true ){
            try{
                // Leverage QueryFactory for CRUD checking
                queryFactory.assertIsAccessible();
            } catch( fflib_SecurityUtils.CrudException e ){
                // Marshal exception into DomainException for backwards compatibility
                throw new fflib_SObjectDomain.DomainException( 'Permission to access an ' + getSObjectType().getDescribe().getName() + ' denied.' );
            }
        }

        // Always set enforceFLS, this is either null skipping SObjectDescribe() based FLS checks, or set to force/ignore FLS validations
        queryFactory.setEnforceFLS( enforceFLS );

        // Configure the QueryFactory with the Selector fields?
        if( includeSelectorFields ){
            // select the Selector fields and FieldSets and set order
            queryFactory.selectFields( getSObjectFieldList() );

            List<Schema.FieldSet> fieldSetList = getSObjectFieldSetList();
            if( this.m_includeFieldSetFields && fieldSetList != null ){
                for( Integer i = 0, j = fieldSetList.size(); i < j; i++ ){
                    queryFactory.selectFieldSet( fieldSetList[ i ] );
                }
            }

            // Automatically select the CurrencyIsoCode for MC orgs (unless the object is a known exception to the rule)
            if( UserInfo.isMultiCurrencyOrganization() && CURRENCY_ISO_CODE_ENABLED ){
                queryFactory.selectField( 'CurrencyIsoCode' );
            }
        }

        // Configure the QueryFactory with the related Selector fields?
        if( includeRelatedFieldSetFields ){
            queryFactory.selectFields( getRelatedFieldSet() );
        }

        // Parse the getOrderBy()
        for( String orderBy : getOrderBy().split( ',' ) ){
            List<String> orderByParts = orderBy.trim().split( ' ' );
            String fieldNamePart = orderByParts[ 0 ];
            String fieldSortOrderPart = orderByParts.size() > 1 ? orderByParts[ 1 ] : null;
            fflib_QueryFactory.SortOrder fieldSortOrder = fflib_QueryFactory.SortOrder.ASCENDING;
            if( fieldSortOrderPart == null ){
                fieldSortOrder = fflib_QueryFactory.SortOrder.ASCENDING;
            } else if( fieldSortOrderPart.equalsIgnoreCase( 'DESC' ) ){
                fieldSortOrder = fflib_QueryFactory.SortOrder.DESCENDING;
            } else if( fieldSortOrderPart.equalsIgnoreCase( 'ASC' ) ){
                fieldSortOrder = fflib_QueryFactory.SortOrder.ASCENDING;
            }
            queryFactory.addOrdering( fieldNamePart, fieldSortOrder, orderBy.containsIgnoreCase( 'NULLS LAST' ) );
        }

        queryFactory.setSortSelectFields( m_sortSelectFields );

        return queryFactory;
    }

    /**
     * Supporting methods for Selector test methods
     * 1) Preparing the Selector test methods; mocking the query proxy to prevent database calls
     * 2) Verification methods whether the expected method was called and the proper binding variables were set
     */
    @TestVisible
    private fflib_ApexMocks mockExecuteQuery(){
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        this.m_queryProxy = ( fflib_Database_IQuery ) mocks.mock( fflib_Database_IQuery.class );
        return mocks;
    }

    /**
     * In addition to mocking fflib_Database_IQuery for query.execute method, ensure to 'program' the proxy to return
     * an empty List<Aggregateresults> to be casted in the fflib_AggregateResult.construct to a List<fflib_AggregateResult>;
     * @return fflib_ApexMocks should be used in case of need for additional stubbing
     */
    @TestVisible
    private fflib_ApexMocks mockExecuteAggregateQuery(){
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        this.m_queryProxy = ( fflib_Database_IQuery ) mocks.mock( fflib_Database_IQuery.class );
        mocks.startStubbing();
        mocks.when( this.m_queryProxy.query( fflib_Match.anyString(), ( AccessLevel ) fflib_Match.anyObject() ) ).thenReturn( new List<AggregateResult>() );
        mocks.when( this.m_queryProxy.query( fflib_Match.anyString(), ( Map<String, Object> ) fflib_Match.anyObject(), ( AccessLevel ) fflib_Match.anyObject() ) ).thenReturn( new List<AggregateResult>() );
        mocks.stopStubbing();
        return mocks;
    }

    /**
     * Method to verify whether executeQuery() was called with a query and no bindVariablesMap
     *
     * @param mocks     fflib_ApexMocks to which the mock was registered
     * @return          Instance of SelectorVerificationResults providing query string and QueryFactory
     */
    @TestVisible
    private SelectorVerificationResults verifyQuery( fflib_ApexMocks mocks ){
        // Verify whether the QueryProxy was called exactly once and capture the constructed query
        fflib_ArgumentCaptor argumentCaptor = new fflib_ArgumentCaptor();
        try{
            ( ( fflib_Database_IQuery ) mocks.verify( this.m_queryProxy, 1 ) ).query( ( String ) argumentCaptor.capture(), ( AccessLevel ) fflib_Match.anyObject() );
        } catch( Exception ex ){
            // Capture the Exception, to provide a more explanatory Assert failure message
            throw new fflib.InvalidImplementationException( 'No executeQuery() was called without bindVariablesMap. If you provided a Map, please use verifyQueryAndBindVariableKeys()' );
        }
        return this.processVerifyQueryResults( argumentCaptor, 1 );
    }

    /**
     * Method to verify whether executeQuery() was called with a query and a valid bindVariablesMap (having matching variables)
     * Validating:
     * - The correct QueryFactory was provided
     * - The query has the same (number of) bind-variables in string as provided in the Map
     *
     * @param mocks     fflib_ApexMocks to which the mock was registered
     * @return          Instance of SelectorVerificationResults providing query string, bind map and QueryFactory
     */
    @TestVisible
    private SelectorVerificationResults verifyQueryAndBindVariableKeys( fflib_ApexMocks mocks ){
        // Verify whether the QueryProxy was called exactly once and capture the constructed query and bindVariablesMap
        fflib_ArgumentCaptor argumentCaptor = new fflib_ArgumentCaptor();
        try{
            ( ( fflib_Database_IQuery ) mocks.verify( this.m_queryProxy, 1 ) ).query( ( String ) argumentCaptor.capture(), ( Map<String, Object> ) argumentCaptor.capture(), ( AccessLevel ) fflib_Match.anyObject() );
        } catch( Exception ex ){
            // Capture the Exception, to provide a more explanatory Assert failure message
            throw new fflib.InvalidImplementationException( 'No executeQuery() was called providing bind-variables, if you didn\'t provide a bindVariablesMap, please use verifyQuery()' );
        }
        return this.processVerifyQueryResults( argumentCaptor, 2 );
    }

    /**
     * Method to verify whether getQueryLocator() was called with a query and no bindVariablesMap
     *
     * @param mocks     fflib_ApexMocks to which the mock was registered
     * @return          Instance of SelectorVerificationResults providing query string and QueryFactory
     */
    @TestVisible
    private SelectorVerificationResults verifyQueryLocator( fflib_ApexMocks mocks ){
        // Verify whether the QueryProxy was called exactly once and capture the constructed query
        fflib_ArgumentCaptor argumentCaptor = new fflib_ArgumentCaptor();
        try{
            ( ( fflib_Database_IQuery ) mocks.verify( this.m_queryProxy, 1 ) ).getQueryLocator( ( String ) argumentCaptor.capture(), ( AccessLevel ) fflib_Match.anyObject() );
        } catch( Exception ex ){
            // Capture the Exception, to provide a more explanatory Assert failure message
            throw new fflib.InvalidImplementationException( 'No getQueryLocator() was called without bindVariablesMap. If you provided a Map, please use verifyQueryLocatorAndBindVariables()' );
        }
        return this.processVerifyQueryResults( argumentCaptor, 1 );
    }

    /**
     * Method to verify whether getQueryLocator() was called with a query and a valid bindVariablesMap (having matching variables)
     * Validating:
     * - The correct QueryFactory was provided
     * - The query has the same (number of) bind-variables in string as provided in the Map
     *
     * @param mocks     fflib_ApexMocks to which the mock was registered
     * @return          Instance of SelectorVerificationResults providing query string, bind map and QueryFactory
     */
    @TestVisible
    private SelectorVerificationResults verifyQueryLocatorAndBindVariableKeys( fflib_ApexMocks mocks ){
        // Verify whether the QueryProxy was called exactly once and capture the constructed query and bindVariablesMap
        fflib_ArgumentCaptor argumentCaptor = new fflib_ArgumentCaptor();
        try{
            ( ( fflib_Database_IQuery ) mocks.verify( this.m_queryProxy, 1 ) ).getQueryLocator( ( String ) argumentCaptor.capture(), ( Map<String, Object> ) argumentCaptor.capture(), ( AccessLevel ) fflib_Match.anyObject() );
        } catch( Exception ex ){
            // Capture the Exception, to provide a more explanatory Assert failure message
            throw new fflib.InvalidImplementationException( 'No getQueryLocator() was called providing bind-variables, if you didn\'t provide a bindVariablesMap, please use verifyQueryLocator()' );
        }
        return this.processVerifyQueryResults( argumentCaptor, 2 );
    }

    /**
     * Centralised method to allow re-use in argumentCaptor validation
     * @param argumentCaptor        The ArgumentCaptor of the queryProxy.query() methods
     * @param numExpectedArguments  Whether we expect (1) only a query, or also (2) a bindVariablesMap
     * @return Instance of SelectorVerificationResults providing query string, queryfactory and opt. bindVariablesMap
     */
    private SelectorVerificationResults processVerifyQueryResults( fflib_ArgumentCaptor argumentCaptor, Integer numExpectedArguments ){
        List<Object> capturedArgs = argumentCaptor.getAllValues();
        System.Assert.areEqual( numExpectedArguments, capturedArgs.size(), 'Expected a different number of captured arguments for the QueryProxy.query() method' );

        // If the right number of variables were captured, construct response wrapper which also performs some basic validations
        return new SelectorVerificationResults( ( String ) capturedArgs[ 0 ], ( ( numExpectedArguments == 2 ) ? ( Map<String, Object> ) capturedArgs[ 1 ] : null ) );
    }

    @TestVisible
    private class SelectorVerificationResults{
        @TestVisible private String query;
        @TestVisible private Map<String, Object> map_bindVariables;
        @TestVisible private fflib_QueryFactory qf;

        @TestVisible
        private SelectorVerificationResults( String q, Map<String, Object> bindVariablesMap ){
            this.query = q;
            this.map_bindVariables = bindVariablesMap; // could be null in case not provided to executeQuery()
            this.qf = fflib_QueryFactory.lastQueryFactory;

            System.Assert.areEqual(
                qf.toSOQL(),
                this.query,
                'Expected the latest queryfactory SOQL result to be passed to DML retrieval'
            );

            // If a bindVariablesMap was provided, validate all bindVariables in query (:abc) also exist in map (keys)
            if( bindVariablesMap != null ){
                // Match bind-variables in query string
                Pattern p = Pattern.compile( '\\:[ ]?([\\w]+)' );
                Matcher matcher = p.matcher( q );
                Set<String> uniqueVariablesInQuery = new Set<String>();
                // Loop over all bind-variables in query string and check if Map has a key of the same name
                while( matcher.find() ){
                    String matchedBindVariable = matcher.group( 1 );
                    uniqueVariablesInQuery.add( matchedBindVariable );
                    System.Assert.isTrue(
                        this.map_bindVariables.containsKey( matchedBindVariable ),
                        'Expected bindvariable "' + matchedBindVariable + '" to be specified in bindVariablesMap ' + JSON.serializePretty( this.map_bindVariables.keySet() )
                    );
                }

                // Lastly, validate whether the map has the same number as variables as uniquely specified in the query-condition
                // Note, this is to prevent lazy-coding/code-smells where more variables are passed into the map than needed
                System.Assert.isTrue(
                    ( this.map_bindVariables.size() == uniqueVariablesInQuery.size() ),
                    'Expected same number of bind-variables in query as in provided Map \n' + this.query + '\n' + JSON.serializePretty( this.map_bindVariables )
                );
            }
        }

        @TestVisible
        private SelectorVerificationResults validateTable( SObjectType sObjType ){
            System.Assert.areEqual(
                sObjType,
                this.qf.table,
                'Expected query to be FROM ' + sObjType + '\n' + this.query
            );
            return this;
        }

        @TestVisible
        private SelectorVerificationResults validateFields( Set<SObjectField> fields ){
            Set<String> lowerCaseFields = new Set<String>();
            for( SObjectField field : fields ){
                lowerCaseFields.add( String.valueOf( field ).toLowerCase() );
            }
            this.validateLowerCaseFields( lowerCaseFields );
            return this;
        }
        @TestVisible
        private SelectorVerificationResults validateFields( Set<String> fields ){
            Set<String> lowerCaseFields = new Set<String>();
            for( String field : fields ){
                lowerCaseFields.add( field.toLowerCase() );
            }
            this.validateLowerCaseFields( lowerCaseFields );
            return this;
        }
        private void validateLowerCaseFields( Set<String> lowerCaseFields ){
            System.Assert.isTrue(
                this.qf.getSelectedFields().containsAll( lowerCaseFields ),
                'Expected query did not include all expected fields (' + JSON.serializePretty( lowerCaseFields ) + ')' +
                    '\nFields included in query: ' + JSON.serializePretty( this.qf.getSelectedFields() )
            );
        }

        @TestVisible
        private SelectorVerificationResults validateCondition( String expectedCondition ){
            return this.validateCondition( expectedCondition, false );
        }

        @TestVisible
        private SelectorVerificationResults validateCondition( String expectedCondition, Boolean partialMatch ){
            expectedCondition = expectedCondition?.toLowerCase();
            String actualCondition = this.qf.getCondition()?.toLowerCase();
            if( partialMatch ){
                System.Assert.isTrue(
                    actualCondition.contains( expectedCondition ),
                    'Expected query to contain condition (' + expectedCondition + ')' +
                        '\nActual condition: ' + actualCondition
                );
            } else{
                System.Assert.areEqual(
                    expectedCondition,
                    actualCondition,
                    'Expected different condition'
                );
            }
            return this;
        }

        @TestVisible
        private SelectorVerificationResults validateBindVariableValue( String bindkey, Object expectedObj ){
            System.Assert.areEqual(
                expectedObj,
                this.map_bindVariables?.get( bindkey ),
                'Expected different object to be set as bind variable for key "' + bindKey + '"'
            );
            return this;
        }
    }

    /**
     * Relay-methods to the query proxy. These methods have the sole responsibility to pass down the query expression and binding map to the query proxy implementation.
     * In addition, it allows one to inject stubs for mocking actual database operations and verify the contents of the input parameters above
     */

    // Database.query() specifications
    public List<SObject> executeQuery( String query ){
        return ( List<SObject> ) m_queryProxy.query( query, fflib_Database.getAccessLevel( getContext() ) );
    }

    public List<SObject> executeQuery( fflib_QueryFactory qf ){
        return this.executeQuery( qf.toSOQL() );
    }

    public List<SObject> executeQuery( String query, Map<String, Object> bindVariablesMap ){
        return ( List<SObject> ) m_queryProxy.query( query, bindVariablesMap, fflib_Database.getAccessLevel( getContext() ) );
    }

    public List<SObject> executeQuery( fflib_QueryFactory qf, Map<String, Object> bindVariablesMap ){
        return this.executeQuery( qf.toSOQL(), bindVariablesMap );
    }

    // Database.query() for Grouped By Results returning AggregateResults
    public List<fflib_AggregateResult> executeAggregateQuery( String query ){
        return fflib_AggregateResult.construct( ( List<AggregateResult> ) m_queryProxy.query( query, fflib_Database.getAccessLevel( getContext() ) ) );
    }

    public List<fflib_AggregateResult> executeAggregateQuery( fflib_QueryFactory qf ){
        return this.executeAggregateQuery( qf.toSOQL() );
    }

    public List<fflib_AggregateResult> executeAggregateQuery( String query, Map<String, Object> bindVariablesMap ){
        return fflib_AggregateResult.construct( ( List<AggregateResult> ) m_queryProxy.query( query, bindVariablesMap, fflib_Database.getAccessLevel( getContext() ) ) );
    }

    public List<fflib_AggregateResult> executeAggregateQuery( fflib_QueryFactory qf, Map<String, Object> bindVariablesMap ){
        return this.executeAggregateQuery( qf.toSOQL(), bindVariablesMap );
    }

    // Database.getQueryLocator() specifications
    public Database.QueryLocator getQueryLocator( String query ){
        return m_queryProxy.getQueryLocator( query, fflib_Database.getAccessLevel( getContext() ) );
    }

    public Database.QueryLocator getQueryLocator( fflib_QueryFactory qf ){
        return this.getQueryLocator( qf.toSOQL() );
    }

    public Database.QueryLocator getQueryLocator( String query, Map<String, Object> bindVariablesMap ){
        return m_queryProxy.getQueryLocator( query, bindVariablesMap, fflib_Database.getAccessLevel( getContext() ) );
    }

    public Database.QueryLocator getQueryLocator( fflib_QueryFactory qf, Map<String, Object> bindVariablesMap ){
        return this.getQueryLocator( qf.toSOQL(), bindVariablesMap );
    }

    public class InvalidContextAssignmentException extends Exception{}
}