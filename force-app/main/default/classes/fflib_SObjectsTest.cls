/**
 * Copyright (c), FinancialForce.com, inc
 * Copyright (c), Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
/**
 *  Unit test module for the fflib_SObjects class
 */
@IsTest( IsParallel = true )
private with sharing class fflib_SObjectsTest{

    private static final String
        SOLUTION_NAME_A = 'A', SOLUTION_NAME_B = 'B', SOLUTION_NAME_C = 'C', SOLUTION_NAME_D = 'D', SOLUTION_NAME_E = 'E', SOLUTION_NAME_F = 'F', SOLUTION_NAME_DUP_LOWER = 'duplicate', SOLUTION_NAME_DUP_MIX = 'DuPlIcAtE';
    private static final String
        SOLUTION_STATUS_DRAFT = 'Draft', SOLUTION_STATUS_REVIEWED = 'Reviewed', SOLUTION_STATUS_DUPLICATE = 'Duplicate';

    private static final DomainSolutions mockDomain{
        get{
            if( mockDomain == null ){
                mockDomain = new DomainSolutions(
                    new List<Solution>{
                        new Solution( SolutionName = SOLUTION_NAME_DUP_LOWER, Status = SOLUTION_STATUS_REVIEWED, IsPublished = true ),
                        new Solution( SolutionName = SOLUTION_NAME_DUP_LOWER, Status = null, IsPublished = false ),

                        new Solution( SolutionName = SOLUTION_NAME_DUP_MIX, Status = null, IsPublished = false ),
                        new Solution( SolutionName = SOLUTION_NAME_DUP_MIX, Status = null, IsPublished = false ),

                        new Solution( SolutionName = SOLUTION_NAME_A, Status = SOLUTION_STATUS_DRAFT, IsPublished = true ),
                        new Solution( SolutionName = SOLUTION_NAME_B, Status = SOLUTION_STATUS_DRAFT, IsPublished = true ),
                        new Solution( SolutionName = SOLUTION_NAME_C, Status = SOLUTION_STATUS_REVIEWED, IsPublished = true ),
                        new Solution( SolutionName = SOLUTION_NAME_D, Status = '', IsPublished = false ),
                        new Solution( SolutionName = SOLUTION_NAME_E, IsPublished = false ),
                        new Solution( SolutionName = SOLUTION_NAME_F, Status = SOLUTION_STATUS_DUPLICATE, IsPublished = true )
                    }
                );
            }

            return mockDomain;
        }
        set;
    }

    private static Integer testFakeIdSequence = 0;
    private static final String TEST_FAKE_ID_PADDING = '000000000000';
    private static Map<SObjectType, String> prefixCacheMap = new Map<SObjectType, String>();

    /**
     * Method that generates a fake Salesforce Id for the given SObjectType.
     *
     * @param	sObjectType	 type of SObject being described.
     * @return	Randomized Salesforce Id for the given SObjectType.
     */
    @TestVisible
    private static Id generateTestRecordId( Schema.SObjectType sobjectType ){
        // Avoid describing SObject multiple times
        if( !prefixCacheMap.containsKey( sObjectType ) ){
            prefixCacheMap.put( sObjectType, sObjectType.getDescribe().getKeyPrefix() );
        }

        String keyPrefix = prefixCacheMap.get( sObjectType );

        testFakeIdSequence++;
        String prefix = TEST_FAKE_ID_PADDING.substring(
            0,
            TEST_FAKE_ID_PADDING.length() - String.valueOf(testFakeIdSequence).length()
        );
        return Id.valueOf( keyPrefix + prefix + testFakeIdSequence );
    }

    @IsTest
    private static void itShouldClearTheField(){
        // Given - create data
        Solution record = new Solution( SolutionName = SOLUTION_NAME_A, Status = 'Draft' );
        DomainSolutions domain = new DomainSolutions( new List<Solution>{ record } );

        // When, Then
        System.Assert.isTrue( !domain.getRecordsBySolutionName( SOLUTION_NAME_A ).isEmpty(), 'Incorrect test data' );
        domain.clearSolutionName();
        System.Assert.isTrue( String.isEmpty( record.SolutionName ), 'Field should have been nullified' );
    }

    @IsTest
    private static void itShouldReturnTheDomainsType(){
        // Given, When, Then
        System.Assert.areEqual(
            ( Object ) Schema.Solution.SObjectType,
            new DomainSolutions( new List<Solution>() )
                .getType(),
            'Unexpected Domain Type'
        );
        System.Assert.areEqual(
            Schema.Solution.SObjectType,
            new DomainSolutions( new List<Solution>() )
                .getSObjectType(),
            'Unexpected Domain SObjectType'
        );
    }


    @IsTest
    private static void itShouldReturnRecordsIds(){
        // Given - create data
        SObjectType solutionSObjectType = Schema.Solution.SObjectType;
        Id idA = fflib_IDGenerator.generate( solutionSObjectType );
        Id idB = fflib_IDGenerator.generate( solutionSObjectType );
        Id idC = fflib_IDGenerator.generate( solutionSObjectType );
        DomainSolutions domain = new DomainSolutions(
            new List<SObject>{
                new Solution( Id = idA ),
                new Solution( Id = idB ),
                new Solution( Id = idC )
            }
        );
        Set<Id> recordIds = new Set<Id>{ idA, idB, idC };
        // When, Then
        System.Assert.isTrue(
            domain.getRecordIds().equals( recordIds ),
            'The domain should return all the record Ids'
        );

        System.Assert.isTrue(
            domain.getIdFieldValues( Schema.Solution.Id ).equals( recordIds ),
            'The domain should return all the record Ids via getIdFieldValues'
        );
    }

    @IsTest
    private static void itShouldReturnRecordsWithFieldValues(){
        // Given, When, Then
        System.Assert.isTrue( mockDomain.getRecordsBySolutionName( SOLUTION_NAME_B ).size() == 1 );
    }

    @IsTest
    private static void itShouldReturnRecordsWithoutFieldValues(){
        // Given, When, Then
        mockDomain.clearSolutionName();
        System.Assert.isTrue( mockDomain.getRecordsWithoutSolutionName().size() == mockDomain.getRecords().size() );
    }

    @IsTest
    private static void itShouldReturnRecordsWithoutAllFields(){
        // Given, When, Then
        mockDomain.clearSolutionName();
        mockDomain.clearSolutionStatus();
        System.Assert.isTrue( mockDomain.getRecordsWithEmptyFields().size() == mockDomain.getRecords().size() );
    }

    @IsTest
    private static void itShouldReturnRecordsWithSolutionName(){
        // Given, When, Then
        System.Assert.isTrue( mockDomain.getRecordsWithSolutionName().size() == mockDomain.getRecords().size() );
    }

    @IsTest
    private static void itShouldReturnRecordsWithAllFieldValues(){
        // Given, When, Then
        System.Assert.isTrue( mockDomain.getRecordsWithAllPopulatedFields().size() == 5 );
    }

    @IsTest
    private static void itShouldReturnFieldValues(){
        // Given - create data
        final Set<String> expectedValidValues = new Set<String>{
            SOLUTION_STATUS_DRAFT,
            SOLUTION_STATUS_REVIEWED,
            SOLUTION_STATUS_DUPLICATE
        };

        final Set<String> expectedAllValues = new Set<String>{
            '',
            null,
            SOLUTION_STATUS_DRAFT,
            SOLUTION_STATUS_REVIEWED,
            SOLUTION_STATUS_DUPLICATE
        };
        // When, Then
        System.Assert.isTrue(
            mockDomain.getStringFieldValues( Schema.Solution.Status, false ).equals( expectedValidValues )
        );
        System.Assert.isTrue(
            mockDomain.getStringFieldValues( Schema.Solution.Status ).equals( expectedAllValues )
        );
        System.Assert.isTrue(
            mockDomain.getFieldValues( Schema.Solution.Status )
                .equals( expectedAllValues )
        );
    }

    @IsTest
    private static void getStringFieldValues_throwsOnNonString(){
        // Given - create data
        DomainSolutions domain = new DomainSolutions(
            new List<Solution>{ new Solution( IsPublished = true ) }
        );

        // When
        try{
            domain.getStringFieldValues( Schema.Solution.IsPublished );
            System.Assert.fail( 'IsPublished is not a String-typed-field and should throw Exception.' );
        } catch( System.TypeException ex ){
            // Then - validate test
            System.Assert.isTrue(
                ex.getMessage().contains( 'Invalid conversion from runtime type' ),
                'Unexpected exception message: ' + ex.getMessage()
            );
        }
    }

    @IsTest
    private static void itShouldSetFieldValue(){
        // Given - create data
        String solutionName = SOLUTION_NAME_F;

        // When, Then
        mockDomain.setSolutionName( solutionName );
        System.Assert.isTrue( mockDomain.getRecordsBySolutionName( solutionName ).size() == mockDomain.getRecords().size() );
    }


    @IsTest
    private static void itShouldSetFieldValueByCondition(){
        // Given - create data
        mockDomain.setPublishingStatusBySolutionName(
            new Map<Object, Object>{
                SOLUTION_NAME_DUP_LOWER => true
            }
        );

        // When, Then
        List<Solution> updatedSolutions = mockDomain.getRecordsBySolutionName( SOLUTION_NAME_DUP_LOWER );
        System.Assert.isTrue( updatedSolutions.size() == 2 );
        System.Assert.isTrue( updatedSolutions[ 0 ].IsPublished );
        System.Assert.isTrue( updatedSolutions[ 1 ].IsPublished );
    }

    @IsTest
    private static void testDomainNameFieldErrorLogging(){
        // Given - create data
        // Test static helpers for raise domain object instance errors
        final String errorMessage = 'Test Error';
        Solution record = new Solution();
        DomainSolutions domain = new DomainSolutions( new List<Solution>{ record } );

        // When, Then
        domain.addNameError( errorMessage );
        System.Assert.areEqual( 1, fflib_SObjects.errorFactory.getAll().size() );
        System.Assert.areEqual( errorMessage, fflib_SObjects.errorFactory.getAll()[ 0 ].message );
        System.Assert.areEqual( Solution.SolutionName, ( ( fflib_SObjects.FieldError ) fflib_SObjects.errorFactory.getAll()[ 0 ] ).field );
    }

    @IsTest
    private static void testDomainRecordErrorLogging(){
        // Given - create data
        // Test static helpers for raise domain object instance errors
        final String errorMessage = 'Test Error';
        Solution record = new Solution();
        DomainSolutions domain = new DomainSolutions( new List<Solution>{ record } );

        // When, Then
        domain.addError( errorMessage );
        System.Assert.areEqual( 1, fflib_SObjects.errorFactory.getAll().size() );
        System.Assert.areEqual( errorMessage, fflib_SObjects.errorFactory.getAll()[ 0 ].message );
    }

    @IsTest
    private static void testErrorLogging(){
        // Given - create data
        // Test static helpers for raise none domain object instance errors
        Solution mockSolution = new Solution ( SolutionName = SOLUTION_NAME_A, Status = SOLUTION_STATUS_DUPLICATE );

        // When, Then
        fflib_SObjects.errorFactory.error( 'Error', mockSolution );
        fflib_SObjects.errorFactory.error( 'Error', mockSolution, Solution.Status );

        System.Assert.areEqual( 2, fflib_SObjects.errorFactory.getAll().size() );
        System.Assert.areEqual( 'Error', fflib_SObjects.errorFactory.getAll()[ 0 ].message );
        System.Assert.areEqual( 'Error', fflib_SObjects.errorFactory.getAll()[ 1 ].message );
        System.Assert.areEqual( Solution.Status, ( ( fflib_SObjects.FieldError ) fflib_SObjects.errorFactory.getAll()[ 1 ] ).field );
        fflib_SObjects.errorFactory.clearAll();

        System.Assert.areEqual( 0, fflib_SObjects.errorFactory.getAll().size() );
    }

    @IsTest
    private static void groupRecordsByFieldValue_success(){
        // When - perform test
        Map<Object, List<SObject>> mappedList = mockDomain.groupRecordsByFieldValue( Solution.SolutionName );

        // Then - validate test
        System.Assert.areEqual( 8, mappedList.keySet().size(), 'Expected #' + 8 + ' unique identifiers to be set as Map-keys' );

        List<SObject> solsByDuplicateName = mappedList.get( SOLUTION_NAME_DUP_LOWER );
        System.Assert.areNotEqual( null, solsByDuplicateName, 'Expected sampleSolutionName to be an identifier in Map' );
        System.Assert.areEqual( 2, solsByDuplicateName.size(), 'Expected #' + 2 + ' Solutions to be mapped to same name' );
    }

    @IsTest
    private static void groupRecordsByFieldValue_emptyFieldValue(){
        // Given - set data
        DomainSolutions domain = new DomainSolutions( new List<Solution>{ new Solution() } );

        // When - perform test
        try{
            Map<Object, List<SObject>> mappedList = domain.groupRecordsByFieldValue( Solution.Status );
            System.Assert.fail( 'No input was provided on the Status field, thus Exception was expected.' );
        } catch( Exception ex ){
            // Then - validate test
            System.Assert.isInstanceOfType( ex, fflib_Objects.InvalidValueException.class, 'Expected an fflib_Objects.InvalidValueException, got ' + ex.getTypeName() );
        }
    }

    @IsTest
    private static void groupRecordsByFieldValue_wrongSObject(){
        // Given - set data
        DomainSolutions domain = new DomainSolutions( new List<Solution>{ new Solution() } );

        // When - perform test
        try{
            Map<Object, List<SObject>> mappedList = domain.groupRecordsByFieldValue( Account.Industry );
            System.Assert.fail( 'Account.Industry is not a field on Solution, thus Exception was expected.' );
        } catch( Exception ex ){
            // Then - validate test
            System.Assert.isInstanceOfType( ex, System.SObjectException.class, 'Expected an System.SObjectException, got ' + ex.getTypeName() );
        }
    }

    @IsTest
    private static void groupRecordsByFieldValue_booleanKey(){
        // Given - create data: group by a Boolean field, so the map key is a Boolean, not a stringified "true"/"false"
        DomainSolutions domain = new DomainSolutions(
            new List<Solution>{
                new Solution( SolutionName = SOLUTION_NAME_A, IsPublished = true ),
                new Solution( SolutionName = SOLUTION_NAME_B, IsPublished = true ),
                new Solution( SolutionName = SOLUTION_NAME_C, IsPublished = false )
            }
        );

        // When - perform test
        Map<Object, List<SObject>> mappedList = domain.groupRecordsByFieldValue( Solution.IsPublished );

        // Then - validate test: exactly two Boolean keys, and lookup by the native Boolean type succeeds
        System.Assert.areEqual( 2, mappedList.keySet().size(), 'Expected one map-key per distinct Boolean value' );
        System.Assert.isTrue( mappedList.containsKey( true ), 'Expected the native Boolean value true to be usable as a map key' );
        System.Assert.isTrue( mappedList.containsKey( false ), 'Expected the native Boolean value false to be usable as a map key' );
        System.Assert.areEqual( 2, mappedList.get( true ).size(), 'Expected 2 Solutions grouped under the Boolean key true' );
        System.Assert.areEqual( 1, mappedList.get( false ).size(), 'Expected 1 Solution grouped under the Boolean key false' );
    }

    @IsTest
    private static void getRecordsByFieldValue_success(){
        // When - perform test
        List<SObject> objectList = mockDomain.getRecordsByFieldValueDirect( Solution.SolutionName, SOLUTION_NAME_DUP_MIX );

        // Then - validate test
        System.Assert.areEqual( 2, objectList.size(), 'Expected different size of objectList ' + objectList.size() );
    }

    @IsTest
    private static void getRecordsByFieldValue_wrongSObject(){
        // When - perform test
        try{
            mockDomain.getRecordsByFieldValueDirect( Account.AccountNumber, SOLUTION_NAME_A );
            System.Assert.fail( 'Account.AccountNumber is not a field on Solution, thus Exception was expected.' );
        } catch( Exception ex ){
            // Then - validate test
            System.Assert.areEqual( 'System.SObjectException', ex.getTypeName(), 'Expected different type of Exception' );
        }
    }

    @IsTest
    private static void getRecordsByFieldValue_emptyValue(){
        // Given - create data: one record with a blank Status among non-blank ones
        DomainSolutions domain = new DomainSolutions(
            new List<Solution>{
                new Solution( SolutionName = SOLUTION_NAME_A, Status = SOLUTION_STATUS_DRAFT ),
                new Solution( SolutionName = SOLUTION_NAME_B, Status = '' )
            }
        );

        // When - perform test
        List<SObject> objectList = domain.getRecordsByFieldValueDirect( Solution.Status, '' );

        // Then - validate test: current implementation matches on value equality, no exception on blank
        System.Assert.areEqual( 1, objectList.size(), 'Expected only the blank-status record to match' );
    }

    @IsTest
    private static void getRecordIds_success(){
        // Given - create data
        List<Solution> solutions = new List<Solution>{
            new Solution( Id = fflib_IDGenerator.generate( Solution.SObjectType ) ),
            new Solution( Id = fflib_IDGenerator.generate( Solution.SObjectType ) )
        };
        // When, Then
        Set<Id> recordIds = new DomainSolutions( solutions ).getRecordIds();
        System.Assert.areEqual( 2, recordIds.size() );
        System.Assert.isTrue( recordIds.contains( solutions[ 0 ].Id ) );
        System.Assert.isTrue( recordIds.contains( solutions[ 1 ].Id ) );
    }

    @IsTest
    private static void getIdFieldValues_includeNulls(){
        // Given - create data: one record with a populated OwnerId, one without
        DomainSolutions domain = new DomainSolutions(
            new List<Solution>{
                new Solution( OwnerId = fflib_IDGenerator.generate( User.SObjectType ) ),
                new Solution()
            }
        );

        // When, Then - default (no-arg) includes null values
        Set<Id> idsIncludingNulls = domain.getIdFieldValues( Schema.Solution.OwnerId );
        System.Assert.areEqual( 2, idsIncludingNulls.size(), 'Expected the null OwnerId to be included by default' );
        System.Assert.isTrue( idsIncludingNulls.contains( null ) );

        // When, Then - explicit includeNulls = false excludes null values
        Set<Id> idsExcludingNulls = domain.getIdFieldValues( Schema.Solution.OwnerId, false );
        System.Assert.areEqual( 1, idsExcludingNulls.size(), 'Expected the null OwnerId to be excluded' );
        System.Assert.isFalse( idsExcludingNulls.contains( null ) );
    }

    @IsTest
    private static void getStringFieldValues_excludeBlanks(){
        // Given - create data
        List<Solution> solutions = new List<Solution>{
            new Solution( SolutionName = SOLUTION_NAME_A ),
            new Solution( SolutionName = SOLUTION_NAME_B )
        };
        // When, Then
        Set<String> strings = new DomainSolutions( solutions ).getStringFieldValues( Solution.SolutionName, false );
        System.Assert.areEqual( 2, strings.size() );
        System.Assert.isTrue( strings.contains( solutions[ 0 ].SolutionName ) );
        System.Assert.isTrue( strings.contains( solutions[ 1 ].SolutionName ) );
    }

    @IsTest
    private static void getParentIdFieldValues_success(){
        // Given - create data
        List<Solution> solutions = new List<Solution>{
            new Solution(
                Owner = new User( ContactId = fflib_IDGenerator.generate( Contact.SObjectType ) ),
                OwnerId = fflib_IDGenerator.generate( User.SObjectType )
            )
        };
        // When, Then
        Set<Id> recordIds = new DomainSolutions( solutions ).getParentIdFieldValues( 'Owner.ContactId' );
        System.Assert.areEqual( 1, recordIds.size() );
        System.Assert.isTrue( recordIds.contains( solutions[ 0 ].Owner.ContactId ) );
    }

    private class DomainSolutions extends fflib_SObjects{
        public DomainSolutions( List<SObject> records ){
            super( records, Schema.Solution.SObjectType );
        }

        public List<Solution> getRecordsBySolutionName( String solutionName ){
            return getRecordsByFieldValues(
                Schema.Solution.SolutionName,
                new Set<Object>{ solutionName }
            );
        }

        public List<Solution> getRecordsBySolutionStatus( String status ){
            return getRecordsByFieldValue(
                Schema.Solution.Status,
                status
            );
        }

        public List<Solution> getRecordsWithoutSolutionName(){
            return getRecordsWithBlankFieldValues(
                Schema.Solution.SolutionName
            );
        }

        public List<Solution> getRecordsWithSolutionName(){
            return getRecordsWithNotBlankFieldValues(
                Schema.Solution.SolutionName
            );
        }

        public List<Solution> getRecordsWithEmptyFields(){
            return getRecordsWithAllBlankFieldValues(
                new Set<Schema.SObjectField>{
                    Schema.Solution.SolutionName,
                    Schema.Solution.Status
                }
            );
        }

        public List<Solution> getRecordsWithAllPopulatedFields(){
            return getRecordsWithAllNotBlankFieldValues(
                new Set<Schema.SObjectField>{
                    Schema.Solution.SolutionName,
                    Schema.Solution.Status
                }
            );
        }

        /**
         * Test-only passthrough exposing the protected getRecordsByFieldValue(s) for direct,
         * arbitrary-field assertions from the outer test class.
         */
        public List<SObject> getRecordsByFieldValueDirect( Schema.SObjectField field, Object value ){
            return getRecordsByFieldValue( field, value );
        }

        public void setSolutionName( String solutionName ){
            setFieldValue( Schema.Solution.SolutionName, solutionName );
        }

        public void setPublishingStatusBySolutionName( Map<Object, Object> statusBySolutionName ){
            setFieldValueByMap(
                Schema.Solution.SolutionName,
                Schema.Solution.IsPublished,
                statusBySolutionName );
        }

        public void addNameError( String message ){
            addError( Schema.Solution.SolutionName, message );
        }

        public void clearSolutionStatus(){
            clearField( Schema.Solution.Status );
        }

        public void clearSolutionName(){
            clearField( Schema.Solution.SolutionName );
        }
    }
}