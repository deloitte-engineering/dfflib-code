/**
 * Copyright (c), FinancialForce.com, inc
 * Copyright (c) 2019, Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
@NamespaceAccessible
@SuppressWarnings('PMD.ClassNamingConventions')
public interface fflib_IMatcher{
    /**
     * Whether or not the supplied argument is a match.
     * Any supplementary information (e.g. boundary conditions, objects to match to etc)
     * should be cached by the matcher constructor.
     * @param arg The argument value supplied to the method
     * @return Boolean True if the argument value is a match, false otherwise.
     */
    Boolean matches(Object arg);
}