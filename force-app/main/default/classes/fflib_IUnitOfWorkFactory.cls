/**
 * Copyright (c), FinancialForce.com, inc
 * Copyright (c), Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
@NamespaceAccessible
public interface fflib_IUnitOfWorkFactory{
	fflib_ISObjectUnitOfWork newInstance();
	fflib_ISObjectUnitOfWork newInstance(fflib_SObjectUnitOfWork.IDML dml);
	fflib_ISObjectUnitOfWork newInstance(List<SObjectType> objectTypes);
	fflib_ISObjectUnitOfWork newInstance(List<SObjectType> objectTypes, fflib_SObjectUnitOfWork.IDML dml);
}