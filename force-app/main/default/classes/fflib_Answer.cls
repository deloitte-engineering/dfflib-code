/**
 * Copyright (c), FinancialForce.com, inc
 * Copyright (c), Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
/**
 * Interface for the answering framework.
 * This interface must be implemented inside the test class and implement the call back method answer.
 *
 * @group Core
 */
public interface fflib_Answer{

    /**
     * Method to be implemented in the test class to implement the call back method.
     *
     * @param   invocation  The invocation on the mock.
     * @throws  The exception to be thrown.
     * @return  The value to be returned.
     */
    Object answer( fflib_InvocationOnMock invocation );
}
