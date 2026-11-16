/**
 * Test class to insert/update a record for each configured trigger
 * - Mitigating 0% coverage build failure, as no records are inserted due to mocked in domain test classes
 * - Note, no business/process-assertion needed, since this is part of Domain test responsibility
 */
@IsTest( isParallel = true )
private with sharing class TriggersTest{

    @IsTest
    private static void roomTrigger_insert(){
        // Given & When - valid single room
        Room__c room = ( Room__c ) TestFactory.aRoom().asSingleRoom( 101 ).save();

        // Then - room inserted
        Assert.isNotNull( room.Id, 'Room should be inserted, firing RoomTrigger' );
    }
}