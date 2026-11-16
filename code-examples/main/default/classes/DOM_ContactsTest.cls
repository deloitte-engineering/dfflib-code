/**
 * Test shell for Contact domain — currently holds only the Builder.
 * No test methods yet; a DOM_Contacts domain class will be added when Contact business logic is needed.
 */
@IsTest( isParallel = true )
public with sharing class DOM_ContactsTest{

    // ============================================================================
    // BUILDER
    // ============================================================================
    public class Builder extends dfflib_UT_SObjectFactory.DomainObject{
        public Builder(){
            super( Contact.SObjectType );
        }

        public Builder asDefault(){
            withName( 'Test', 'Guest' );
            set( Contact.Email, 'testguest' + '@example.com' );
            return this;
        }

        public Builder withEmail( String email ){
            set( Contact.Email, email );
            return this;
        }

        public Builder withFirstName( String firstName ){
            set( Contact.FirstName, firstName );
            return this;
        }

        public Builder withLastName( String lastName ){
            set( Contact.LastName, lastName );
            return this;
        }

        public Builder withName( String firstName, String lastName ){
            set( Contact.FirstName, firstName );
            set( Contact.LastName, lastName );
            return this;
        }

        public Builder withPhone( String phone ){
            set( Contact.Phone, phone );
            return this;
        }
    }
}