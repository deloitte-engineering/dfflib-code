/**
 * Copyright (c) 2019, Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
/**
 * Centralised utility class for common validation and exception handling functionalities.
 * Intended as a standalone dependency for all packages, to avoid duplication and encourage reuse.
 *
 * Common functionalities:
 * - Input parameter checking
 * - Exception Handling
 */
@NamespaceAccessible
public with sharing class dfflib_Utils{

    /**
     * VALIDATION UTILITIES
     */
    /**
     * Method to verify whether the input parameter is not null
     *
     * @param   param           The parameter to validate
     * @param   paramName       The parameter name to display in case the parameter is invalid
     */
    @NamespaceAccessible
    public static void verifyNotNull( Object param, String paramName ){
        if( param == null ){
            throw new InvalidInputValueException( message( '{0} cannot be null', paramName ) );
        }
    }

    /**
     * Method to verify whether the input parameter is not blank
     *
     * @param   param           The parameter to validate
     * @param   paramName       The parameter name to display in case the parameter is invalid
     */
    @NamespaceAccessible
    public static void verifyNotBlank( String param, String paramName ){
        if( String.isBlank( param ) ){
            throw new InvalidInputValueException( message( '{0} cannot be blank', paramName ) );
        }
    }

    /**
     * Method to verify whether the input list is not null nor empty
     *
     * @param   objList         The list to validate
     * @param   paramName       The parameter name to display in case the parameter is invalid
     */
    @NamespaceAccessible
    public static void verifyNotEmpty( List<Object> objList, String paramName ){
        if( objList == null || objList.isEmpty() ){
            throw new InvalidInputValueException( message( '{0} cannot be empty', paramName ) );
        }
    }

    /**
     * Method to shortcut the String.format call when having only one parameter to be substituted
     *
     * @param   message             The message to be formatted
     * @param   substitutionString  The substitution string to replace in the original message
     * @return  String where {0} in message variable is substituted with substitutionString
     */
    @NamespaceAccessible
    public static String message( String message, String substitutionString ){
        return String.format( message, new List<String>{ substitutionString } );
    }

    /**
     * COMMON EXCEPTIONS - to prevent custom exceptions per class
     */
    public class InvalidImplementationException extends Exception{}
    public class InvalidInputValueException extends fflib_Objects.InvalidValueException{}
    public class MissingDataException extends Exception{}
}