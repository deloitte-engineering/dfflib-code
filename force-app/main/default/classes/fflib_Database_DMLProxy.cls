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
 */
/**
 * Centralised class to group all Database DML operations:
 * 1) Allowing to easily apply different database security models, through sharing modes and access levels (AccessLevel)
 * 2) Allowing optimal separation of concerns where UOW focuses on registration and fflib_Database_DMLProxy on database interactions
 *      This allows to simplify Test methods, and make the framework more environment-independent (test-classes not failing on added validations)
 *      Lastly, this enables unlocked packages where framework code is not needed to be touched by project developers
 *
 *  @author     Rafael Fernandes dos Santos (rfernandesdossantos@deloitte.nl)
 *  @created    February 2023
 */
public abstract class fflib_Database_DMLProxy{

    /**
     * Getter providing a DMLProxy implementation for the security enforcement model provided
     *
     * @param   securityContext     Database security context for DML operations to be executed on
     * @return  DMLProxy implementation for the security context provided
     */
    public static fflib_Database_IDML getDMLProxyImplementation( fflib_Database.Context securityContext ){
        return SECURITY_ENFORCEMENT_DML.get( securityContext );
    }

    /**
     * Database context models supported by the unit of work.
     */
    private final static Map<fflib_Database.Context, fflib_Database_IDML> SECURITY_ENFORCEMENT_DML = new Map<fflib_Database.Context, fflib_Database_IDML>{
        fflib_Database.Context.FULL => new WithSimpleDML(),
        fflib_Database.Context.SHARING_SKIP_PERMISSIONS => new WithSimpleDML(),
        fflib_Database.Context.NONE => new WithoutSimpleDML(),
        fflib_Database.Context.INHERIT => new InheritSimpleDML()
    };

    /**
     * All standard transactions will implement the security model when saving.
     */
    @TestVisible
    private with sharing class WithSimpleDML implements fflib_Database_IDML{
        public List<Object> performDMLAction( fflib_SObjectUnitOfWork.DMLActions action, List<SObject> objList, Database.DMLOptions options, AccessLevel accessLevel ){
            if( options != null && options.optAllOrNone != true ){
                System.debug( LoggingLevel.WARN, 'fflib - IMPORTANT: AllOrNone is FALSE, developer is responsible for handling save errors' );
            }

            switch on action{
                when dNEW, dNEW_PRIO{
                    return ( options == null ) ? Database.insert( objList, accessLevel ) : Database.insert( objList, options, accessLevel );
                }
                when dUPDATE, dUPDATE_PRIO{
                    return ( options == null ) ? Database.update( objList, accessLevel ) : Database.update( objList, options, accessLevel );
                }
                when else{
                    throw new InvalidDMLActionException( 'Invalid Action for DMLAction with DMLOptions ' + action );
                }
            }
        }

        public List<Object> performDMLAction( fflib_SObjectUnitOfWork.DMLActions action, List<SObject> objList, Boolean allOrNone, AccessLevel accessLevel ){
            if( !allOrNone ){
                System.debug( LoggingLevel.WARN, 'fflib - IMPORTANT: AllOrNone is FALSE, developer is responsible for handling save errors' );
            }

            switch on action{
                when dDELETE, dDELETE_PRIO{
                    return Database.delete( objList, allOrNone, accessLevel );
                }
                when dUNDELETE{
                    return Database.undelete( objList, allOrNone, accessLevel );
                }
                when else{
                    throw new InvalidDMLActionException( 'Invalid Action for DMLAction with AllOrNone Boolean ' + action );
                }
            }
        }

        public List<Object> performDMLAction( fflib_SObjectUnitOfWork.DMLActions action, List<SObject> objList, AccessLevel accessLevel ){
            if( objList != null && !objList.isEmpty() ){
                switch on action{
                    when dPUB_BEFORE, dPUB_AFTER_SUCCESS, dPUB_AFTER_FAILURE{
                        return EventBus.publish( objList );
                    }
                    when dEMPTY_RECBIN{
                        return Database.emptyRecycleBin( objList );
                    }
                    when dNEW_IMMEDIATE{
                        return Database.insertImmediate( objList, accessLevel );
                    }
                    when dUPDATE_IMMEDIATE{
                        return Database.updateImmediate( objList, accessLevel );
                    }
                    when dDELETE_IMMEDIATE{
                        return Database.deleteImmediate( objList, accessLevel );
                    }
                    when else{
                        throw new InvalidDMLActionException( 'Invalid Action for DMLAction without additional parameters ' + action );
                    }
                }
            }
            return null;
        }

        public List<Object> performOperation( fflib_SObjectUnitOfWork.Operations operation, List<Object> objList ){
            if( objList != null && !objList.isEmpty() ){
                // Per operation convert List<Any> to right format by looping per record to prevent "Invalid conversion" exception
                switch on operation{
                    when SEND_EMAIL{
                        List<Messaging.Email> emailList = new List<Messaging.Email>();
                        for( Integer i = 0, j = objList.size(); i < j; i++ ){
                            emailList.add( ( Messaging.Email ) objList[ i ] );
                        }
                        return Messaging.sendEmail( emailList );
                    }
                    when PROCESS_APPROVAL_PROCESS{
                        List<Approval.ProcessRequest> approvalList = new List<Approval.ProcessRequest>();
                        for( Integer i = 0, j = objList.size(); i < j; i++ ){
                            approvalList.add( ( Approval.ProcessRequest ) objList[ i ] );
                        }
                        return Approval.process( approvalList );
                    }
                    when else{
                        throw new InvalidDMLActionException( 'Invalid Operation ' + operation );
                    }
                }
            }
            return null;
        }
    }

