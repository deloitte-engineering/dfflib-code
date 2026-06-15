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
 * 'Classic' invocation verifier - checks that a method was called with the given arguments the expected number of times.
 * The order of method calls is not important.
 */
public class fflib_AnyOrder extends fflib_MethodVerifier{

    /**
     * Verifies a method was invoked the expected number of times, with the expected arguments.
     *
     * @param   qualifiedMethod     The method to be verified.
     * @param   expectedArguments   The arguments of the method that needs to be verified.
     * @param   verificationMode    The verification mode that holds the setting about how the verification should be performed.
     */
    protected override void verify( fflib_QualifiedMethod qualifiedMethod, fflib_MethodArgValues expectedArguments, fflib_VerificationMode verificationMode ){
        List<fflib_IMatcher> expectedMatchers = fflib_Match.Matching ? fflib_Match.getAndClearMatchers( expectedArguments.argValues.size() ) : null;
        List<fflib_MethodArgValues> actualArguments = fflib_MethodCountRecorder.getMethodArgumentsByTypeName().get( qualifiedMethod );

        Integer methodCount = getMethodCount( expectedArguments, expectedMatchers, actualArguments );
        String qualifier = '';
        Integer expectedCount = null;

        if( ( verificationMode.verifyMin == verificationMode.verifyMax ) && methodCount != verificationMode.verifyMin ){
            expectedCount = verificationMode.verifyMin;
        } else if( verificationMode.verifyMin != null && verificationMode.verifyMin > methodCount ){
            expectedCount = verificationMode.verifyMin;
            qualifier = ' or more times';
        } else if( verificationMode.verifyMax != null && verificationMode.verifyMax < methodCount ){
            expectedCount = verificationMode.verifyMax;
            qualifier = ' or fewer times';
        }

        if( expectedCount != null ){
            throwException( qualifiedMethod, '', expectedCount, qualifier, methodCount, verificationMode.customAssertMessage,
                expectedArguments, expectedMatchers, actualArguments
            );
        }
    }

    /**
     * Method that records the number of times a method is correctly called, by comparing all supplied method arg values
     * to the supplied target matchers. In case no matchers are supplied, it simply compares the supplied method arg values
     * with expected values
     *
     * @param   methodArg       The arguments of the method that needs to be verified
     * @param   matchers        List of matchers to validate against
     * @param   methodArgs      The arguments that were actually provided
     * @return  Number of times a method is correctly called with a set of arguments, behavior that is asserted by a set of matchers
     */
    private Integer getMethodCount( fflib_MethodArgValues methodArg, List<fflib_IMatcher> matchers, List<fflib_MethodArgValues> methodArgs ){
        Integer retval = 0;

        if( methodArgs != null ){
            if( matchers != null ){
                for( fflib_MethodArgValues args : methodArgs ){
                    if( fflib_Match.matchesAllArgs( args, matchers ) ){
                        capture( matchers );
                        retval++;
                    }
                }
            } else{
                return countCalls( methodArgs, methodArg );
            }
        }

        return retval;
    }

    /**
     * Method that records the number of times a method is correctly called, simply comparing the supplied method arg values
     * with expected values
     *
     * @param   methodArgs    The arguments of the method that needs to be verified
     * @param   methodArg     The arguments that were actually provided
     * @return  Number of times a method is correctly called with a set of arguments, behavior that is asserted by a set of matchers
     */
    private Integer countCalls( List<fflib_MethodArgValues> methodArgs, fflib_MethodArgValues methodArg ){
        Integer count = 0;

        for( fflib_MethodArgValues arg : methodArgs ){
            if( arg == methodArg ){
                count++;
            }
        }

        return count;
    }

    /**
     * Method that validate the verification mode used in the verify.
     * Not all the methods from the fflib_VerificationMode are implemented for the different classes that extends the fflib_MethodVerifier.
     * The error is thrown at run time, so this method is called in the method that actually performs the verify.
     *
     * @param   verificationMode    The verification mode that have to been verified.
     * @throws  Exception with message for the fflib_VerificationMode not implemented.
     */
    protected override void validateMode( fflib_VerificationMode verificationMode ){
        if( verificationMode.method == fflib_VerificationMode.ModeName.CALLS ){
            throw new fflib_ApexMocks.ApexMocksException( 'The calls() method is available only in the InOrder Verification.' );
        }
    }
}