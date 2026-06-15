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
 * No parallel testing flag set since DML operations aren't permitted on the User SObjectType.
 */
@IsTest
private with sharing class fflib_SecurityUtilsTest{

    @TestSetup
    private static void testSetup(){
        // Create a Permission Set that grants "Read" access to Account, Contact and Lead.
        PermissionSet ps = new PermissionSet( Label = 'Read Only Permission Set', Name = 'ReadOnlyPermissionSet' );
        insert ps;

        // Grant Read access to the SObjects for CRUD tests
        List<ObjectPermissions> objectPerms = new List<ObjectPermissions>();
        objectPerms.add( createObjectPermissions( ps.Id, 'Account', false, true, false, false ) );
        objectPerms.add( createObjectPermissions( ps.Id, 'Contact', false, true, false, false ) );
        objectPerms.add( createObjectPermissions( ps.Id, 'Lead', false, true, false, false ) );
        insert objectPerms;

        // Grant Read/Edit access to the SObject fields FLS tests
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

    private static User setupTestUser( String profileName ){
        Profile p;
        p = getProfile( profileName );

        //Username global uniqueness is still enforced in tests
        //Make sure we get something unique to avoid issues with parallel tests
        String uniqueness = Datetime.now() + ':' + Math.random();
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

        return usr;
    }

    private static User assignPermissionSet( String permissionSetName, User usr ){
        PermissionSet ps = [ SELECT Id FROM PermissionSet WHERE Name = :permissionSetName ];
        PermissionSetAssignment psa = new PermissionSetAssignment( AssigneeId = usr.Id, PermissionSetId = ps.Id );
        insert psa;
        return usr;
    }

    @IsTest
    private static void readonly_field_access(){
        User testUser = assignPermissionSet( 'ReadOnlyPermissionSet', setupTestUser( 'Minimum Access - Salesforce' ) );
        System.runAs( testUser ){
            {
                fflib_SecurityUtils.SecurityException ex;
                try{
                    fflib_SecurityUtils.checkFieldIsInsertable( Account.SObjectType, 'Name' );
                } catch( fflib_SecurityUtils.SecurityException e ){
                    ex = e;
                }
                System.Assert.isNotNull( ex, 'Minimum Access - Salesforce profile should not be able to insert Account.Name' );
                System.Assert.isInstanceOfType( ex, fflib_SecurityUtils.FlsException.class, 'Expected an FlsException, got ' + ex.getTypeName() );
            }
            {
                fflib_SecurityUtils.SecurityException ex;
                try{
                    fflib_SecurityUtils.checkFieldIsReadable( Contact.SObjectType, 'LastName' );
                } catch( fflib_SecurityUtils.SecurityException e ){
                    ex = e;
                }
                System.Assert.isNull( ex, 'Minimum Access - Salesforce profile should be able to read Contact.LastName' );
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
            { //No exceptions, despite no rights
                fflib_SecurityUtils.checkFieldIsInsertable( Account.SObjectType, 'Name' );
                fflib_SecurityUtils.checkFieldIsReadable( Contact.SObjectType, 'LastName' );
                fflib_SecurityUtils.checkFieldIsUpdateable( Lead.SObjectType, 'Company' );
            }
        }
    }

    @IsTest
    private static void readonly_object_access(){
        User testUser = assignPermissionSet( 'ReadOnlyPermissionSet', setupTestUser( 'Minimum Access - Salesforce' ) );
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
                System.Assert.isNull( ex, 'Minimum Access - Salesforce profile should be able to read Contact' );
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
            { //No exceptions, despite no rights
                fflib_SecurityUtils.checkObjectIsInsertable( Account.SObjectType );
                fflib_SecurityUtils.checkObjectIsReadable( Contact.SObjectType );
                fflib_SecurityUtils.checkObjectIsUpdateable( Lead.SObjectType );
                fflib_SecurityUtils.checkObjectIsDeletable( Opportunity.SObjectType );
            }
        }
    }

    @IsTest
    private static void readonly_objectAndField_access(){
        User testUser = assignPermissionSet( 'ReadOnlyPermissionSet', setupTestUser( 'Minimum Access - Salesforce' ) );
        System.runAs( testUser ){
            {
                fflib_SecurityUtils.SecurityException ex;
                try{
                    fflib_SecurityUtils.checkInsert(
                        Account.SObjectType,
                        new List<String>{
                            'Name',
                            'ParentId',
                            'OwnerId'
                        }
                    );
                } catch( fflib_SecurityUtils.SecurityException e ){
                    ex = e;
                }
                System.Assert.isNotNull( ex, 'Minimum Access - Salesforce profile should not be able to insert Account' );
                System.Assert.isInstanceOfType( ex, fflib_SecurityUtils.CrudException.class, 'Expected an CrudException, got ' + ex.getTypeName() );
            }
            {
                fflib_SecurityUtils.SecurityException ex;
                try{
                    fflib_SecurityUtils.checkRead(
                        Contact.SObjectType,
                        new List<String>{
                            'LastName',
                            'Email',
                            'BirthDate'
                        }
                    );
                } catch( fflib_SecurityUtils.SecurityException e ){
                    ex = e;
                }
                System.Assert.isNull( ex, 'Minimum Access - Salesforce profile should be able to read Contact' );
            }
            {
                fflib_SecurityUtils.SecurityException ex;
                try{
                    fflib_SecurityUtils.checkUpdate(
                        Lead.SObjectType,
                        new List<String>{
                            'LastName',
                            'FirstName',
                            'Company'
                        }
                    );
                } catch( fflib_SecurityUtils.SecurityException e ){
                    ex = e;
                }
                System.Assert.isNotNull( ex, 'Minimum Access - Salesforce profile should not be able to update Lead' );
                System.Assert.isInstanceOfType( ex, fflib_SecurityUtils.CrudException.class, 'Expected an CrudException, got ' + ex.getTypeName() );
            }

            fflib_SecurityUtils.BYPASS_INTERNAL_FLS_AND_CRUD = true;
            { //no exceptions, despite no rights
                fflib_SecurityUtils.checkInsert(
                    Account.SObjectType,
                    new List<String>{
                        'Name',
                        'Type',
                        'OwnerId'
                    }
                );
                fflib_SecurityUtils.checkRead(
                    Contact.SObjectType,
                    new List<String>{
                        'LastName',
                        'AccountId',
                        'OwnerId'
                    }
                );
                fflib_SecurityUtils.checkUpdate(
                    Lead.SObjectType,
                    new List<String>{
                        'LastName',
                        'FirstName',
                        'Company'
                    }
                );
            }
        }
    }

    @IsTest
    private static void sysadmin_objectAndField_access(){
        User testUser = setupTestUser( 'System Administrator' );
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
        User testUser = setupTestUser( 'Minimum Access - Salesforce' );
        System.runAs( testUser ){
            {
                fflib_SecurityUtils.SecurityException ex;
                try{
                    fflib_SecurityUtils.checkFieldIsInsertable( Account.SObjectType, 'Name' );
                } catch( fflib_SecurityUtils.SecurityException e ){
                    ex = e;
                }
                System.Assert.isNotNull( ex, 'Minimum Access - Salesforce profile should not be able to insert Account.Name' );
                System.Assert.isInstanceOfType( ex, fflib_SecurityUtils.FlsException.class, 'Expected an FlsException, got ' + ex.getTypeName() );
            }
            {
                fflib_SecurityUtils.SecurityException ex;
                try{
                    fflib_SecurityUtils.checkFieldIsReadable( Contact.SObjectType, 'LastName' );
                } catch( fflib_SecurityUtils.SecurityException e ){
                    ex = e;
                }
                System.Assert.isNotNull( ex, 'Minimum Access - Salesforce profile should be able to read Contact.LastName' );
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
        User testUser = setupTestUser( 'Minimum Access - Salesforce' );
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