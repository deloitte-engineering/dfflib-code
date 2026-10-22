/**
 * Copyright (c), FinancialForce.com, inc
 * Copyright (c) 2019, Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
/**
 * Class defining a method return value.
 */
@IsTest( isParallel=true )
@NamespaceAccessible
@SuppressWarnings('PMD.ClassNamingConventions, PMD.FieldNamingConventions, PMD.PropertyNamingConventions, PMD.ApexDoc')
public with sharing class fflib_MethodReturnValue{
    private StandardAnswer basicAnswer = new StandardAnswer();

    /**
     * Instance of the implementation of the Answer interface that implements the answer,
     * if an answer isn't explicitly set the standard answer will be used, which just returns the stubbed return value.
     */
    public fflib_Answer answer { get; set; }

    /**
     * Setup a stubbed return value.
     *
     * @param   value   The value to return from the stubbed method call.
     * @return  The fflib_MethodReturnValue instance to allow you to chain the methods.
     */
    @NamespaceAccessible
    public fflib_MethodReturnValue thenReturn( Object value ){
        thenAnswer( this.basicAnswer.setValue( value ) );
        return this;
    }

    /**
     * Setup a stubbed exception.
     *
     * @param   e   The exception to throw from the stubbed method call.
     * @return  The fflib_MethodReturnValue instance to allow you to chain the methods.
     */
    @NamespaceAccessible
    public fflib_MethodReturnValue thenThrow( Exception e ){
        thenAnswer( this.basicAnswer.setValue( e ) );
        return this;
    }

    /**
     * Setup a stubbed answer.
     *
     * @param   answer  The answer to run from the stubbed method call.
     */
    @NamespaceAccessible
    public void thenAnswer( fflib_Answer answer ){
        this.answer = answer;
    }

    /**
     * Setup a list of stubbed return values.
     *
     * @param   values  The values to return from the stubbed method call in consecutive calls.
     * @return  The fflib_MethodReturnValue instance to allow you to chain the methods.
     */
    @NamespaceAccessible
    public fflib_MethodReturnValue thenReturnMulti( List<Object> values ){
        thenAnswer( this.basicAnswer.setValues( values ) );
        return this;
    }

    /**
     * Setup a list stubbed exceptions.
     *
     * @param   es  The exceptions to throw from the stubbed method call in consecutive calls.
     * @return  The fflib_MethodReturnValue instance to allow you to chain the methods.
     */
    @NamespaceAccessible
    public fflib_MethodReturnValue thenThrowMulti( List<Exception> es ){
        thenAnswer( this.basicAnswer.setValues( es ) );
        return this;
    }

    /**
     * Inner class to handle all the stubs that do not use the thenAnswer method directly.
     * For internal use only.
     */
    @NamespaceAccessible
    public class StandardAnswer implements fflib_Answer{
        private Integer whichStubReturnIndex = 0;

        /**
         * It stores the return values for the method stubbed.
         * The values would be stored and then returned as part of the standard answer invocation.
         */
        private List<Object> ReturnValues = new List<Object>();

        /**
         * Setter of a single return value.
         *
         * @param   value   The value to be set as return value for the StandardAnswer object.
         * @return  The StandardAnswer instance.
         */
        public StandardAnswer setValue( Object value ){
            ReturnValues.add( value );
            return this;
        }

        /**
         * Setter of the list of return values.
         *
         * @param   values   List<Object> representing the values to be set as return value for the StandardAnswer object.
         * @return  The StandardAnswer instance.
         */
        public StandardAnswer setValues( List<Object> values ){
            if( values == null || values.size() == 0 ){
                throw new fflib_ApexMocks.ApexMocksException(
                    'The stubbing is not correct, no return values have been set.' );
            }

            ReturnValues.addAll( values );
            return this;
        }

        /**
         * Standard basic implementation for the fflib_Answer answer method, to be used as default answering.
         *
         * @param   invocation  The invocation to answer for.
         * @return  The ReturnValue for the method stubbed.
         */
        public Object answer( fflib_InvocationOnMock invocation ){
            if( ReturnValues == null || ReturnValues.size() == 0 ){
                throw new fflib_ApexMocks.ApexMocksException(
                    'The stubbing is not correct, no return values have been set.' );
            }

            Integer returnValuesSize = ReturnValues.size() - 1;

            if( whichStubReturnIndex < returnValuesSize ){
                return ReturnValues[ whichStubReturnIndex++ ];
            } else{
                return ReturnValues[ returnValuesSize ];
            }
        }
    }
}