    /**
     * Allows specific transactions to override the security model when saving.
     */
    @TestVisible
    private without sharing class WithoutSimpleDML implements fflib_Database_IDML{
        public List<Object> performDMLAction( fflib_SObjectUnitOfWork.DMLActions action, List<SObject> objList, Database.DMLOptions options, AccessLevel accessLevel ){
            if( options != null && options.optAllOrNone != true ){
                System.debug( LoggingLevel.WARN, 'fflib - IMPORTANT: AllOrNone is FALSE, developer is responsible for handling save errors' );
            }

            switch on action{
                when dNEW, dNEW_PRIO{
                    return ( options == null ) ? Database.insert( objList, accessLevel ) : Database.insert( objList, options, accessLevel );
                }
                when dUPDATE, dUPDATE_PRIO{
                    return ( options == null ) ? Database.update( objList, accessLevel ) : Database.update( objList, options, accessLevel );
                }
                when else{
                    throw new InvalidDMLActionException( 'Invalid Action for DMLAction with DMLOptions ' + action );
                }
            }
        }

        public List<Object> performDMLAction( fflib_SObjectUnitOfWork.DMLActions action, List<SObject> objList, Boolean allOrNone, AccessLevel accessLevel ){
            if( !allOrNone ){
                System.debug( LoggingLevel.WARN, 'fflib - IMPORTANT: AllOrNone is FALSE, developer is responsible for handling save errors' );
            }

            switch on action{
                when dDELETE, dDELETE_PRIO{
                    return Database.delete( objList, allOrNone, accessLevel );
                }
                when dUNDELETE{
                    return Database.undelete( objList, allOrNone, accessLevel );
                }
                when else{
                    throw new InvalidDMLActionException( 'Invalid Action for DMLAction with AllOrNone Boolean ' + action );
                }
            }
        }

        public List<Object> performDMLAction( fflib_SObjectUnitOfWork.DMLActions action, List<SObject> objList, AccessLevel accessLevel ){
            if( objList != null && !objList.isEmpty() && accessLevel != null ){
                switch on action{
                    when dPUB_BEFORE, dPUB_AFTER_SUCCESS, dPUB_AFTER_FAILURE{
                        return EventBus.publish( objList );
                    }
                    when dEMPTY_RECBIN{
                        return Database.emptyRecycleBin( objList );
                    }
                    when dNEW_IMMEDIATE{
                        return Database.insertImmediate( objList, accessLevel );
                    }
                    when dUPDATE_IMMEDIATE{
                        return Database.updateImmediate( objList, accessLevel );
                    }
                    when dDELETE_IMMEDIATE{
                        return Database.deleteImmediate( objList, accessLevel );
                    }
                    when else{
                        throw new InvalidDMLActionException( 'Invalid Action for DMLAction without additional parameters ' + action );
                    }
                }
            }
            return null;
        }

        public List<Object> performOperation( fflib_SObjectUnitOfWork.Operations operation, List<Object> objList ){
            if( objList != null && !objList.isEmpty() ){
                // Per operation convert List<Any> to right format by looping per record to prevent "Invalid conversion" exception
                switch on operation{
                    when SEND_EMAIL{
                        List<Messaging.Email> emailList = new List<Messaging.Email>();
                        for( Integer i = 0, j = objList.size(); i < j; i++ ){
                            emailList.add( ( Messaging.Email ) objList[ i ] );
                        }
                        return Messaging.sendEmail( emailList );
                    }
                    when PROCESS_APPROVAL_PROCESS{
                        List<Approval.ProcessRequest> approvalList = new List<Approval.ProcessRequest>();
                        for( Integer i = 0, j = objList.size(); i < j; i++ ){
                            approvalList.add( ( Approval.ProcessRequest ) objList[ i ] );
                        }
                        return Approval.process( approvalList );
                    }
                    when else{
                        throw new InvalidDMLActionException( 'Invalid Operation ' + operation );
                    }
                }
            }
            return null;
        }
    }

