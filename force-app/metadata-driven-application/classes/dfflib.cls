/**
 * Copyright (c) 2019, Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
/**
 * Application class to centralise access to core fflib factories.
 * Ensuring the metadata-driven layer initiation is correctly linked. 
 */
@NamespaceAccessible
public with sharing class dfflib{

    /**
     * FFLIB CONFIG
     */

    /**
     * Unit Of Work - sequence: order of execution, taking into account the object dependencies during DML updates
     */
    public static final dfflib_Application.UnitOfWorkFactory unitOfWork = new dfflib_Application.UnitOfWorkFactory();

    /**
     * Selectors - sequence: alphabetic, mapping SObjectType to SEL class
     */
    public static final dfflib_Application.SelectorFactory selector = new dfflib_Application.SelectorFactory();

    /**
     * Domains - sequence: alphabetic, mapping the SObjectType to DOM layer
     */
    public static final dfflib_Application.DomainFactory domain = new dfflib_Application.DomainFactory( selector );

    /**
     * Services - sequence: alphabetic, mapping the classes to allow mocking
     */
    public static final dfflib_Application.ServiceFactory service = new dfflib_Application.ServiceFactory();
}