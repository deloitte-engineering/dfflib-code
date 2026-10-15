/**
 * Copyright (c), Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
/**
 * Class for creating Mock SObjects used for Mocking
 *
 * SObjects are either created or modified by using default data mapping classes which can be found within
 * UT_TestFactoryData. For all sObjects which you need to manage the default record values create a new inner class
 * and define the defaults there.
 *
 * Example usage
 * =============
 *
 * To use the Factory, first you must instantiate it:
 *
 * 		UT_SObjectFactory factory = new UT_SObjectFactory();
 *
 * Below is an example creating an account and adding three child opportunities:
 *
 *         Account record = ( Account ) factory.create( Account.SObjectType )
 *          .addChildren( 'Opportunities', new List<UT_TestFactory.SObjectMock>{
 *                 factory.create( new Opportunity() ),
 *                 factory.create( new Opportunity() ),
 *                 factory.create( new Opportunity() )
 *          } )
 *          .save();
 *
 * If you only need to create one child record, then you can use the following shorthand version:
 *
 *         Account record = ( Account ) factory.create( Account.SObjectType )
 *             .addChild('Opportunities', factory.create( new Opportunity() ) )
 *             .save();
 *
 * If you want to create an account, but mock it, then use the following code:
 *
 *         Account record = ( Account ) factory.create( Account.SObjectType ).mock();
 *
 * You can also create a child record and link it to one more parent records:
 *
 *         Opportunity record = ( Opportunity ) factory.create( Opportunity.SObjectType )
 *             .addParent( Opportunity.AccountId,
 *                 factory.create( new Account() )
 *             )
 *             .save();
 *
 * When mocking records you may want to populate the mocked records with fake ID's. Use the createWithId methods
 * instead. Note, if you intend to save the records to the database then this will fail, use the create method instead.
 *
 * If you need to save records to the database in a particular order, then you can define your own unit of work
 * instance and supply this to the save method:
 *
 *         UT_SObjectFactory factory = new UT_SObjectFactory();
 *         fflib_ISObjectUnitOfWork uow = fflib.unitOfWork.newInstance(
 *            new List<Schema.SObjectType>{
 *                  Account.sObjectType,
 *                Opportunity.sObjectType
 *        });
 *
 *         Account record = ( Account ) factory.create( Account.SObjectType )
 *          .addChild('Opportunities', factory.create( new Opportunity() ) )
 *          .save(uow);
 *
 * Lastly, if you have a specific unit testing scenario you can supply specific values within an sObject instance
 * and these will not be overwritten by the defaults.
 *
 *         Account record = ( Account ) factory.create( new Account( Rating = 'Cold' ) ).save();
 *
 */
