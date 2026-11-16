/**
 * Test Factory entry point class
 *
 * Demonstrates D'fflib test factory patterns including:
 * - Static factory methods for each builder
 * - Fluent API for test data creation
 * - Support for mock(), mockWithIds(), and save() patterns
 *
 * Builders are co-located with their domain test class:
 * - DOM_RoomsTest.Builder            → TestFactory.aRoom()
 * - DOM_RoomReservationsTest.Builder → TestFactory.aRoomReservation()
 * - DOM_ContactsTest.Builder         → TestFactory.aContact()
 *
 * Usage:
 *   Room__c room = TestFactory.aRoom()
 *       .asSingleRoom( 101 )
 *       .mockWithIds();
 *
 *   RoomReservation__c reservation = TestFactory.aRoomReservation()
 *       .forRoom( TestFactory.aRoom().asSingleRoom( 101 ) )
 *       .asDefault()
 *       .mockWithIds();
 *
 *   // Reservation passing all validation rules (Room, Contact, dates, guests)
 *   RoomReservation__c validReservation = TestFactory.aRoomReservation()
 *       .asValid()
 *       .mockWithIds();
 */
@IsTest( isParallel = true )
public with sharing class TestFactory{
    /**
     * Create a Contact builder
     * @return DOM_ContactsTest.Builder instance
     */
    public static DOM_ContactsTest.Builder aContact(){
        return new DOM_ContactsTest.Builder();
    }

    /**
     * Create a Room builder
     * @return DOM_RoomsTest.Builder instance
     */
    public static DOM_RoomsTest.Builder aRoom(){
        return new DOM_RoomsTest.Builder();
    }

    /**
     * Create a RoomReservation builder
     * @return DOM_RoomReservationsTest.Builder instance
     */
    public static DOM_RoomReservationsTest.Builder aRoomReservation(){
        return new DOM_RoomReservationsTest.Builder();
    }
}