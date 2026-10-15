/**
 * Copyright (c), Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
/**
 * Application class to centralise access to core fflib factories.
 * Ensuring the metadata-driven layer initiation is correctly linked. 
 */
@NamespaceAccessible
public with sharing class fflib{

    /**
     * FFLIB CONFIG
     */

    /**
     * Unit Of Work - sequence: order of execution, taking into account the object dependencies during DML updates
     */
    public static final fflib_Application.UnitOfWorkFactory unitOfWork = new fflib_Application.UnitOfWorkFactory();

    /**
     * Selectors - sequence: alphabetic, mapping SObjectType to SEL class
     */
    public static final fflib_Application.SelectorFactory selector = new fflib_Application.SelectorFactory();

    /**
     * Domains - sequence: alphabetic, mapping the SObjectType to DOM layer
     */
    public static final fflib_Application.DomainFactory domain = new fflib_Application.DomainFactory( selector );

    /**
     * Services - sequence: alphabetic, mapping the classes to allow mocking
     */
    public static final fflib_Application.ServiceFactory service = new fflib_Application.ServiceFactory();
}