/**
 * Copyright (c), FinancialForce.com, inc
 * Copyright (c), Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
@NamespaceAccessible
public interface fflib_IDomainFactory{
	fflib_IDomain newInstance( Set<Id> recordIds );
	fflib_IDomain newInstance( List<SObject> records );
	fflib_IDomain newInstance( List<Object> objects, Object objectType );
	fflib_IDomain newInstance( List<SObject> records, SObjectType domainSObjectType );
}