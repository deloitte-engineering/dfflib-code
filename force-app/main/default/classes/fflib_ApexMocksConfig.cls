/**
 * Copyright (c), FinancialForce.com, inc
 * Copyright (c) 2019, Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
@IsTest
@NamespaceAccessible
@SuppressWarnings('PMD.AvoidBooleanMethodParameters, PMD.ClassNamingConventions, PMD.PropertyNamingConventions')
public class fflib_ApexMocksConfig{
    /**
     * When false, stubbed behaviour and invocation counts are shared among all test spies.
     * - See fflib_ApexMocksTest.thatMultipleInstancesCanBeMockedDependently
     * - This is the default for backwards compatibility.
     * When true, each test spy instance has its own stubbed behaviour and invocations.
     * - See fflib_ApexMocksTest.thatMultipleInstancesCanBeMockedIndependently
     */
    @NamespaceAccessible
    public static Boolean hasIndependentMocks {get; set;}

    static{
        hasIndependentMocks = false;
    }
}
