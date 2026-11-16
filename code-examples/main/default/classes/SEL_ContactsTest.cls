/**
 * Test class for SEL_Contacts
 *
 * Demonstrates D'fflib selector test patterns including:
 * - mockExecuteQuery() for preventing database calls
 * - verifyQueryAndBindVariableKeys() fluent validation chain
 */
@IsTest( isParallel = true )
private with sharing class SEL_ContactsTest{

    @IsTest
    private static void selectByEmails_multipleEmails(){
        // create mocks - prevent database calls
        SEL_Contacts selector = SEL_Contacts.newInstance( dfflib_Database.Context.NONE );
        fflib_ApexMocks mocks = selector.mockExecuteQuery();

        // Given - set input
        Set<String> emails = new Set<String>{ 'jane.doe@example.com', 'john.doe@example.com' };

        // When - perform test
        selector.selectByEmails( emails );

        // Then - validate query, condition and bind variables
        selector.verifyQueryAndBindVariableKeys( mocks )
            .validateCondition( 'Email IN :emails' )
            .validateBindVariableValue( 'emails', emails )
            .validateFields( new Set<SObjectField>{
                Contact.Email,
                Contact.FirstName,
                Contact.LastName,
                Contact.Phone
            } );
    }
}
