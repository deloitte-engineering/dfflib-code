/**
 * Test class for SEL_RoomReservations class
 *
 * Demonstrates D'fflib selector test patterns including:
 * - mockExecuteQuery() for preventing database calls on standard queries
 * - mockExecuteAggregateQuery() for preventing database calls on aggregate queries
 * - verifyQueryAndBindVariableKeys() for fluent validation
 * - validateCondition() for query condition verification
 * - validateBindVariableValue() for bind variable verification
 * - validateFields() for field selection verification (Set<String> for aggregate, Set<SObjectField> for standard)
 */
@IsTest( isParallel = true )
private with sharing class SEL_RoomReservationsTest{
    @IsTest
    private static void selectOpenCountPerRoomId_emptyRoomIds(){
        // create mocks - prevent database calls; use mockExecuteAggregateQuery for aggregate queries
        SEL_RoomReservations selector = SEL_RoomReservations.newInstance( dfflib_Database.Context.FULL );
        fflib_ApexMocks mocks = selector.mockExecuteAggregateQuery();

        // Given - setup Set to validate bind-passing
        Set<Id> roomIds = new Set<Id>();

        // When - perform test
        selector.selectOpenCountPerRoomId( roomIds );

        // Then - validate query, condition and fields (use Set<String> for aggregate fields)
        dfflib_QueryFactory qf = selector.verifyQueryAndBindVariableKeys( mocks )
            .validateFields( new Set<String>{
                'Room__c',
                'COUNT( Id ) numOpenReservations'
            } )
            .validateCondition( 'Room__c IN :roomIds AND Status__c IN :openStatuses' )
            .validateBindVariableValue( 'roomIds', roomIds )
            .validateBindVariableValue( 'openStatuses', DOM_RoomReservations.STATUSES_OPEN )
            .qf;
        System.Assert.areEqual( 'Room__c', qf.getGroupByField(), 'Expected Group by on Room__c' );
    }

    @IsTest
    private static void selectByRoomId_emptyRoomIds(){
        // create mocks - prevent database calls
        SEL_RoomReservations selector = SEL_RoomReservations.newInstance( dfflib_Database.Context.FULL );
        fflib_ApexMocks mocks = selector.mockExecuteQuery();

        // Given - setup Set to validate bind-passing
        Set<Id> roomIds = new Set<Id>();

        // When - perform test
        selector.selectByRoomId( roomIds );

        // Then - validate query, condition and fields
        selector.verifyQueryAndBindVariableKeys( mocks )
            .validateCondition( 'Room__c IN :roomIds' )
            .validateBindVariableValue( 'roomIds', roomIds )
            .validateFields( new Set<SObjectField>{ RoomReservation__c.Room__c, RoomReservation__c.Status__c } );
    }

    @IsTest
    private static void selectByContactId_singleContactId(){
        // create mocks - prevent database calls
        SEL_RoomReservations selector = SEL_RoomReservations.newInstance( dfflib_Database.Context.FULL );
        fflib_ApexMocks mocks = selector.mockExecuteQuery();

        // Given - setup Set to validate bind-passing
        Id contactId = fflib_IDGenerator.generate( Contact.SObjectType );
        Set<Id> contactIds = new Set<Id>{ contactId };

        // When - perform test
        selector.selectByContactId( contactIds );

        // Then - validate query, condition and fields
        selector.verifyQueryAndBindVariableKeys( mocks )
            .validateCondition( 'Contact__c IN :contactIds' )
            .validateBindVariableValue( 'contactIds', contactIds );
    }
}