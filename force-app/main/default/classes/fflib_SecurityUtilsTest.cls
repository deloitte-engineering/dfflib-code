/**
 * Copyright (c), FinancialForce.com, inc
 * Copyright (c), Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
/**
 * No parallel testing flag set since DML operations aren't permitted on the User SObjectType.
 */
@IsTest
private with sharing class fflib_SecurityUtilsTest{

    @TestSetup
    private static void testSetup(){
        // #315 Create a Permission Set that grants "Read" access to Account, Contact and Lead. We will use this in
        // Spring '21 orgs that lack the "Read Only" Profile. See:
        // https://help.salesforce.com/articleView?id=release-notes.rn_profiles_and_perms_read_only_new.htm&release=230&type=5).
        PermissionSet ps = new PermissionSet( Label = 'Read Only Permission Set', Name = 'ReadOnlyPermissionSet' );
        insert ps;

        // Grant Read access to the SObjects we use for CRUD tests
        List<ObjectPermissions> objectPerms = new List<ObjectPermissions>();
        objectPerms.add( createObjectPermissions( ps.Id, 'Account', false, true, false, false ) );
        objectPerms.add( createObjectPermissions( ps.Id, 'Contact', false, true, false, false ) );
        objectPerms.add( createObjectPermissions( ps.Id, 'Lead', false, true, false, false ) );
        insert objectPerms;

        // Grant Read/Edit access to the SObject fields we use for FLS tests
        List<FieldPermissions> fieldPerms = new List<FieldPermissions>();
        fieldPerms.add( createFieldPermissions( ps.Id, 'Contact', 'BirthDate', true, false ) );
        fieldPerms.add( createFieldPermissions( ps.Id, 'Contact', 'Email', true, false ) );
        insert fieldPerms;
    }

    private static Profile getProfile( String profileName ){
        return [ SELECT Id, Name FROM Profile WHERE Name = :profileName ];
    }

    private static ObjectPermissions createObjectPermissions( Id permSetId, String objectType, Boolean canCreate, Boolean canRead, Boolean canUpdate, Boolean canDelete ){
        return new ObjectPermissions(
            ParentId = permSetId,
            SobjectType = objectType,
            PermissionsCreate = canCreate,
            PermissionsRead = canRead,
            PermissionsEdit = canUpdate,
            PermissionsDelete = canDelete
        );
    }

    private static FieldPermissions createFieldPermissions( Id permSetId, String objectType, String fieldName, Boolean canRead, Boolean canEdit ){
        return new FieldPermissions(
            ParentId = permSetId,
            SobjectType = objectType,
            Field = objectType + '.' + fieldName,
            PermissionsRead = canRead,
            PermissionsEdit = canEdit
        );
    }

    private static User setupTestUser( Boolean limitedAccess, Boolean grantReadAccess ){
        Profile p;

        if( limitedAccess ){
            try{
                p = getProfile( 'Minimum Access - Salesforce' );
            } catch( QueryException ex ){
                if( ex.getMessage().contains( 'List has no rows for assignment to SObject' ) ){
                    //#440 - not ideal, but we'll fall back to the rather liberally permissioned 'Read Only' profile that exists in very old orgs
                    p = getProfile( 'Read Only' );
                }
            }
        } else {
            p = getProfile( 'System Administrator' );
        }

        // Username global uniqueness is still enforced in tests
        // Make sure we get something unique to avoid issues with parallel tests
        String uniqueness = DateTime.now() + ':' + Math.random();
        try{
            throw new NullPointerException();
        } catch( Exception e ){
            uniqueness += e.getStackTraceString(); //includes the top level test method name without having to pass it
        }

        User usr = new User(
            Username = UserInfo.getUserId() + '.' + uniqueness.hashCode() + '@' + UserInfo.getOrganizationId() + '.sfdcOrg',
            Alias = 'testExec',
            Email = 'apextests@example.com',
            EmailEncodingKey = 'UTF-8',
            FirstName = 'FirstName',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles'
        );
        insert usr;

        if( limitedAccess && grantReadAccess ){
            // #315 We need to assign the Perm Set to grant Account "Read" access
            PermissionSet accountReadPS = [ SELECT Id FROM PermissionSet WHERE Name = 'ReadOnlyPermissionSet' ];
            PermissionSetAssignment psa = new PermissionSetAssignment( AssigneeId = usr.Id, PermissionSetId = accountReadPS.Id );
            insert psa;
        }
        return usr;
    }

    @IsTest
    private static void readonly_field_access(){
        User testUser = setupTestUser( true, true );
        System.runAs( testUser ){
            {
                fflib_SecurityUtils.SecurityException ex;
                try{
                    fflib_SecurityUtils.checkFieldIsInsertable( Account.SObjectType, 'naMe' );
                } catch( fflib_SecurityUtils.SecurityException e ){
                    ex = e;
                }
                System.Assert.isNotNull( ex, 'Read only profile should not be able to insert Account.Name' );
                System.Assert.isInstanceOfType( ex, fflib_SecurityUtils.FlsException.class, 'Expected an FlsException, got ' + ex.getTypeName() );
            }
            {
                fflib_SecurityUtils.SecurityException ex;
                try{
                    fflib_SecurityUtils.checkFieldIsReadable( Contact.SObjectType, 'LastNAME' );
                } catch( fflib_SecurityUtils.SecurityException e ){
                    ex = e;
                }
                System.Assert.isNull( ex, 'Read only profile should be able to read Contact.LastName' );
            }
            {
                fflib_SecurityUtils.SecurityException ex;
                try{
                    fflib_SecurityUtils.checkFieldIsUpdateable( Lead.SObjectType, 'cOMPANY' );
                } catch( fflib_SecurityUtils.SecurityException e ){
                    ex = e;
                }
                System.Assert.isNotNull( ex, 'Read only profile should not be able to update Lead.Company' );
                System.Assert.isInstanceOfType( ex, fflib_SecurityUtils.FlsException.class, 'Expected an FlsException, got ' + ex.getTypeName() );
            }

            fflib_SecurityUtils.BYPASS_INTERNAL_FLS_AND_CRUD = true;
            { // No exceptions, despite no rights
                fflib_SecurityUtils.checkFieldIsInsertable( Account.SObjectType, 'naMe' );
                fflib_SecurityUtils.checkFieldIsReadable( Contact.SObjectType, 'LastNAME' );
                fflib_SecurityUtils.checkFieldIsUpdateable( Lead.SObjectType, 'cOMPANY' );
            }
        }
    }

    @IsTest
    private static void readonly_object_access(){
        User testUser = setupTestUser( true, true );
        System.runAs( testUser ){
            {
                fflib_SecurityUtils.SecurityException ex;
                try{
                    fflib_SecurityUtils.checkObjectIsInsertable( Account.SObjectType );
                } catch( fflib_SecurityUtils.SecurityException e ){
                    ex = e;
                }
                System.Assert.isNotNull( ex, 'Read only profile should not be able to insert Account' );
                System.Assert.isInstanceOfType( ex, fflib_SecurityUtils.CrudException.class, 'Expected an CrudException, got ' + ex.getTypeName() );
            }
            {
                fflib_SecurityUtils.SecurityException ex;
                try{
                    fflib_SecurityUtils.checkObjectIsReadable( Contact.SObjectType );
                } catch( fflib_SecurityUtils.SecurityException e ){
                    ex = e;
                }
                System.Assert.isNull( ex, 'Read only profile should be able to read Contact' );
            }
            {
                fflib_SecurityUtils.SecurityException ex;
                try{
                    fflib_SecurityUtils.checkObjectIsUpdateable( Lead.SObjectType );
                } catch( fflib_SecurityUtils.SecurityException e ){
                    ex = e;
                }
                System.Assert.isNotNull( ex, 'Read only profile should not be able to update Lead' );
                System.Assert.isInstanceOfType( ex, fflib_SecurityUtils.CrudException.class, 'Expected an CrudException, got ' + ex.getTypeName() );
            }
            {
                fflib_SecurityUtils.SecurityException ex;
                try{
                    fflib_SecurityUtils.checkObjectIsDeletable( Opportunity.SObjectType );
                } catch( fflib_SecurityUtils.SecurityException e ){
                    ex = e;
                }
                System.Assert.isNotNull( ex, 'Read only profile should not be able to delete Opportunity' );
                System.Assert.isInstanceOfType( ex, fflib_SecurityUtils.CrudException.class, 'Expected an CrudException, got ' + ex.getTypeName() );
            }

            fflib_SecurityUtils.BYPASS_INTERNAL_FLS_AND_CRUD = true;
            { // No exceptions, despite no rights
                fflib_SecurityUtils.checkObjectIsInsertable( Account.SObjectType );
                fflib_SecurityUtils.checkObjectIsReadable( Contact.SObjectType );
                fflib_SecurityUtils.checkObjectIsUpdateable( Lead.SObjectType );
                fflib_SecurityUtils.checkObjectIsDeletable( Opportunity.SObjectType );
            }
        }
    }

    @IsTest
    private static void readonly_objectAndField_access(){
        User testUser = setupTestUser( true, true );
        System.runAs( testUser ){
            {
                fflib_SecurityUtils.SecurityException ex;
                try{
                    fflib_SecurityUtils.checkInsert(
                        Account.SObjectType,
                        new List<String>{
                            'Name',
                            'ParentId',
                            'ownerId'
                        }
                    );
                } catch( fflib_SecurityUtils.SecurityException e ){
                    ex = e;
                }
                System.Assert.isNotNull( ex, 'Read only profile should not be able to insert Account' );
                System.Assert.isInstanceOfType( ex, fflib_SecurityUtils.CrudException.class, 'Expected an CrudException, got ' + ex.getTypeName() );
            }
            {
                fflib_SecurityUtils.SecurityException ex;
                try{
                    fflib_SecurityUtils.checkRead(
                        Contact.SObjectType,
                        new List<String>{
                            'LastName',
                            'eMaiL',
                            'BirthDATE'
                        }
                    );
                } catch( fflib_SecurityUtils.SecurityException e ){
                    ex = e;
                }
                System.Assert.isNull( ex, 'Read only profile should be able to read Contact' );
            }
            {
                fflib_SecurityUtils.SecurityException ex;
                try{
                    fflib_SecurityUtils.checkUpdate(
                        Lead.SObjectType,
                        new List<String>{
                            'LastName',
                            'FirstNAMe',
                            'cOMPANY'
                        }
                    );
                } catch( fflib_SecurityUtils.SecurityException e ){
                    ex = e;
                }
                System.Assert.isNotNull( ex, 'Read only profile should not be able to update Lead' );
                System.Assert.isInstanceOfType( ex, fflib_SecurityUtils.CrudException.class, 'Expected an CrudException, got ' + ex.getTypeName() );
            }

            fflib_SecurityUtils.BYPASS_INTERNAL_FLS_AND_CRUD = true;
            { //no exceptions, despite no rights
                fflib_SecurityUtils.checkInsert(
                    Account.SObjectType,
                    new List<String>{
                        'Name',
                        'Type',
                        'ownerId'
                    }
                );
                fflib_SecurityUtils.checkRead(
                    Contact.SObjectType,
                    new List<String>{
                        'LastName',
                        'accountId',
                        'ownerId'
                    }
                );
                fflib_SecurityUtils.checkUpdate(
                    Lead.SObjectType,
                    new List<String>{
                        'LastName',
                        'FirstNAMe',
                        'cOMPANY'
                    }
                );
            }
        }
    }

    @IsTest
    private static void sysadmin_objectAndField_access(){
        User testUser = setupTestUser( false, false );
        System.runAs( testUser ){
            fflib_SecurityUtils.checkInsert(
                Account.SObjectType,
                new List<Schema.SObjectField>{
                    Account.SObjectType.fields.Name,
                    Account.SObjectType.fields.ParentId,
                    Account.SObjectType.fields.OwnerId
                }
            );
            fflib_SecurityUtils.checkRead(
                Contact.SObjectType,
                new List<Schema.SObjectField>{
                    Contact.SObjectType.fields.LastName,
                    Contact.SObjectType.fields.AccountId,
                    Contact.SObjectType.fields.OwnerId
                }
            );
            fflib_SecurityUtils.checkUpdate(
                Lead.SObjectType,
                new List<Schema.SObjectField>{
                    Lead.SObjectType.fields.LastName,
                    Lead.SObjectType.fields.FirstName,
                    Lead.SObjectType.fields.Company
                }
            );
        }
    }

    @IsTest
    private static void no_read_field_access(){
        User testUser = setupTestUser( true, false );
        System.runAs( testUser ){
            {
                fflib_SecurityUtils.SecurityException ex;
                try{
                    fflib_SecurityUtils.checkFieldIsInsertable( Account.SObjectType, 'Name' );
                } catch( fflib_SecurityUtils.SecurityException e ){
                    ex = e;
                }
                System.Assert.isNotNull( ex, 'Read only profile should not be able to insert Account.Name' );
                System.Assert.isInstanceOfType( ex, fflib_SecurityUtils.FlsException.class, 'Expected an FlsException, got ' + ex.getTypeName() );
            }
            {
                fflib_SecurityUtils.SecurityException ex;
                try{
                    fflib_SecurityUtils.checkFieldIsReadable( Contact.SObjectType, 'LastName' );
                } catch( fflib_SecurityUtils.SecurityException e ){
                    ex = e;
                }
                System.Assert.isNotNull( ex, 'Read only profile should not be able to read Contact.LastName' );
                System.Assert.isInstanceOfType( ex, fflib_SecurityUtils.FlsException.class, 'Expected an FlsException, got ' + ex.getTypeName() );
            }
            {
                fflib_SecurityUtils.SecurityException ex;
                try{
                    fflib_SecurityUtils.checkFieldIsUpdateable( Lead.SObjectType, 'Company' );
                } catch( fflib_SecurityUtils.SecurityException e ){
                    ex = e;
                }
                System.Assert.isNotNull( ex, 'Minimum Access - Salesforce profile should not be able to update Lead.Company' );
                System.Assert.isInstanceOfType( ex, fflib_SecurityUtils.FlsException.class, 'Expected an FlsException, got ' + ex.getTypeName() );
            }
            fflib_SecurityUtils.BYPASS_INTERNAL_FLS_AND_CRUD = true;
            { // No exceptions, despite no rights
                fflib_SecurityUtils.checkFieldIsInsertable( Account.SObjectType, 'Name' );
                fflib_SecurityUtils.checkFieldIsReadable( Contact.SObjectType, 'LastName' );
                fflib_SecurityUtils.checkFieldIsUpdateable( Lead.SObjectType, 'Company' );
            }
        }
    }

    @IsTest
    private static void no_read_object_access(){
        User testUser = setupTestUser( true, false );
        System.runAs( testUser ){
            {
                fflib_SecurityUtils.SecurityException ex;
                try{
                    fflib_SecurityUtils.checkObjectIsInsertable( Account.SObjectType );
                } catch( fflib_SecurityUtils.SecurityException e ){
                    ex = e;
                }
                System.Assert.isNotNull( ex, 'Minimum Access - Salesforce profile should not be able to insert Account' );
                System.Assert.isInstanceOfType( ex, fflib_SecurityUtils.CrudException.class, 'Expected an CrudException, got ' + ex.getTypeName() );
            }
            {
                fflib_SecurityUtils.SecurityException ex;
                try{
                    fflib_SecurityUtils.checkObjectIsReadable( Contact.SObjectType );
                } catch( fflib_SecurityUtils.SecurityException e ){
                    ex = e;
                }
                System.Assert.isNotNull( ex, 'Minimum Access - Salesforce profile should be able to read Contact' );
                System.Assert.isInstanceOfType( ex, fflib_SecurityUtils.CrudException.class, 'Expected an CrudException, got ' + ex.getTypeName() );
            }
            {
                fflib_SecurityUtils.SecurityException ex;
                try{
                    fflib_SecurityUtils.checkObjectIsUpdateable( Lead.SObjectType );
                } catch( fflib_SecurityUtils.SecurityException e ){
                    ex = e;
                }
                System.Assert.isNotNull( ex, 'Minimum Access - Salesforce profile should not be able to update Lead' );
                System.Assert.isInstanceOfType( ex, fflib_SecurityUtils.CrudException.class, 'Expected an CrudException, got ' + ex.getTypeName() );
            }
            {
                fflib_SecurityUtils.SecurityException ex;
                try{
                    fflib_SecurityUtils.checkObjectIsDeletable( Opportunity.SObjectType );
                } catch( fflib_SecurityUtils.SecurityException e ){
                    ex = e;
                }
                System.Assert.isNotNull( ex, 'Minimum Access - Salesforce profile should not be able to delete Opportunity' );
                System.Assert.isInstanceOfType( ex, fflib_SecurityUtils.CrudException.class, 'Expected an CrudException, got ' + ex.getTypeName() );
            }
            fflib_SecurityUtils.BYPASS_INTERNAL_FLS_AND_CRUD = true;
            { // No exceptions, despite no rights
                fflib_SecurityUtils.checkObjectIsInsertable( Account.SObjectType );
                fflib_SecurityUtils.checkObjectIsReadable( Contact.SObjectType );
                fflib_SecurityUtils.checkObjectIsUpdateable( Lead.SObjectType );
                fflib_SecurityUtils.checkObjectIsDeletable( Opportunity.SObjectType );
            }
        }
    }
}