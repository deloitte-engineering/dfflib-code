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
 * This class implements the actual verification.
 * @group Core
 */
public abstract class fflib_MethodVerifier{

    /**
     * Verify a method was called on a mock object.
     *
     * @param   mockInvocation      The object holding all the data of the invocation, like the method and arguments and the mock instance.
     * @param   verificationMode    The verification mode that holds the setting about how the verification should be performed.
     */
    public void verifyMethodCall( fflib_InvocationOnMock mockInvocation, fflib_VerificationMode verificationMode ){
        validateMode( verificationMode );

        verify( mockInvocation.getMethod(), mockInvocation.getMethodArgValues(), verificationMode );
    }

    /**
     * Method that actually performs the verify.
     *
     * @param   qualifiedMethod         The method to be verified.
     * @param   methodArg               The arguments of the method that needs to be verified.
     * @param   verificationMode        The verification mode that holds the setting about how the verification should be performed.
     */
    protected abstract void verify( fflib_QualifiedMethod qualifiedMethod, fflib_MethodArgValues methodArg, fflib_VerificationMode verificationMode );

    /**
     * Method that validates the verification mode used in the verify.
     * Not all the methods from the fflib_VerificationMode are implemented for the different classes that extends the fflib_MethodVerifier.
     * The error is thrown at run time, so this method is called in the method that actually performs the verify.
     *
     * @param   verificationMode    The verification mode that has to have been verified.
     * @throws  Exception with message for the fflib_VerificationMode not implemented.
     */
    protected abstract void validateMode( fflib_VerificationMode verificationMode );

    /**
     * Method that performs the argument capturing.
     * Captures argument values during verification.
     *
     * @param   matchers    The list of matcher with which a method is verified.
     */
    protected void capture( List<fflib_IMatcher> matchers ){
        for( fflib_IMatcher matcher : matchers ){
            if( matcher instanceof fflib_ArgumentCaptor.AnyObject ){
                ( ( fflib_ArgumentCaptor.AnyObject ) matcher ).storeArgument();
            }
        }
    }

    /**
     * Method that triggers an exception describing the behavior of a qualified method. It constructs a detailed description,
     * based on multiple parameters, of the differences between the qualified method and a set of matchers used to verify
     * the method's behaviour
     *
     * @param   qualifiedMethod             The method to verify
     * @param   inOrder                     String representing the order
     * @param   expectedCount               Expected number of times the method should be called
     * @param   qualifier                   Qualified expected count, in case there is
     * @param   methodCount                 Actual number of times the method is called
     * @param   customAssertMessage         A custom assert message
     * @param   expectedArguments           Expected method arguments
     * @param   expectedMatchers            Method matchers
     * @param   actualArguments             Actual arguments provided to the method
     * @throws  fflib_ApexMocks.ApexMocksException containing the above description
     */
    protected void throwException( fflib_QualifiedMethod qualifiedMethod, String inOrder, Integer expectedCount, String qualifier, Integer methodCount,
        String customAssertMessage,
        fflib_MethodArgValues expectedArguments,
        List<fflib_IMatcher> expectedMatchers,
        List<fflib_MethodArgValues> actualArguments ){
        String template = 'EXPECTED COUNT: {0}{1}{2}' // Qualified expected count (e.g. "3 or fewer times in order")
            + '\nACTUAL COUNT: {3}' // Actual count
            + '\nMETHOD: {4}' // Method signature
            + '{5}'; // Custom assert message

        String expectedDescription = '';
        String actualDescription = '';

        if( qualifiedMethod.hasArguments() ){
            template += '\n---' // Separator
                + '\nACTUAL ARGS: {6}' // Actual args
                + '\n---' // Separator
                + '\nEXPECTED ARGS: {7}'; // Matcher descriptions

            if( expectedMatchers == null ){
                expectedDescription = describe( expectedArguments );
            } else{
                expectedDescription = describe( expectedMatchers );
            }
            actualDescription = describe( actualArguments );
        }

        String message = String.format( template, new List<String>{
            '' + expectedCount,
            String.isBlank( qualifier ) ? '' : ( '' + qualifier ),
            inOrder,
            '' + methodCount,
            '' + qualifiedMethod,
            String.isBlank( customAssertMessage ) ? '' : ( '\n' + customAssertMessage ),
            actualDescription,
            expectedDescription
        } );

        throw new fflib_ApexMocks.ApexMocksException( message );
    }

    private static String describe( List<fflib_IMatcher> matchers ){
        List<String> descriptions = new List<String>();
        for( fflib_IMatcher matcher : matchers ){
            descriptions.add( '' + matcher );
        }

        return String.join( descriptions, ', ' );
    }

    private static String describe( List<fflib_MethodArgValues> valuesFromAllInvocations ){
        List<String> descriptions = new List<String>();
        if( valuesFromAllInvocations != null ){
            for( fflib_MethodArgValues valuesFromOneInvocation : valuesFromAllInvocations ){
                descriptions.add( describe( valuesFromOneInvocation ) );
            }
        }

        return '(' + String.join( descriptions, '), (' ) + ')';
    }

    private static String describe( fflib_MethodArgValues values ){
        List<String> descriptions = new List<String>();
        for( Object value : values.argValues ){
            try{
                // Attempt to JSON serialize - that way it doesn't truncate SObject fields etc.
                // Bear in mind that something are not JSON serializable, e.g. things with circular references.
                descriptions.add( JSON.serialize( value ) );
            } catch( Exception error ){
                descriptions.add( '' + value );
            }
        }

        return String.join( descriptions, ', ' );
    }
}