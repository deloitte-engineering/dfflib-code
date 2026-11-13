/**
 * Trigger for Room__c object
 *
 * D'fflib Feature Demonstrated:
 * - Metadata-driven trigger framework
 * - Single-line trigger that delegates to dfflib_SObjectDomain.triggerHandler
 * - All trigger logic is handled in the Domain class (DOM_Rooms.cls)
 * - Trigger handlers are registered in Domain constructor
 */
trigger RoomTrigger on Room__c ( before insert, before update, before delete,
    after insert, after update, after delete, after undelete ){
    dfflib_SObjectDomain.triggerHandler( DOM_Rooms.class );
}
