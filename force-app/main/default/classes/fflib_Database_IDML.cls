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
 *//**
 * Class that defines an interface to the DML proxy servicing the Unit of Work implementation to be compatible with apex-mock framework
 *
 *  @created    February 2023
 */
public interface fflib_Database_IDML{
    /**
     * Method template for executing DML actions on the behalf of the callee (aka Unit of Work instance).
     * Depending on provided DMLActions additional DMLOptions or AllOrNone can be defined
     *
     * @param   action          DML action to be executed. For more information, check {@link fflib_SObjectUnitOfWork.DMLActions}
     * @param   objList         List<SObject> for which the Database operation should be registered with
     * @param   options         Specifies additional data for the transaction, such as assignment rule information or
     *                          rollback behavior when errors occur during record insertions (only for inserts & updates)
     * @param   allOrNone       Specifies whether the operation allows partial success. If specified as false and a record fails,
     *                          the remainder of the DML operation can still succeed (only for deletes & undeletes)
     * @param   accessLevel     AccessLevel specified for the Database operations to execute in
     * @return  List<SaveResults> SaveResults from DML operation returned by underlying Database method
     */
    List<Object> performDMLAction( fflib_SObjectUnitOfWork.DMLActions action, List<SObject> objList, Database.DMLOptions options, AccessLevel accessLevel );
    List<Object> performDMLAction( fflib_SObjectUnitOfWork.DMLActions action, List<SObject> objList, Boolean allOrNone, AccessLevel accessLevel );
    List<Object> performDMLAction( fflib_SObjectUnitOfWork.DMLActions action, List<SObject> objList, AccessLevel accessLevel );

    /**
     * Method template for executing non-SObject specific Database operations such as Email or Approval Process submissions
     *
     * @param   operation       The Operation to be executed. For more information, check {@link fflib_SObjectUnitOfWork.Operations}
     * @param   objList         List<Object> for which the Operation should be performed
     * @return  List<Object> SaveResults returned by called Operation
     */
    List<Object> performOperation( fflib_SObjectUnitOfWork.Operations operation, List<Object> objList );
}