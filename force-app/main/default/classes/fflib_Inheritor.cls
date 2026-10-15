/**
 * Copyright (c), FinancialForce.com, inc
 * Copyright (c), Deloitte Consultative Services B.V.
 * SPDX-License-Identifier: BSD-3-Clause
 * See LICENSE in the repository root for the full license text.
 */
@IsTest( isParallel = true )
@NamespaceAccessible
@SuppressWarnings('PMD.ClassNamingConventions, PMD.ApexDoc')
public with sharing class fflib_Inheritor implements IA, IB, IC{
    public interface IA {String doA();}
    public interface IB {String doB();}
    public interface IC {String doC();}
    
    public String doA(){return 'Did A';}
    public String doB(){return 'Did B';}
    public String doC(){return 'Did C';}
}