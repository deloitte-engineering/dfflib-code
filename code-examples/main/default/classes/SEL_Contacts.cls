/**
 * Selector class for Contact object
 *
 * Demonstrates D'fflib selector patterns including:
 * - Selector for a standard object, registered via Dfflib_Selector_Config__mdt
 * - executeQuery with bind variable maps
 */
public with sharing class SEL_Contacts extends dfflib_SObjectSelector{

    /**
     * Creates a new instance of the selector via the application class. This is here to allow unit tests to override
     * and inject a mock instead of this class or to switch out this class for a new version.
     *
     * @param ctx   The database context to use for this selector instance (e.g. FULL, WITH_SHARING, NONE)
     * @return      A new SEL_Contacts instance (or test mock) bound to the given context
     */
    public static SEL_Contacts newInstance( dfflib_Database.Context ctx ){
        return ( SEL_Contacts ) dfflib.selector.newInstance( Contact.SObjectType, ctx );
    }

    /**
     * Returns the SObject type for the selector. This is used to retrieve the sObject name when building the SOQL queries.
     *
     * @return  Contact SObjectType token
     */
    public override Schema.SObjectType getSObjectType(){
        return Contact.SObjectType;
    }

    /**
     * Returns the sObject fields which should be selected within all queries (unless not required).
     *
     * @return  List of Contact SObjectField tokens included in every standard query
     */
    public override List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField>{
            Contact.Email,
            Contact.FirstName,
            Contact.Id,
            Contact.LastName,
            Contact.Phone
        };
    }

    // ============================================================================
    // QUERY METHODS
    // ============================================================================

    /**
     * Select all Contacts matching any of the given email addresses (case-insensitive by SOQL).
     *
     * @param emails    Email addresses to match on
     * @return          List of Contact records with a matching Email
     */
    public List<Contact> selectByEmails( Set<String> emails ){
        dfflib_QueryFactory qf = newQueryFactory( true );
        qf.setCondition( 'Email IN :emails' );

        return this.executeQuery( qf, new Map<String, Object>{
            'emails' => emails
        } );
    }
}
