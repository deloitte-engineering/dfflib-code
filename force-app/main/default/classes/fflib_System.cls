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
public class fflib_System{

    /**
     * Verifies that the supplied argument is meaningfully equivalent to the expected argument, as defined by its matcher.
     * See fflib_SystemTest for examples of usage.
     *
     * @param   ignoredRetVal   Dummy value, returned on registering an fflib_IMatcher.
     * @param   value           The object instance upon which we are checking equality.
     */
    public static void assertEquals( Object ignoredRetVal, Object value ){
        assertEquals( ignoredRetVal, value, null );
    }

    /**
     * Verifies that the supplied argument is meaningfully equivalent to the expected argument, as defined by its matcher.
     * See fflib_SystemTest for examples of usage.
     *
     * @param   ignoredRetVal           Dummy value, returned on registering an fflib_IMatcher.
     * @param   value                   The object instance upon which we are checking equality.
     * @param   customAssertMessage     Provides context or additional information for the assertion.
     */
    public static void assertEquals( Object ignoredRetVal, Object value, String customAssertMessage ){
        fflib_IMatcher matcher = null;
        try{
            List<fflib_IMatcher> matchers = fflib_Match.getAndClearMatchers( 1 );
            matcher = matchers[ 0 ];
        } catch( fflib_ApexMocks.ApexMocksException e ){
            throw new fflib_ApexMocks.ApexMocksException( 'System.Assert.areEqual() expects you to register exactly 1 fflib_IMatcher (typically through the helpers in fflib_Match).' );
        }

        if( !matcher.matches( value ) ){
            throw new fflib_ApexMocks.ApexMocksException( String.format( 'Expected : {0}, Actual: {1}{2}', new String[]{
                String.valueOf( matcher ),
                String.valueOf( value ),
                String.isBlank( customAssertMessage ) ? '' : ( ' -- ' + customAssertMessage )
            } ) );
        }
    }
}