    /**
     * Inherits the sharing model when saving.
     */
    @TestVisible
    private inherited sharing class InheritSimpleDML implements fflib_Database_IDML{
        public List<Object> performDMLAction( fflib_SObjectUnitOfWork.DMLActions action, List<SObject> objList, Database.DMLOptions options, AccessLevel accessLevel ){
            if( options != null && options.optAllOrNone != true ){
                System.debug( LoggingLevel.WARN, 'fflib - IMPORTANT: AllOrNone is FALSE, developer is responsible for handling save errors' );
            }

            switch on action{
                when dNEW, dNEW_PRIO{
                    return ( options == null ) ? Database.insert( objList, accessLevel ) : Database.insert( objList, options, accessLevel );
                }
                when dUPDATE, dUPDATE_PRIO{
                    return ( options == null ) ? Database.update( objList, accessLevel ) : Database.update( objList, options, accessLevel );
                }
                when else{
                    throw new InvalidDMLActionException( 'Invalid Action for DMLAction with DMLOptions ' + action );
                }
            }
        }

        public List<Object> performDMLAction( fflib_SObjectUnitOfWork.DMLActions action, List<SObject> objList, Boolean allOrNone, AccessLevel accessLevel ){
            if( !allOrNone ){
                System.debug( LoggingLevel.WARN, 'fflib - IMPORTANT: AllOrNone is FALSE, developer is responsible for handling save errors' );
            }

            switch on action{
                when dDELETE, dDELETE_PRIO{
                    return Database.delete( objList, allOrNone, accessLevel );
                }
                when dUNDELETE{
                    return Database.undelete( objList, allOrNone, accessLevel );
                }
                when else{
                    throw new InvalidDMLActionException( 'Invalid Action for DMLAction with AllOrNone Boolean ' + action );
                }
            }
        }

        public List<Object> performDMLAction( fflib_SObjectUnitOfWork.DMLActions action, List<SObject> objList, AccessLevel accessLevel ){
            if( objList != null && !objList.isEmpty() && accessLevel != null ){
                switch on action{
                    when dPUB_BEFORE, dPUB_AFTER_SUCCESS, dPUB_AFTER_FAILURE{
                        return EventBus.publish( objList );
                    }
                    when dEMPTY_RECBIN{
                        return Database.emptyRecycleBin( objList );
                    }
                    when dNEW_IMMEDIATE{
                        return Database.insertImmediate( objList, accessLevel );
                    }
                    when dUPDATE_IMMEDIATE{
                        return Database.updateImmediate( objList, accessLevel );
                    }
                    when dDELETE_IMMEDIATE{
                        return Database.deleteImmediate( objList, accessLevel );
                    }
                    when else{
                        throw new InvalidDMLActionException( 'Invalid Action for DMLAction without additional parameters ' + action );
                    }
                }
            }
            return null;
        }

        public List<Object> performOperation( fflib_SObjectUnitOfWork.Operations operation, List<Object> objList ){
            if( objList != null && !objList.isEmpty() ){
                // Per operation convert List<Any> to right format by looping per record to prevent "Invalid conversion" exception
                switch on operation{
                    when SEND_EMAIL{
                        List<Messaging.Email> emailList = new List<Messaging.Email>();
                        for( Integer i = 0, j = objList.size(); i < j; i++ ){
                            emailList.add( ( Messaging.Email ) objList[ i ] );
                        }
                        return Messaging.sendEmail( emailList );
                    }
                    when PROCESS_APPROVAL_PROCESS{
                        List<Approval.ProcessRequest> approvalList = new List<Approval.ProcessRequest>();
                        for( Integer i = 0, j = objList.size(); i < j; i++ ){
                            approvalList.add( ( Approval.ProcessRequest ) objList[ i ] );
                        }
                        return Approval.process( approvalList );
                    }
                    when else{
                        throw new InvalidDMLActionException( 'Invalid Operation ' + operation );
                    }
                }
            }
            return null;
        }
    }

    public class InvalidDMLActionException extends Exception{}
}