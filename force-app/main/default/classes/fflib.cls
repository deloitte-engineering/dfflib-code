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
 * Main application utility class for common functionalities, fflib structure setup.
 *
 * Common functionalities:
 * - Input parameter checking
 * - Exception Handling
 *
 * FFLIB Structure setup:
 * - Returning correct business implementation for UnitOfWork, Service, Selector and Domain Layers within the application
 *
 * @author      Reinier van den Assum (rvandenassum@deloitte.nl)
 * @created     June 2020
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