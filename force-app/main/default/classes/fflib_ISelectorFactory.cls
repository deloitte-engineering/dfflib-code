/**
 * Copyright (c), FinancialForce.com, inc
 * Copyright (c) 2019, Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
@NamespaceAccessible
public interface fflib_ISelectorFactory{
	fflib_ISObjectSelector newInstance( SObjectType sObjectType );
	List<SObject> selectById( Set<Id> recordIds );
	List<SObject> selectByRelationship( List<SObject> relatedRecords, SObjectField relationshipField );
}