@IsTest
public with sharing class UT_SObjectFactory{

    // Main source of default values which can be used across any builder
    private static String MOCK_DATA_CLASS = 'UT_TestFactoryData';

    // The suffix of the data builder classes expected. E.g. AccountDefaults
    private static String MOCK_DATE_CLASS_SUFFIX = 'Defaults';

    // Map which contains sObjects which should only be created once, which match a given key
    private static Map<SObjectType, Map<String, SObject>> sObjectCacheMap = new Map<SObjectType, Map<String, SObject>>();

    // Map which indicates for sObjects which should be created once whether they have been registerd within a unit of
    private static Map<SObjectType, Map<String, Boolean>> sObjectCacheCreatedMap = new Map<SObjectType, Map<String, Boolean>>();

    // Singleton instance for all SObjectMock instances to reference
    private static UT_SObjectFactory sObjectBuilder = new UT_SObjectFactory();

    // Instances of the accessed data default classes will be cached within this map, this is to save time instantiating
    // them over and over again
    private static Map<String, ISObjectDefaults> defaultsCache = new Map<String, ISObjectDefaults>();

    // When mocking ID's and or during serialization of mocked objects there is a chance that the nodes can be cyclic
    // and could lead to CPU limits being hit unnecessarily. The stack depth tracks how much the mocking has recursively
    // descended to allow it to abort and allow the system to stay within limits.
    private static Integer stackDepth = -1;

    // The maximum stack depth allowed before aborting
    private static Integer MAXIMUM_STACK_DEPTH = 5;

    // Tracks which sObject types have reloaded their cache from the database - this is for when switching from
    // test setup phase to unit test phase we need to ensure we do not create duplicate records
    private static Set<SObjectType> loadedCacheTypes = new Set<SObjectType>();

    // TODO: add method headers to this class.

    private static void loadCache( SObjectType sType ){
        if( UT_TestFactoryData.keyableMap.containsKey( sType ) && !loadedCacheTypes.contains( sType ) ){
            Keyable k = UT_TestFactoryData.keyableMap.get( sType );
            loadedCacheTypes.add( sType );
            List<SObject> records = k.reload( sType );

            for( Integer i = 0, j = records.size(); i < j; i++ ){
                SObject record = records[ i ];
                String key = UT_TestFactoryData.keyableMap.get( sType ).generateKey( record );

                if( key != null ){
                    // Build a map for this sObject type if we've not encountered it before
                    if( !sObjectCacheMap.containsKey( sType ) ){
                        sObjectCacheMap.put( sType, new Map<String, SObject> () );
                        sObjectCacheCreatedMap.put( sType, new Map<String, Boolean> () );
                    }

                    // Place the record into cache for this sObject type
                    if( !sObjectCacheMap.get( sType ).containsKey( key ) ){
                        sObjectCacheMap.get( sType ).put( key, record );
                        sObjectCacheCreatedMap.get( sType ).put( key, true );
                    }
                }
            }
        }
    }


    /**
     * Classes should implement this interface for when they generate keys for uniqueness to avoid creating duplicate
     * records between the different builders without the requirement to link builders together.
     */
    public interface Keyable{
        String generateKey( SObject record );
        List<SObject> reload( SObjectType sType );
    }

    /**
     * When setting values to an sObject you can add a value which is an instance of a class which implements
     * this class interface. When populating sObjects there will be a check to determine if the value is of this
     * type and if so, will pass the value into the replacer to evaluate and replace variables within the value.
     *
     * E.g. addField('Name', new CounterReplacer('Test Account {0}'));
     */
    public interface ValueReplacer{
        String evaluate( SObjectType sObjectType, String fieldName );
    }

    /**
     * Interface which should be implemented on classes which provide default field values for sObject records.
     */
    public interface ISObjectDefaults{
        Map<String, Object> getFieldValues();
    }

    /**
     * Base sObject default field values class. This class should be extended by all classes which provide default
     * field values and the intention of this class to allow easy upgrading of the classes in future with minimal
     * change.
     */
    public abstract class SObjectDefaults implements ISObjectDefaults{
        protected abstract Map<String, Object> getFieldValues();
    }

    /**
     * Constructor
     */
    public UT_SObjectFactory(){}

    /**
     * Constructor used to allow changing where the location of the data mapping classes are located. This is useful
     * when there are several data mapping classes and for organisational purposes they are separated into smaller
     * classes.
     *
     * @param mockDataClass        The class name which contains the data mapping classes.
     */
    public UT_SObjectFactory( String mockDataClass ){
        MOCK_DATA_CLASS = mockDataClass;
    }

    /**
     * Constructor used to allow changing where the location of the data mapping classes are located and also the
     * name of the class suffix (e.g. "Defaults") to something more specific.
     *
     * @param mockDataClass        The class name which contains the data mapping classes.
     */
    public UT_SObjectFactory( String mockDataClass, String classSuffix ){
        MOCK_DATA_CLASS = mockDataClass;
        MOCK_DATE_CLASS_SUFFIX = classSuffix;
    }

    /**
     * Creates a SObjectMock instance for a given sObjectType. This will be the parent record whereby you can add
     * children to. The defaults for the class will be used for the mapping.
     *
     * @param sObjectType    The sObjectType to use to create the SObjectMock instance for.
     *
     * @return    An instance of SObjectMock which is configured for the given sObjectType.
     */
    public SObjectMock create( Schema.SObjectType sObjectType ){
        return create( sObjectType, MOCK_DATA_CLASS );
    }

    /**
     * Creates a SObjectMock instance for a given sObjectType. This will be the parent record whereby you can add
     * children to. The given defaults class will be used for the mapping.
     *
     * @param sObjectType    The sObjectType to use to create the SObjectMock instance for.
     * @param mockDataClass The data mapping class to use to find the mapping class.
     *
     * @return    An instance of SObjectMock which is configured for the given sObjectType.
     */
    public SObjectMock create( Schema.SObjectType sObjectType, String mockDataClass ){
        SObjectMock instance = new SObjectMock( sObjectType )
            .setDefaults( getDefaults( sObjectType, mockDataClass ) );
        return instance;
    }

    /**
     * Creates an instance of SObjectMock configured using the sObject record provided. This will extract the
     * sObjectType from the record and will populate the unpopulated fields with the defaults from the default class
     * for the sObjectType.
     *
     * @param sObj The sObject record to use to to configure the SObjectMock instance.
     *
     * @return    An instance of SObjectMock which is configured using the given sObject record.
     */
    public SObjectMock create( SObject sObj ){
        return create( sObj, true );
    }

    public SObjectMock create( SObject sObj, Boolean loadDefaults ){
        return create( sObj, MOCK_DATA_CLASS );
    }

    /**
     * Creates an instance of SObjectMock configured using the sObject record provided. This will extract the
     * sObjectType from the record and will populate the unpopulated fields with the defaults from the given default
     * class for the sObjectType.
     *
     * @param sObj The sObject record to use to to configure the SObjectMock instance.
     * @param mockDataClass The data mapping class to use to find the mapping class.
     *
     * @return    An instance of SObjectMock which is configured using the given sObject record.
     */
    public SObjectMock create( SObject sObj, String mockDataClass ){
        SObjectMock instance = new SObjectMock( sObj )
            .setDefaults( getDefaults( sObj.getsObjectType(), mockDataClass ) );

        return instance;
    }

    /**
     * Creates an instance of SObjectMock configured using the sObject record provided, but in addition it will populate
     * the record with a ID. It will also populate the missing fields using the defaults mapping class for the sObjectType.
     *
     * @param sObj The sObject record to use to to configure the SObjectMock instance.
     * @return    An instance of SObjectMock which is configured using the given sObject record.
     */
    public SObjectMock createWithId( SObject sObj ){
        return create( sObj ).setId();
    }

    /**
     * Creates a SObjectMock instance for a given sObjectType. This will be the parent record whereby you can add
     * children to. The given defaults class will be used for the mapping. In addition it will populate the sObject
     * record with an ID.
     *
     * @param sObjectType    The sObjectType to use to create the SObjectMock instance for.
     * @return    An instance of SObjectMock which is configured using the given sObjectType.
     */
    public SObjectMock createWithId( Schema.SObjectType sObjectType ){
        return create( sObjectType ).setId();
    }

    /**
     * get Defaults ( FieldValues, RelationShips, Dependencies ) for a SObject
     *
     * @param    sObjectType   SObject Type
     * @return Object class with defaults
     */
    private ISObjectDefaults getDefaults( Schema.SObjectType sObjectType ){
        return getDefaults( sObjectType, MOCK_DATA_CLASS );
    }

    /**
     * get Defaults ( FieldValues, RelationShips, Dependencies ) for a SObject
     *
     * @param    sObjectType   SObject Type
     * @param    className     Classname which contains the Mock Data for the SObject
     * @return Object class with defaults
     */
    private ISObjectDefaults getDefaults( Schema.SObjectType sObjectType, String mockDataClass ){
        String defaultClassName = mockDataClass;

        // Construct default values class. __ is not supported
        if( !mockDataClass.contains( '.' ) ){
            String objectName = String.valueOf( sObjectType );
            defaultClassName += '.' + objectName.replaceAll( '__c|__', '' ) + MOCK_DATE_CLASS_SUFFIX;
        }

        if( !defaultsCache.containsKey( defaultClassName ) ){
            // Create an instance of the defaults class so we can get the Map of field defaults
            Type defaultsType = Type.forName( defaultClassName );

            // When class is invalid throw an Exception
            if( defaultsType == null ){
                defaultsType = DummyDefaults.class;
            }

            // Put the item in the cache
            defaultsCache.put( defaultClassName, ( ISObjectDefaults ) defaultsType.newInstance() );
        }

        return defaultsCache.get( defaultClassName );
    }

    /**
     * Dummy defaults mapping class when a mapping class doesn't exist for an sObjectType.
     */
    public class DummyDefaults implements ISObjectDefaults{
        public Map<String, Object> getFieldValues(){
            return new Map<String, Object>();
        }

        public Map<String, Schema.SObjectType> getFieldRelationships(){
            return new Map<String, Schema.SObjectType>();
        }
    }

    /**
     * An SObjectMock instance is resposible for managing all of the field value, child and parent nodes for a source
     * sObject record which is being either mocked or saved.
     */
    public class SObjectMock{
        private Type sType;
        private SObject sObj;
        private Id sObjectId;
        private ISObjectDefaults defaults;
        private List<INode> nodes = new List<INode>();
        private Set<String> removedFields = new Set<String>();
        private SObject savingRecord;
        private Boolean isBuilt = false;
        private Boolean skipCache = false;

        /**
         * Constructor is used to allow setting of the sObjectType which the SObjectMock instance is responsible
         * for managing.
         *
         * @param sObjectType The sObjectType the SObjectMock will create a new record for.
         */
        public SObjectMock( Schema.SObjectType sObjectType ){
            this.sObj = sObjectType.newSObject();
        }

        /**
         * Constructor is used to allow setting of the sObject record which the SObjectMock instance is responsible
         * for managing.
         *
         * @param    sObj        sObject
         */
        public SObjectMock( SObject sObj ){
            dfflib_Utils.verifyNotNull( sObj, 'sObj' );
            this.sObj = sObj;
            createWithSObjectTemplate( sObj );
        }

        /**
         * @return    The fake record ID or the actual record ID of the sObject within this instance.
         */
        public Id getId(){
            return this.sObjectId;
        }

        /**
         * Populates the sObject record with a fake record ID.
         */
        public SObjectMock setId(){
            this.setId( sObj.getSObjectType() );
            return this;
        }

        /**
         * Allows setting the sObject record with a fake ID.
         */
        public SObjectMock setId( Schema.SObjectType sObjectType ){
            return setId( fflib_IDGenerator.generate( sObjectType ) );
        }

        public SObjectMock setId( Id recordId ){
            this.sObjectId = recordId;
            this.sObj.put( 'Id', this.sObjectId ); // assign field also direct to SObject
            this.addField( 'Id', this.sObjectId );
            return this;
        }

        /**
         * Method to add a Field, overwrites the field if it's already exists
         *
         * @param    fieldName        The API of the field on the sObject to populate with the given value.
         * @param    value            The value which will be assigned to the field on the sObject.
         */
        public SObjectMock addField( String fieldName, Object value ){
            Boolean fieldFound = false;
            value = evaluateValue( fieldName, value );

            for( Integer i = 0, j = this.nodes.size(); i < j; i++ ){
                if( this.nodes[ i ].serialize( true ).containsKey( fieldName ) ){
                    this.nodes[ i ] = new FieldValueNode( fieldName, value );
                    fieldFound = true;
                }
            }

            if( !fieldFound ){
                this.nodes.add( new FieldValueNode( fieldName, value ) );
            }

            if( !removedFields.isEmpty() ){
                if( removedFields.contains( fieldName.toLowerCase() ) ){
                    removedFields.remove( fieldName.toLowerCase() );
                }
            }

            return this;
        }

        /**
         * Method to add a Field
         *
         * @param    field            Field token on the sObject to populate with the given value.
         * @param    value            The value which will be assigned to the field on the sObject.
         */
        public SObjectMock addField( Schema.SObjectField field, Object value ){
            return this.addField( UT_SObjectFactoryUtils.getFieldName( field ), value );
        }

        /**
         * Removes a field from the record.
         */
        public SObjectMock removeField( String field ){
            for( Integer i = 0, j = nodes.size(); i < j; i++ ){
                if( nodes[ i ] instanceof FieldValueNode ){
                    FieldValueNode node = ( FieldValueNode ) nodes[ i ];

                    if( node.getFieldName().equalsIgnoreCase( field ) ){
                        nodes.remove( i );
                        break;
                    }
                }
            }

            removedFields.add( field.toLowerCase() );
            return this;
        }

        public SObjectMock removeField( Schema.SObjectField field ){
            return removeField( UT_SObjectFactoryUtils.getFieldName( field ) );
        }

        /**
         * Method to add a single child record underneath the current parent sObject record.
         *
         * @param    relationshipName    The relationship name between the child records and the parent record.
         * @param    child                SObjectMock instance which will be linked to this instance.
         */
        public SObjectMock addChild( String relationshipName, SObjectMock child ){
            return addChildren( relationshipName, new List<SObjectMock>{
                child
            } );
        }

        /**
         * Method to add multiple child records underneath the current parent sObject record.
         *
         * @param    relationshipName    The relationship name between the child records and the parent record.
         * @param    children            List of SObjectMock instances which will be linked to this instance.
         */
        public SObjectMock addChildren( String relationshipName, List<SObjectMock> children ){
            dfflib_Utils.verifyNotBlank( relationshipName, 'relationshipName' );
            dfflib_Utils.verifyNotNull( children, 'children' );

            // if withId(), add set the correct parentId;
            if( getId() != null && children != null ){
                String parentRelationField = UT_SObjectFactoryUtils.getChildRelationshipFieldName( sObj.getSObjectType(), relationshipName );

                for( Integer i = 0, j = children.size(); i < j; i++ ){
                    children[ i ].addField( parentRelationField, getId() );
                }
            }

            // Child SObjectMock instances for the given sObject type may have been added already, we need to add the
            // children to the existing child node
            Boolean found = false;
            SObjectField relationshipField = UT_SObjectFactoryUtils.getChildRelationshipFieldToken( sObj.getSObjectType(), relationshipName );

            for( Integer i = 0, j = nodes.size(); i < j; i++ ){
                INode node = nodes[ i ];

                if( node instanceof ChildNode ){
                    ChildNode cn = ( ChildNode ) node;
                    if( cn.getRelationshipField() == relationshipField ){
                        cn.addChildren( children );
                        found = true;
                        break;
                    }
                }
            }

            // Only add a new child node if we have not added this sObject type before
            if( !found ){
                this.nodes.add( new ChildNode (
                    relationshipName,
                    children,
                    relationshipField
                ) );
            }

            return this;
        }

        private Boolean hasMockedIds = false;

        /**
         * Used to set fake ID's within all of the SObjectMock instances and will populate all of the relationship
         * fields upwards and downwards in the relationships. This is primarily used by the test factory builders
         * when the builders do not directly expose the SObjectMocks to allow setting the fake ID's.
         */
        public void mockIds(){
            if( hasMockedIds ){
                return;
            }
            hasMockedIds = true;

            // Only set the ID of the sObject if one has not yet been set,
            // otherwise we could be overwriting the ID being set in a unit test
            if( sObjectId == null ){
                setId();
            }

            stackDepth++;

            if( stackDepth < MAXIMUM_STACK_DEPTH ){
                for( Integer i = 0, j = nodes.size(); i < j; i++ ){
                    INode node = nodes[ i ];

                    if( node instanceof ChildNode ){
                        // A child node, such as opportunity line item, decend and set all ID's and if the children have
                        // children, then decend into those as well
                        ChildNode cn = ( ChildNode ) node;
                        SObjectField field = cn.getRelationshipField();
                        List<SObjectMock> children = cn.getChildren();

                        for( Integer k = 0, l = children.size(); k < l; k++ ){
                            children[ k ].addField( field, getId() );
                            children[ k ].mockIds();
                        }
                    } else if( node instanceof ParentNode ){
                        // Parent relationship defined, ascend upwards and potentially down through its child nodes as well
                        ParentNode pn = ( ParentNode ) node;
                        pn.getChildren()[ 0 ].mockIds();
                    }
                }
            }

            stackDepth--;
        }

        /**
         * Method to add Parent Node
         *
         * @param	relationshipName
         * @param	parent
         */
        public SObjectMock addParent( Schema.SObjectField relationshipField, SObjectMock parent ){
            this.nodes.add( new ParentNode( relationshipField, parent, false, false ) );
            return this;
        }

        /**
         * Method to add Parent Node
         *
         * @param    relationshipName
         * @param    parent
         */
        public SObjectMock addParent( Schema.SObjectField relationshipField, SObjectMock parent, Boolean priorityNew, Boolean isAfterInsert ){
            this.nodes.add( new ParentNode( relationshipField, parent, priorityNew, isAfterInsert ) );
            return this;
        }

        /**
         * Method to set defaults for the SObject type ( e.g. DefaultFields )
         * see SObjectDefaults class for possible method options
         *
         * @param   defaults
         */
        public SObjectMock setDefaults( ISObjectDefaults defaults ){
            dfflib_Utils.verifyNotNull( defaults, 'defaults' );
            this.defaults = defaults;
            return this;
        }

        /**
         * Method for creating a SObject from a SObject Template
         *
         * @param   sObj         SObject used as template.
         */
        private void createWithSObjectTemplate( SObject sObj ){
            if( !sObj.getPopulatedFieldsAsMap().isEmpty() ){
                List<String> fieldNames = UT_SObjectFactoryUtils.getFieldNameList( sObj.getSObjectType() );

                for( Integer i = 0, j = fieldNames.size(); i < j; i++ ){
                    Object value = sObj.get( fieldNames[ i ] );

                    if( value != null ){
                        this.addField( fieldNames[ i ], value );
                    }
                }
            }
        }

        /**
         * Method for populating default field values
         * the default values are defined in the <SObjectName>Defaults class
         *
         * @param   fields         Map with field values
         * @param   isMocking    Allows non-writeable fields to be populated, useful for mocking
         *
         * @return Map<String, Object> with field values
         */
        private Map<String, Object> populateDefaultFieldValues( Map<String, Object> fieldValues, Boolean isMocking ){
            // if the defaults are not defined then return current fieldValues
            if( this.defaults == null && this.defaults.getFieldValues().isEmpty() ){
                return fieldValues;
            }

            Map<String, Object> defaultFieldValues = this.defaults.getFieldValues();

            // populate missing object fieldValues which are defined in ObjectDefault
            for( String fd : defaultFieldValues.keySet() ){
                if( ( fieldValues.containsKey( fd ) && fieldValues.get( fd ) == null )
                    || !fieldValues.containsKey( fd ) ){
                    Boolean write = true;

                    // Determine if we are not mocking whether we can write to the field
                    if( !isMocking ){
                        SObjectField sObjField = fflib_SObjectDescribe.getDescribe( sObj.getSObjectType() ).getField( fd );
                        Schema.DescribeFieldResult sObjFieldDesc = sObjField.getDescribe();

                        // Can we create values in the field
                        if( sObjFieldDesc.isAutoNumber() || sObjFieldDesc.isCalculated() ){
                            write = false;
                        }
                    }

                    if( write && !removedFields.contains( fd.toLowerCase() ) ){
                        fieldValues.put( fd, evaluateValue( fd, defaultFieldValues.get( fd ) ) );
                    }
                }
            }

            return fieldValues;
        }

        /**
         * This will determine if the value being set on the SObject is of the type ValueReplacer
         * and if so, will replace any merge fields defined within the value with custom dynamic values
         * such as a counter to ensure uniqueness.
         *
         * @param fieldName        The API name of the field being set with the value
         * @param value            The value being set against the field which could be a ValueReplacer.
         *
         * @return    The final value which should be set on the sObject for the field specified.
         */
        private Object evaluateValue( String fieldName, Object value ){
            if( value instanceof ValueReplacer ){
                return ( ( ValueReplacer ) value ).evaluate( sObj.getSObjectType(), fieldName );
            } else{
                return value;
            }
        }

        /**
         * Serialize all the nodes to a field Map
         *
         * @param   isMocking    Allows non-writeable fields to be populated, useful for mocking
         *
         * @return  map with fields (<String, Object>)
         */
        public Map<String, Object> serialize( Boolean isMocking ){
            Map<String, Object> fields = new Map<String, Object>();
            stackDepth++;

            // To prevent a cyclic condition whereby SObjectMocks can be pointing to a node higher up in the same
            // tree, we need to add in a stack depth check which will forcefully abort the serialization process.
            if( stackDepth < MAXIMUM_STACK_DEPTH ){
                for( Integer i = 0, j = nodes.size(); i < j; i++ ){
                    INode node = nodes[ i ];

                    if( !isMocking ){
                        // When saving we only need to serialize the field value nodes on the current sObject
                        if( node instanceof FieldValueNode ){
                            fields.putall( node.serialize( isMocking ) );
                        }
                    } else{
                        // When mocking we need to serialize all nodes
                        if( !( node instanceof ParentNode ) ){
                            fields.putAll( node.serialize( isMocking ) );
                        } else{
                            DescribeFieldResult fd = node.getRelationshipField().getDescribe();
                            SObjectMock child = node.getChildren()[ 0 ];
                            fields.put( fd.getRelationshipName(), child.serialize( isMocking ) );
                            fields.put( fd.getName(), child.getId() );
                        }
                    }
                }
            }

            fields = populateDefaultFieldValues( fields, isMocking );

            // Reduce stack depth to allow sibling nodes to decend further down the stack
            stackDepth--;

            return fields;
        }

        /**
         * This will generate a new instance of the sObject with all of the fields, child and parent relationships
         * set. If mocking then this method will populate non-writeable fields with the values provided from the
         * defaults or from the added values to the SObjectMock instance.
         *
         * @param   isMocking    Allows non-writeable fields to be populated, useful for mocking
         *
         * @return  SObject instance populated with the field values, child and parent relationships set ready for
         *             saving to the database or ready for use for mocking purposes.
         */
        private SObject getSObject( Boolean isMocking ){
            if( this.sType == null ){
                this.sType = Type.forName( String.valueOf( sObj.getSObjectType() ) );
            }

            // Serialize the sObject and its parent and child relationships
            Map<String, Object> output = serialize( isMocking );

            // Unserializable fields will be re-added after converting the sObjects into JSON and casting back
            Map<String, Object> unserializeableFields = new Map<String, Object>();

            if( output != null ){
                fflib_SObjectDescribe sObjectDescribe = fflib_SObjectDescribe.getDescribe( sObj.getSObjectType() );

                // Loop over fields from the output, remove appropriate fields when mocking
                for( String field : output.keySet() ){
                    Schema.SObjectField token = sObjectDescribe.getField( field );

                    if( token != null ){
                        // Base 64 fields cannot be serialized and will result in an error, a workaround to this is to
                        // remove them from the serialization and re-add them afterwards
                        if( token.getDescribe().getType() == Schema.DisplayType.BASE64 ){
                            unserializeableFields.put( field, output.get( field ) );
                            output.remove( field );
                        }

                        // Polymorphic relation fields (Owner, Who, etc) will result in serialization error
                        // Remove the polymorphic fields from serialization in case of mocking
                        if( isMocking && isPolymorphicParentField( field, sObjectDescribe ) ){
                            output.remove( field );
                        }

                        // Is there a request to remove a field from the output, e.g. PersonAccounts you may want to
                        // remove the Name field if it is defined within the defaults
                        if( !isMocking && !token.getDescribe().isCreateable() ){
                            System.debug( LoggingLevel.WARN, 'fflib - Warning! Field is not createable and is being removed from the SObject: ' + field );
                            output.remove( field );
                        }
                    }
                }
            }

            // Convert the sObjects to JSON and cast deserialize it back to allow writing to non-writeable fields
            SObject record;

            try{
                record = ( SObject ) JSON.deserialize( JSON.serialize( output ), this.sType );
            } catch( Exception ex ){
                System.debug( LoggingLevel.ERROR, 'fflib - Deserialization exceptions usually occur when not all of the required fields are populated for an SObject' );
                System.debug( LoggingLevel.ERROR, 'fflib - Failed to deserialize: ' + JSON.serialize( output ) );
                throw ex;
            }

            // Add back in all of the unserializable fields
            for( String field : unserializeableFields.keySet() ){
                record.put( field, unserializeableFields.get( field ) );
            }

            // Some types of sObjects may only be created once and we have to determine whether this sObject is one
            // of those types. If the record can produce a uniqueness key then we cache the record and subsequent
            // sObjects which are generated and match on the same key will instead use the cached version.
            SObjectType recordSObjectType = sObj.getSObjectType();

            if( UT_TestFactoryData.keyableMap.containsKey( recordSObjectType ) && !skipCache ){
                String key = UT_TestFactoryData.keyableMap.get( recordSObjectType ).generateKey( record );

                if( key != null ){
                    // Build a map for this sObject type if we've not encountered it before
                    if( !sObjectCacheMap.containsKey( recordSObjectType ) ){
                        sObjectCacheMap.put( recordSObjectType, new Map<String, SObject> () );
                        sObjectCacheCreatedMap.put( recordSObjectType, new Map<String, Boolean> () );
                    }

                    // Place the record into cache for this sObject type
                    if( !sObjectCacheMap.get( recordSObjectType ).containsKey( key ) ){
                        sObjectCacheMap.get( recordSObjectType ).put( key, record );
                        sObjectCacheCreatedMap.get( recordSObjectType ).put( key, false );
                    }

                    // Retrieve record from cache
                    record = sObjectCacheMap.get( recordSObjectType ).get( key );
                }
            }

            return record;
        }

        private Boolean isPolymorphicParentField( String field, fflib_SObjectDescribe sObjectDescribe ){
            SObjectField fieldToken = sObjectDescribe.getField( field );
            DescribeFieldResult dfr = fieldToken.getDescribe();
            return ( dfr.getType() == Schema.DisplayType.REFERENCE
                && dfr.isNamePointing()
                && field != dfr.getName()
                && ( field.endsWithIgnoreCase( '__r' )
                || dfr.getName().endsWithIgnoreCase( 'Id' ) )
            );
        }

        /**
         * This will return the sObject with its fields populated without mocking or modifying the database. Note,
         * this will regenerate the sObject with new values.
         *
         * @return SObject
         */
        public SObject getSObject(){
            return getSObject( false );
        }

        /**
         * Used for returning the sObject which should be inserted into the database or shared across multiple different
         * builders. This is to avoid the same builder being used in different contexts resulting in multiple records.
         */
        public SObject getSObjectForSave(){
            if( savingRecord == null ){
                savingRecord = getSObject();
            }
            return savingRecord;
        }

        /**
         * Allows setting the record within the domain which should be used for saving. This is primarily used when
         * using the queryDomain functionality whereby the reloaded sObject should not be rebuilt and referenced
         * domains should not regenerate the sObject to avoid creating duplicate records.
         */
        public void setSObjectForSave( SObject record ){
            this.savingRecord = record;
        }

        /**
         * Used to determine whether the current SObjectMock has been built already, i.e. mocked or saved to the
         * database. This is used when an instance of SObjectMock is used across multiple builders and must share the
         * same SObject record.
         */
        private Boolean isBuilt(){
            return isBuilt;
        }


        /**
         * Allows setting whether this instance of SObjectMock has been built, i.e mocked or saved.
         *
         * @param isBuilt        True to indicate that the sObject has been mocked or save, otherwise false will allow
         *                         the sObject to be regenerated.
         */
        public void isBuilt( Boolean isBuilt ){
            this.isBuilt = isBuilt;

            if( !isBuilt ){
                savingRecord = null;
            }
        }


        /**
          * This will generate a mocked version of the sObject using the data provided by the mapping classes and will
          * populate the formula, rollup summary and other fields with sample data.
         *
         * @return  SObject        An sObject record which is populated with test data and optionally linked to other
         *                         records through relationships.
         */
        public SObject mock(){
            if( savingRecord == null ){
                savingRecord = getSObject( true );
            }

            return savingRecord;
        }


        /**
          * This will save version of the sObject using the data provided by the mapping classes and will NOT
          * populate the formula, rollup summary and other fields with sample data. Note, the global unit of work
          * instance will be used to handle the order of precedence when writing the objects to the database.
         *
         * @return  SObject        An sObject record which is populated with test data and optionally linked to other
         *                         records through relationships.
         */
        public virtual SObject save(){
            fflib_ISObjectUnitOfWork uow = fflib.unitOfWork.newInstance();
            SObject record = save( uow );
            uow.commitWork();
            return record;
        }

        /**
          * This will save version of the sObject using the data provided by the mapping classes and will NOT
          * populate the formula, rollup summary and other fields with sample data. The provided unit of work
          * instance will be used to handle the order of precedence when writing the objects to the database.
         *
         * @param    uow            Unit of work instance which will be used for transaction management.
         * @return  SObject        An sObject record which is populated with test data and optionally linked to other
         *                         records through relationships.
         */
        public SObject save( fflib_ISObjectUnitOfWork uow ){
            SObject record = saveToUOW( uow );

            // We need to handle a unique situation whereby a parent record might be linked to an sObject which is
            // linked to it, i.e. an account with bank account underneath it, but on the account there is a lookup to
            // the active bank account
            for( Integer i = 0, j = nodes.size(); i < j; i++ ){
                INode node = nodes[ i ];

                if( node instanceof ParentNode ){
                    ParentNode pn = ( ParentNode ) node;

                    if( pn.isAfterInsert() ){
                        uow.registerWork(
                            new ParentAfterInsert ( record, pn.getRelationshipField(), pn.getChildren()[ 0 ].getSObjectForSave() )
                        );
                    }
                }
            }

            // Ensure that any created child records get the relationship fields populated to point back to the
            // parent record
            for( Integer i = 0, j = nodes.size(); i < j; i++ ){
                INode node = nodes[ i ];

                if( node instanceof ChildNode ){
                    ChildNode cn = ( ChildNode ) node;
                    String relationshipName = UT_SObjectFactoryUtils.getChildRelationshipName( record.getSObjectType(), cn.getRelationshipField() );

                    // Only attempt to set the lookup field if we have found a child relationship name
                    if( relationshipName != null && record.getPopulatedFieldsAsMap().containsKey( relationshipName ) ){
                        List<SObject> childRecords = record.getSObjects( relationshipName );

                        for( Integer k = 0, l = childRecords.size(); k < l; k++ ){
                            childRecords[ k ].put( UT_SObjectFactoryUtils.getFieldName( cn.getRelationshipField() ), record.Id );
                        }
                    }
                }
            }

            return record;
        }

        /**
         * Saves the source sObject and all child and parent related sObjects to the database through the support of
         * the unit of work functionality.
         *
         * @return SObject
         */
        private SObject saveToUOW( fflib_ISObjectUnitOfWork uow ){
            dfflib_Utils.verifyNotNull( uow, 'uow' );

            if( getId() != null ){
                throw new dfflib_Utils.InvalidImplementationException( 'createWithId cannot be used with saving records' );
            }

            SObject parent = getSObjectForSave();
            isBuilt( true );

            if( !isCreated( parent ) && parent.Id == null ){
                uow.registerNew( parent );
            }

            for( Integer i = 0, j = nodes.size(); i < j; i++ ){
                resolve( uow, parent, nodes[ i ] );
            }

            return parent;
        }

        /**
         * @return    Returns the nodes which are referenced within this sObjectMock instance. This is to allow parents
         *             to resolve.
         */
        private List<INode> getNodes(){
            return nodes;
        }

        /**
         * This will resolve the relationships between parent and child records and will recursively call itself until
         * all relationships have been resolved. As records can have children as well as parents, we always resolve
         * the parents first and then descend down the tree finding all child sObjects to be linked afterwards.
         *
         * @param parent        Current parent sObject record, all child or parents will be linked to this record.
         * @param node            Current node being processed, this will either be a child or a parent node.
         * @param uow            Unit of work instance which will handle transaction management.
         */
        private void resolve( fflib_ISObjectUnitOfWork uow, SObject parent, INode node ){
            if( node instanceof ChildNode ){
                ChildNode cn = ( ChildNode ) node;
                if( cn.isResolved() ){
                    return;
                }
                cn.setIsResolved( true );

                // Link all of the children of this node to the parent record
                for( SObjectMock child : node.getChildren() ){
                    SObject record = child.getSObjectForSave();

                    if( !child.isBuilt() ){

                        if( !isCreated( record ) && record.Id == null ){
                            uow.registerNew( record, node.getRelationshipField(), parent );
                        }

                        child.isBuilt( true );
                    }

                    // We need to perform an additional check to ensure that we are not attempting to reparent a master-detail
                    // lookup for records which have already been built
                    Boolean isMasterDetail = false;

                    if( record.Id != null && node.getRelationshipField().getDescribe().getRelationshipOrder() != null ){
                        isMasterDetail = true;
                    }

                    if( !isMasterDetail ){
                        uow.registerRelationship( record, node.getRelationshipField(), parent );
                    }

                    for( INode childNode : child.getNodes() ){
                        resolve( uow, child.getSObjectForSave(), childNode );
                    }
                }
            } else if( node instanceof ParentNode ){
                // Node is a parent node, we need to evaluate its tree
                ParentNode pn = ( ParentNode ) node;

                if( pn.isResolved() ){
                    return;
                }
                pn.setIsResolved( true );

                SObjectMock mock = pn.getChildren()[ 0 ];
                SObject record = mock.getSObjectForSave();

                if( !mock.isBuilt() && !isCreated( record ) && record.Id == null ){
                    if( pn.isPriorityNew() ){
                        uow.registerPriorityNew( record );
                    } else{
                        uow.registerNew( record );
                    }

                    // Mark this as being built in case this build is being used across multiple other builders
                    mock.isBuilt( true );
                }

                // We need to perform an additional check to ensure that we are not attempting to reparent a master-detail
                // lookup for records which have already been built
                Boolean isMasterDetail = false;

                if( parent.Id != null && node.getRelationshipField().getDescribe().getRelationshipOrder() != null ){
                    isMasterDetail = true;
                }

                if( !isMasterDetail ){
                    uow.registerRelationship( parent, node.getRelationshipField(), record );
                }

                for( SObjectMock child : node.getChildren() ){
                    for( INode childNode : child.getNodes() ){
                        resolve( uow, record, childNode );
                    }
                }
            }
        }

        /**
         * When saving records to the database an additional check needs to be performed per record being inserted
         * to determine whether there is a key assigned to it which should resolve to a single record. I.e. when
         * inserting countries into the database, we only want to insert one country, not multiple. This method
         * determines if the provided record has already been registered within the unit of work and if not, will
         * mark it as being created preventing multiple records matching the same key from being created.
         */
        private Boolean isCreated( SObject record ){
            Boolean created = false;

            if( UT_TestFactoryData.keyableMap.containsKey( record.getSObjectType() ) ){
                String key = UT_TestFactoryData.keyableMap.get( record.getSObjectType() ).generateKey( record );

                if( key != null ){
                    if( sObjectCacheCreatedMap.containsKey( record.getSObjectType() ) && sObjectCacheCreatedMap.get( record.getSObjectType() ).containsKey( key ) ){
                        created = sObjectCacheCreatedMap.get( record.getSObjectType() ).get( key );
                        sObjectCacheCreatedMap.get( record.getSObjectType() ).put( key, true );
                    }
                }
            }

            return created;
        }

        private void disableCache(){
            skipCache = true;
        }

        private void enableCache(){
            skipCache = false;
        }

    }

    /**
     * All field values, parent and child relationships defined for sObjects are represented as nodes. All nodes
     * must be serializable in order to support converting to JSON and then being able to be deserialized to support
     * the mocking capabilities required.
     */
    public interface INode{
        Map<String, Object> serialize( Boolean isMocking );
        List<SObjectMock> getChildren();
        Schema.SObjectField getRelationshipField();
    }

    /**
      * A parent node represents a parent relationship between the source sObject being generated and a lookup to
      * another record.
      */
    public class ParentNode implements INode{
        private Schema.SObjectField relationshipField;
        private SObjectMock parent;
        private Boolean priorityNew;
        private Boolean isAfterInsert;
        private Boolean isResolved = false;

        public ParentNode( Schema.SObjectField relationshipField, SObjectMock parent, Boolean priorityNew, Boolean isAfterInsert ){
            this.relationshipField = relationshipField;
            this.parent = parent;
            this.priorityNew = priorityNew;
            this.isAfterInsert = isAfterInsert;
        }

        public Map<String, Object> serialize( Boolean isMocking ){
            return new Map<String, Object>{
                UT_SObjectFactoryUtils.getFieldName( this.relationshipField ) => this.parent.serialize( isMocking )
            };
        }

        public List<SObjectMock> getChildren(){
            return new List<SObjectMock>{
                this.parent
            };
        }

        public Schema.SObjectField getRelationshipField(){
            return this.relationshipField;
        }

        public Boolean isPriorityNew(){
            return priorityNew;
        }

        public Boolean isAfterInsert(){
            return isAfterInsert;
        }

        public Boolean isResolved(){
            return isResolved;
        }

        public void setIsResolved( Boolean isResolved ){
            this.isResolved = isResolved;
        }
    }

    /**
     * A child node represents one or more child records which are related to the source sObject being generated.
     * Child nodes are used when generating the JSON structure when generating the sObject.
     */
    public class ChildNode implements INode{
        private String fieldName;
        private List<SObjectMock> children;
        private Schema.SObjectField relationshipField;
        private Boolean isResolved = false;

        public ChildNode( String fieldName, List<SObjectMock> children, Schema.SObjectField relationshipField ){
            this.fieldName = fieldName;
            this.children = children;
            this.relationshipField = relationshipField;
        }

        public Map<String, Object> serialize( Boolean isMocking ){
            List<Map<String, Object>> serializedChildren = new List<Map<String, Object>>();

            for( SObjectMock child : children ){
                if( !child.isBuilt() ){
                    serializedChildren.add( child.serialize( isMocking ) );
                }
            }

            return new Map<String, Object>{
                this.fieldName => new Map<String, Object>{
                    'totalSize' => this.children.size(),
                    'done' => true,
                    'records' => serializedChildren
                }
            };
        }

        public List<SObjectMock> getChildren(){
            return this.children;
        }

        public Schema.SObjectField getRelationshipField(){
            return this.relationshipField;
        }

        public void addChildren( List<SObjectMock> children ){
            this.children.addAll( children );
        }

        public Boolean isResolved(){
            return isResolved;
        }

        public void setIsResolved( Boolean isResolved ){
            this.isResolved = isResolved;
        }
    }

    /**
     * A field node represents a key value pair which will be used when generating the JSON structure when generating
     * an sObject. A field node does not have any parent or child nodes.
     */
    public class FieldValueNode implements INode{
        protected String fieldName;
        protected Object value;

        public FieldValueNode( String fieldName, Object value ){
            this.fieldName = fieldName;
            this.value = value;
        }

        public String getFieldName(){
            return fieldName;
        }

        public Map<String, Object> serialize( Boolean isMocking ){
            return new Map<String, Object>{
                this.fieldName => this.value
            };
        }

        public List<SObjectMock> getChildren(){
            return new List<SObjectMock>();
        }

        public Schema.SObjectField getRelationshipField(){
            return null;
        }
    }

    /**
     * A domain object interacts with the SObjectFactory to populate the field values and allows adding, removing
     * of parent and child relationships to the sObject record the domain is responsible for. Once the domain has
     * all of the necessary data set on the domain, it exposes an API to either mock or save the records to the
     * database.
     */
    public virtual class DomainObject{

        // Private instance
        private SObjectMock sObjectFactory;
        private List<SObjectMock> factories = new List<SObjectMock>();
        private List<DomainObject> orphans = new List<DomainObject>();
        private Map<SObjectField, DomainObject> parentDomains = new Map<SObjectField, DomainObject>();
        private Map<String, DomainObject> childDomains = new Map<String, DomainObject>();

        // Record which was initially generated or provided to the domain object
        public SObject record;

        /**
         * Constructor used for creating a new domain object based on an sObject type without providing any initial
         * values. All default values will be derived from the default values or values added to the domain.
         */
        public DomainObject( SObjectType sType ){
            this( sType.newSObject() );
        }

        /**
         * Constructor used for creating a new domain object based on an sObject type without providing any initial
         * values. All default values will be derived from the default values or values added to the domain.
         */
        public DomainObject( SObject sObj ){
            loadCache( sObj.getSObjectType() );
            sObjectFactory = sObjectBuilder.create( sObj );
            sObjectFactory.disableCache();
            record = sObj;
            sObjectFactory.enableCache();
        }

        /**
         * Exposes the SObjectMock instance which the domain object is using to set up the sObject record. This is used
         * for adding either parent or child relationships when the parent or child requires access to the relationship
         * fields.
         */
        public SObjectMock getSObjectFactory(){
            return sObjectFactory;
        }

        /**
         * Add a field with value to the SObjectFactory
         *
         * @param    fieldName    the field name to set the value on
         * @param    value        the value for the the field
         */
        public virtual DomainObject set( String fieldName, Object value ){
            sObjectFactory.addField( fieldName, value );
            return this;
        }

        public virtual DomainObject set( SObjectField field, Object value ){
            set( UT_SObjectFactoryUtils.getFieldName( field ), value );
            return this;
        }

        /**
         * Removes a field from the SObjectFactory
         *
         * @param    fieldName    the field name to set the value on
         * @param    value        the value for the the field
         */
        protected virtual DomainObject remove( String fieldName ){
            sObjectFactory.removeField( fieldName );
            return this;
        }

        protected virtual DomainObject remove( SObjectField field ){
            remove( UT_SObjectFactoryUtils.getFieldName( field ) );
            return this;
        }

        /**
         * Method to add Parent Node
         *
         * @param    relationshipName
         * @param    parent
         */
        public virtual DomainObject setParent( Schema.SObjectField relationshipField, DomainObject parent ){
            DomainObject result;
            if( parent != null ){
                Boolean isPriorityNew = parent.record.getSObjectType() == this.record.getSObjectType();
                result = setParent( relationshipField, parent, isPriorityNew );
            }
            return result;
        }

        public virtual DomainObject setParent( Schema.SObjectField relationshipField, DomainObject parent, Boolean priorityNew ){
            if( parentDomains.get( relationshipField ) != parent ){
                SObjectMock factory = parent.getSObjectFactory();
                sObjectFactory.addParent( relationshipField, factory, priorityNew, false );
                factories.add( factory );
                parentDomains.put( relationshipField, parent );
            }
            return this;
        }

        public virtual DomainObject setParentAfterInsert( Schema.SObjectField relationshipField, DomainObject parent ){
            if( parentDomains.get( relationshipField ) != parent ){
                SObjectMock factory = parent.getSObjectFactory();
                sObjectFactory.addParent( relationshipField, factory, false, true );
                factories.add( factory );
                parentDomains.put( relationshipField, parent );
            }
            return this;
        }

        /**
         * Method to add a single child record underneath the current parent sObject record.
         *
         * @param    relationshipName    The relationship name between the child records and the parent record.
         * @param    child                SObjectMock instance which will be linked to this instance.
         */
        public virtual DomainObject addChild( String relationshipFieldName, DomainObject child ){
            if( childDomains.get( relationshipFieldName ) != child ){
                SObjectMock factory = child.getSObjectFactory();
                sObjectFactory.addChild( relationshipFieldName, factory );
                factories.add( factory );
                childDomains.put( relationshipFieldName, child );
            }
            return this;
        }

        public virtual DomainObject addChild( SObjectField relationshipField, DomainObject child ){
            DomainObject result;
            if( child != null ){
                String name = UT_SObjectFactoryUtils.getChildRelationshipName( record.getSObjectType(), relationshipField );
                result = addChild( name, child );
            }
            return result;
        }

        public virtual void addChildren( SObjectField relationshipField, List<DomainObject> children ){
            for( DomainObject child : children ){
                addChild( relationshipField, child );
            }
        }

        /**
         * This will generate a mocked version of the sObject using the data provided by the mapping classes and will
         * populate the formula, rollup summary and other fields with sample data.
         *
         * @return  SObject        An sObject record which is populated with test data and optionally linked to other
         *                         records through relationships.
         */
        public virtual SObject mock(){
            build();
            return sObjectFactory.mock();
        }

        /**
         * Allows builders to explicitly set the ID of the sObject which will be generated.
         *
         * @param recordId		The ID to use to apply to the sObject being mocked or saved.
         */
        public virtual DomainObject setId( Id recordId ){
            sObjectFactory.setId( recordId );
            return this;
        }

        /**
         * This will generate a mocked version of the sObject using the data provided by the mapping classes and will
         * populate the formula, rollup summary and other fields with sample data. However, it will generate mock ID's
         * for the sObject within the domain and all parent child records and will populate all lookup fields with
         * the correct ID's.
         *
         * @return  SObject        An sObject record which is populated with test data and optionally linked to other
         *                         records through relationships.
         */
        public virtual SObject mockWithIds(){
            build();
            sObjectFactory.mockIds();
            return sObjectFactory.mock();
        }

        /**
         * Saves the sObject and all related sObjects (child and parents) to the database. Non-writeable fields such
         * as formula and rollup fields will not be populated using the defaults or any supplied values before creating
         * the record.
         *
         * @return  SObject        An sObject record containing the values set during generation and contains the ID's
         *                         of all lookup fields populated.
         */
        public virtual SObject save(){
            fflib_ISObjectUnitOfWork uow = fflib.unitOfWork.newInstance();
            SObject record = save( uow );
            uow.commitWork();
            return record;
        }

        public SObject save( fflib_ISObjectUnitOfWork uow ){
            saveOrphans( uow );
            build();
            return sObjectFactory.save( uow );
        }


        public virtual DomainObject build(){

            if( !processingDomains.contains( this ) ){
                processingDomains.add( this );

                for( DomainObject domain : parentDomains.values().clone() ){
                    domain.build();
                }

                for( DomainObject domain : childDomains.values().clone() ){
                    domain.build();
                }
            }

            return this;
        }

        public SObject useMock(){
            return sObjectFactory.mock();
        }

        /**
         * This will save all orphan structures to the database and any orphans which were added within their domain
         * stuctures.
         */
        private void saveOrphans( fflib_ISObjectUnitOfWork uow ){
            for( DomainObject domain : orphans ){
                for( DomainObject childDomain : domain.getOrphans() ){
                    childDomain.save( uow );
                }

                domain.save( uow );
            }
        }

        /**
         * Allows querying for an existing record within the database using the sObjects name fields' value to locate
         * a matching record. E.g. if the name field on the sObject is "Name" then the value from that field will be
         * used to locate an existing record which matches the same value.
         */
        public virtual SObject query(){
            SObjectField field = fflib_SObjectDescribe.getDescribe( record.getSObjectType() ).getNameField();
            String nameField = UT_SObjectFactoryUtils.getFieldName( field );
            return query( new FindByFieldValueLocator( nameField ) );
        }

        /**
         * Allows querying for an existing record within the database using an instance of ExistingRecordLocator.
         * The instance provided is responsible for searching for existing records based on custom logic, such as
         * using the generated values on the source sObject to locate matching records.
         */
        public virtual SObject query( ExistingRecordLocator checker ){
            return query(
                checker.getRecordId(
                    getSObjectFactory().getSObjectForSave()
                )
            );
        }

        /**
         * Allows querying for an existing record within the database using a record ID. This is primarily used for
         * when reloading test data which was created within the test setup phase within unit test classes.
         */
        public virtual SObject query( Id recordId ){
            if( recordId == null ){
                return null;
            }

            String selectClause = String.join( UT_SObjectFactoryUtils.getFieldNameList( record.getSObjectType() ), ', ' );
            String sObjectName = record.getSObjectType().getDescribe().getName();
            String query = 'SELECT ' + selectClause + ' FROM ' + sObjectName + ' WHERE Id = :recordId LIMIT 1';
            return Database.query( query, AccessLevel.USER_MODE );
        }

        public virtual DomainObject queryDomain(){
            SObject record = query();
            DomainObject domain = new DomainObject( record );
            domain.getSObjectFactory().setSObjectForSave( record );
            domain.getSObjectFactory().isBuilt( true );
            return domain;
        }


        public virtual void addOrphan( DomainObject orphan ){
            orphans.add( orphan );
        }

        private List<DomainObject> getOrphans(){
            return orphans;
        }

    }


    private static Set<DomainObject> processingDomains = new Set<DomainObject>();


    /**
     * Interface which should be implemented on classes which are responsible for locating existing records within the
     * database based upon data populated on a generated sObject.
     */
    public interface ExistingRecordLocator{
        Id getRecordId( SObject record );
    }


    /**
     * An existing record locator class which is responsible for finding records within the database based on a field
     * value populated on a genrated sObject.
     */
    public without sharing class FindByFieldValueLocator implements ExistingRecordLocator{
        private String fieldName;

        public FindByFieldValueLocator( String fieldName ){
            this.fieldName = fieldName;
        }

        public Id getRecordId( SObject record ){
            String sObjectName = record.getSObjectType().getDescribe().getName();
            Object value = record.get( fieldName );
            List<SObject> records = Database.query( 'SELECT Id FROM ' + sObjectName + ' WHERE ' + fieldName + ' = :value LIMIT 1', AccessLevel.USER_MODE );
            return records.isEmpty() ? null : records[ 0 ].Id;
        }
    }


    /**
     * This class is used to handle a unique scenario whereby a record higher up in the hierarchy must be linked to a
     * record below it, but cannot as the child record hasn't been created yet. Parent after insert means run an update
     * against the record after it is has been inserted and link it to sObject which will have now been inserted.
     */
    private class ParentAfterInsert implements fflib_SObjectUnitOfWork.IDoWork{
        // TODO: bulkify this

        private SObject record;
        private SObjectField field;
        private SObject otherRecord;

        public ParentAfterInsert( SObject record, SObjectField field, SObject otherRecord ){
            this.record = record;
            this.field = field;
            this.otherRecord = otherRecord;
        }

        public void doWork(){
            SObject toUpdate = record.getSObjectType().newSObject();
            toUpdate.Id = record.Id;

            toUpdate.put(
                UT_SObjectFactoryUtils.getFieldName( field ),
                otherRecord.Id
            );

            Database.update( toUpdate, AccessLevel.USER_MODE );
        }

    }

}