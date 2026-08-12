/**
 * Copyright (c), FinancialForce.com, inc
 * Copyright (c), Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
public interface fflib_ISObjectDomain extends fflib_IDomain{

    /**
     * Return the SObjectType the Domain class represents.
     *
     * @return  SObjectType this Domain class represents.
     */
    Schema.SObjectType sObjectType();

    /**
     * Alternative to the Records property, provided to support mocking of Domain classes.
     *
     * @return  List<SObject> in context.
     */
    List<SObject> getRecords();
}
