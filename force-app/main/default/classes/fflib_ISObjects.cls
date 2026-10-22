/**
 * Copyright (c), FinancialForce.com, inc
 * Copyright (c) 2019, Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
@NamespaceAccessible
public interface fflib_ISObjects extends fflib_IObjects{
    /**
     * @return Return the SObject records contained in the domain
     */
    List<SObject> getRecords();

    /**
     * @return Return the SObject records ids contained in the domain
     */
    Set<Id> getRecordIds();

    /**
     * @return Return the SObjectType of the SObjects contained in the domain
     */
    SObjectType getSObjectType();
}
