/**
 * Copyright (c), Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
/**
 * Main application utility class for common functionalities, fflib structure setup.
 *
 * Common functionalities:
 * - Input parameter checking
 * - Exception Handling
 *
 * FFLIB Structure setup:
 * - Returning correct business implementation for UnitOfWork, Service, Selector and Domain Layers within the application
 *
 */
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

    /**
     * COMMON EXCEPTIONS - to prevent custom exceptions per class
     */
    public class InvalidImplementationException extends Exception{}
    public class InvalidInputValueException extends Exception{}
    public class MissingDataException extends Exception{}
}
