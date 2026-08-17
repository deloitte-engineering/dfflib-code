/**
 * Copyright (c), Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
/**
 * Class that defines an interface to the DML proxy servicing the Unit of Work implementation to be compatible with apex-mock framework
 *
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
