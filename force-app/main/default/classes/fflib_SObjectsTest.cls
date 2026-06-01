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
 *  Unit test module for the fflib_SObjects class
 * 
 *  @author     Rafael Fernandes dos Santos (rfernandesdossantos@deloitte.nl)
 *  @created    October 2025
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
            domain.pluckIds( Schema.Solution.Id ).equals( recordIds ),
            'The domain should return all the record Ids'
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
    private static void itShouldReturnRecordsWithoutAllFieldValues(){
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
            mockDomain.pluckStrings( Schema.Solution.Status ).equals( expectedValidValues )
        );
        System.Assert.isTrue(
            mockDomain.getFieldValues( Schema.Solution.Status )
                .equals( expectedAllValues )
        );
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
    private static void mapSObjectsListByIdentifier_success(){
        // When - perform test
        Map<String, List<SObject>> mappedList = mockDomain.mapSObjectsListByIdentifier( Solution.SolutionName );

        // Then - validate test
        System.Assert.areEqual( 8, mappedList.keySet().size(), 'Expected #' + 8 + ' unique identifiers to be set as Map-keys' );

        List<SObject> solsByDuplicateName = mappedList.get( SOLUTION_NAME_DUP_LOWER );
        System.Assert.areNotEqual( null, solsByDuplicateName, 'Expected sampleSolutionName to be an identifier in Map' );
        System.Assert.areEqual( 2, solsByDuplicateName.size(), 'Expected #' + 2 + ' Solutions to be mapped to same name' );
    }

    @IsTest
    private static void mapSObjectsListByIdentifierLowerCase_success(){
        // When - perform test
        Map<String, List<SObject>> mappedList = mockDomain.mapSObjectsListByIdentifier( Solution.SolutionName, true );

        // Then - validate test
        System.Assert.areEqual( 7, mappedList.keySet().size(), 'Expected 7 unique identifiers to be set as Map-keys' );

        List<SObject> solsByDuplicateName = mappedList.get( SOLUTION_NAME_DUP_LOWER );
        System.Assert.areNotEqual( null, solsByDuplicateName, 'Expected solDuplicateNameA to be an identifier in Map' );
        System.Assert.areEqual( 4, solsByDuplicateName.size(), 'Expected 4 Solutions to be mapped to SolutionName' );
    }

    @IsTest
    private static void mapSObjectsListByIdentifier_emptyFieldValue(){
        // Given - set data
        DomainSolutions domain = new DomainSolutions( new List<Solution>{ new Solution() } );

        // When - perform test
        try{
            Map<String, List<SObject>> mappedList = domain.mapSObjectsListByIdentifier( Solution.Status );
            throw new fflib.InvalidImplementationException( 'You should have never entered here.' );
        } catch( Exception ex ){
            // Then - validate test
            System.Assert.isInstanceOfType( ex, fflib.InvalidInputValueException.class, 'Expected an fflib.InvalidInputValueException, got ' + ex.getTypeName() );
        }
    }

    @IsTest
    private static void mapSObjectsListByIdentifier_fieldFromOtherSObject(){
        // Given - set data
        DomainSolutions domain = new DomainSolutions( new List<Solution>{ new Solution() } );

        // When - perform test
        try{
            Map<String, List<SObject>> mappedList = domain.mapSObjectsListByIdentifier( Account.Industry );
            throw new fflib.InvalidImplementationException( 'You should have never entered here.' );
        } catch( Exception ex ){
            // Then - validate test
            System.Assert.isInstanceOfType( ex, System.SObjectException.class, 'Expected an System.SObjectException, got ' + ex.getTypeName() );
        }
    }

    @IsTest
    private static void filterListByIdentifier_success(){
        // When - perform test
        List<SObject> objectList = mockDomain.filterListByFieldValue( Solution.SolutionName, SOLUTION_NAME_DUP_MIX );

        // Then - validate test
        System.Assert.areEqual( 2, objectList.size(), 'Expected different size of objectList ' + objectList.size() );
    }

    @IsTest
    private static void filterListByIdentifier_fieldFromOtherSObject(){
        // When - perform test
        try{
            mockDomain.filterListByFieldValue( Account.AccountNumber, SOLUTION_NAME_A );
            throw new fflib.InvalidImplementationException( 'You should have never entered here.' );
        } catch( Exception ex ){
            // Then - validate test
            System.Assert.areEqual( 'System.SObjectException', ex.getTypeName(), 'Expected different type of Exception' );
        }
    }

    @IsTest
    private static void filterListByIdentifier_emptyValue(){
        // When - perform test
        try{
            mockDomain.filterListByFieldValue( Solution.Status, '' );
            throw new fflib.InvalidImplementationException( 'You should have never entered here since the identifier field was empty' );
        } catch( Exception ex ){
            // Then - validate test
            System.Assert.isInstanceOfType( ex, fflib.InvalidInputValueException.class, 'Expected different type of Exception since OwnerId - identifierField - was left empty on purpose, got ' + ex.getTypeName() );
        }
    }

    @IsTest
    private static void shouldPluckIdsCorrectly(){
        // Given - create data
        List<Solution> solutions = new List<Solution>{
            new Solution( Id = fflib_IDGenerator.generate( Solution.SObjectType ) ),
            new Solution( Id = fflib_IDGenerator.generate( Solution.SObjectType ) )
        };
        // When, Then
        Set<Id> recordIds = new DomainSolutions( solutions ).pluckIds();
        System.Assert.areEqual( 2, recordIds.size() );
        System.Assert.isTrue( recordIds.contains( solutions[ 0 ].Id ) );
        System.Assert.isTrue( recordIds.contains( solutions[ 1 ].Id ) );
    }

    @IsTest
    private static void shouldPluckIdsCorrectlyIdSpecified(){
        // Given - create data
        List<Solution> solutions = new List<Solution>{
            new Solution( Id = fflib_IDGenerator.generate( Solution.SObjectType ) ),
            new Solution( Id = fflib_IDGenerator.generate( Solution.SObjectType ) )
        };
        // When, Then
        Set<Id> recordIds = new DomainSolutions( solutions ).pluckIds( Solution.Id );
        System.Assert.areEqual( 2, recordIds.size() );
        System.Assert.isTrue( recordIds.contains( solutions[ 0 ].Id ) );
        System.Assert.isTrue( recordIds.contains( solutions[ 1 ].Id ) );
    }

    @IsTest
    private static void shouldPluckStringsCorrectly(){
        // Given - create data
        List<Solution> solutions = new List<Solution>{
            new Solution( SolutionName = SOLUTION_NAME_A ),
            new Solution( SolutionName = SOLUTION_NAME_B )
        };
        // When, Then
        Set<String> strings = new DomainSolutions( solutions ).pluckStrings( Solution.SolutionName );
        System.Assert.areEqual( 2, strings.size() );
        System.Assert.isTrue( strings.contains( solutions[ 0 ].SolutionName ) );
        System.Assert.isTrue( strings.contains( solutions[ 1 ].SolutionName ) );
    }

    @IsTest
    private static void shouldPluckIdsFromRelationshipCorrectly(){
        // Given - create data
        List<Solution> solutions = new List<Solution>{
            new Solution(
                Owner = new User( ContactId = fflib_IDGenerator.generate( Contact.SObjectType ) ),
                OwnerId = fflib_IDGenerator.generate( User.SObjectType )
            )
        };
        // When, Then
        Set<Id> recordIds = new DomainSolutions( solutions ).pluckIdsFromRelationship( 'Owner.ContactId' );
        System.Assert.areEqual( 1, recordIds.size() );
        System.Assert.isTrue( recordIds.contains( solutions[ 0 ].Owner.ContactId ) );
    }

    @IsTest
    private static void getPicklistValues_validReturn(){
        // Given - create data
        List<Schema.PicklistEntry> pleForSolutionStatusName = Solution.Status.getDescribe().getPicklistValues();

        // When, Then
        List<Schema.PicklistEntry> ple = mockDomain.getPicklistValues( 'Solution', 'Status' );
        System.Assert.areEqual( ple.size(), pleForSolutionStatusName.size() );
        System.Assert.areEqual( ple[ 0 ].getLabel(), pleForSolutionStatusName[ 0 ].getLabel() );
    }

    @IsTest
    private static void getPicklistValues_missingInput(){
        // When - perform test
        try{
            mockDomain.getPicklistValues( 'Solution', null );
            throw new fflib.InvalidImplementationException( 'This Exception should not be thrown as field-input was empty' );
        } catch( Exception ex ){
            // Then - validate
            System.Assert.isInstanceOfType( ex, fflib.InvalidInputValueException.class, 'Expected an fflib.InvalidInputValueException, got ' + ex.getTypeName() );
        }
    }

    @IsTest
    private static void getPicklistValues_invalidInput(){
        // When - perform test
        try{
            mockDomain.getPicklistValues( 'test1', 'test2' );
            throw new fflib.MissingDataException( 'This Exception should not be thrown as input is invalid (not valid fields)' );
        } catch( Exception ex ){
            // Then - validate
            System.Assert.isInstanceOfType( ex, fflib.InvalidImplementationException.class, 'Expected an fflib.InvalidImplementationException, got ' + ex.getTypeName() );
        }
    }

    @IsTest
    private static void getPicklistValuesToStrings(){
        // Given - create data
        List<String> picklistValuesForMyVehicle = mockDomain.getPicklistValuesToStrings( 'Solution', 'Status' );

        // When, Then
        System.Assert.isTrue( picklistValuesForMyVehicle.contains( 'Draft'.toUpperCase() ), 'Expected to contain this picklist value' );
        System.Assert.isTrue( picklistValuesForMyVehicle.contains( 'Reviewed'.toUpperCase() ), 'Expected to contain this picklist value' );
    }

    @IsTest
    private static void isValidPicklistValue(){
        // Given - create data

        // When, Then
        // Success
        System.Assert.isTrue( mockDomain.isValidPicklistValue( Solution.Status, Solution.SObjectType, 'Draft' ), 'Expected Unknown to be a valid picklist value on Solution.Status field' );

        // Failure
        System.Assert.isFalse( mockDomain.isValidPicklistValue( Solution.Status, Solution.SObjectType, null ), 'Expected false since blank picklist value was provided' );
        System.Assert.isFalse( mockDomain.isValidPicklistValue( Solution.Status, Solution.SObjectType, 'Non existing picklist' ), 'Expected false since picklist values should not exist in Solution.Status' );

        try{
            System.Assert.isFalse( mockDomain.isValidPicklistValue( Solution.Status, Contact.SObjectType, 'Unknown' ), 'Expected false since no Status field should exist on Contact SObjectType' );
            throw new fflib.InvalidImplementationException( 'This Exception should never be thrown' );
        } catch( Exception ex ){
            String exceptionMessage = ex.getMessage();
            System.Assert.isTrue( exceptionMessage.contains( 'Contact' ), 'Expected attempted SObjectType to be in Exception message ' + exceptionMessage );
            System.Assert.isTrue( exceptionMessage.contains( 'Status' ), 'Expected attempted Field to be in Exception message ' + exceptionMessage );
        }
    }

    private class DomainSolutions extends fflib_SObjects{
        public DomainSolutions( List<SObject> records ){
            super( records, Schema.Solution.SObjectType );
        }

        public List<Solution> getRecordsBySolutionName( String solutionName ){
            return filterListByFieldValues(
                Schema.Solution.SolutionName,
                new Set<Object>{ solutionName }
            );
        }

        public List<Solution> getRecordsBySolutionStatus( String status ){
            return filterListByFieldValue(
                Schema.Solution.Status,
                status
            );
        }

        public List<Solution> getRecordsWithoutSolutionName(){
            return filterListByBlankFieldValues(
                Schema.Solution.SolutionName
            );
        }

        public List<Solution> getRecordsWithSolutionName(){
            return filterListByNonEmptyFieldValues(
                Schema.Solution.SolutionName
            );
        }

        public List<Solution> getRecordsWithEmptyFields(){
            return filterListByAllBlankFieldValues(
                new Set<Schema.SObjectField>{
                    Schema.Solution.SolutionName,
                    Schema.Solution.Status
                }
            );
        }

        public List<Solution> getRecordsWithAllPopulatedFields(){
            return filterListByAllNonEmptyFieldValues(
                new Set<Schema.SObjectField>{
                    Schema.Solution.SolutionName,
                    Schema.Solution.Status
                }
            );
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