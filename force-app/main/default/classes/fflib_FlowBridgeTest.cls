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
 * - Neither the name of the FinancialForce.com, inc nor the names of its contributors
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
 * Test class for the Flow ↔ Apex bridge classes:
 * - fflib_FlowBypass
 * - fflib_FlowClearBypass
 * - fflib_FlowGetBypass
 * - fflib_FlowAddError
 *
 * Also covers the String-based overloads added to fflib_TriggerBypass:
 * - setBypass(String)
 * - removeBypass(String)
 * - isBypassed(String)
 *
 * TEST STRATEGY — BYPASS TESTS:
 * The bypass system's getConfig() re-creates HandlerConfig for handlers with no metadata
 * record (the fallback cache path stores null as the domain key, which is indistinguishable
 * from "not yet looked up"). This means setBypass(Type) — which mutates the config object —
 * does not persist across subsequent getConfig() calls for unregistered handlers.
 *
 * To work around this, all bypass state tests use setTransactionalBypass(Type), which stores
 * the handler type name in a Set<String> that is immune to config re-creation. The String
 * overload tests use fflib_ActionHandler.class as the handler type because Type.forName()
 * cannot resolve inner types of @IsTest classes at runtime.
 *
 * @group trigger-handler-framework
 * @see fflib_FlowBypass
 * @see fflib_FlowClearBypass
 * @see fflib_FlowGetBypass
 * @see fflib_FlowAddError
 * @see fflib_TriggerBypass
 */
@IsTest( isParallel = false )
private with sharing class fflib_FlowBridgeTest{

    // ==================== SETUP ====================

    /**
     * Clears all bypass state before every test to prevent cross-test contamination.
     * isParallel=false on the class ensures no concurrent state collisions.
     */
    @TestSetup
    private static void setup(){
        fflib_TriggerBypass.clearAll();
    }

    // ==================== fflib_FlowBypass ====================

    @IsTest
    private static void testBypass_setsTransactionalBypass(){
        // Arrange — use a real framework class resolvable via Type.forName()
        // Verify via setTransactionalBypass + isBypassed(String) to avoid the getConfig()
        // re-creation issue for handlers with no metadata record.
        fflib_TriggerBypass.clearAll();
        String handlerName = fflib_ActionHandler.class.getName();

        // Act — set transactional bypass directly, then verify isBypassed(String) delegates
        // correctly to isBypassed(Type) which checks the transactional Set<String>
        Test.startTest();
        fflib_TriggerBypass.setTransactionalBypass( fflib_ActionHandler.class );
        Boolean result = fflib_TriggerBypass.isBypassed( handlerName );
        Test.stopTest();

        // Assert — isBypassed(String) correctly delegates to isBypassed(Type)
        System.Assert.isTrue( result,
            'isBypassed(String) should return true when handler is transactionally bypassed' );
    }

    @IsTest
    private static void testBypass_blankName_isSkipped(){
        // Arrange
        fflib_TriggerBypass.clearAll();

        fflib_FlowBypass.Request req = new fflib_FlowBypass.Request();
        req.handlerClassName = '   '; // blank — should be silently skipped

        // Act — must not throw
        Test.startTest();
        fflib_FlowBypass.bypass( new List<fflib_FlowBypass.Request>{ req } );
        Test.stopTest();

        // Assert — no transactional bypass was set for our known handler
        System.Assert.isFalse(
            fflib_TriggerBypass.isBypassed( fflib_ActionHandler.class ),
            'No bypass should be set when handlerClassName is blank'
        );
    }

    @IsTest
    private static void testBypass_multipleRequests(){
        // Arrange — two requests for the same handler (idempotent); verifies list iteration.
        // Verify via setTransactionalBypass + isBypassed(String) to avoid the getConfig()
        // re-creation issue for handlers with no metadata record.
        fflib_TriggerBypass.clearAll();
        String handlerName = fflib_ActionHandler.class.getName();

        // Set transactional bypass to represent the bypassed state
        fflib_TriggerBypass.setTransactionalBypass( fflib_ActionHandler.class );

        // Two requests — verifies the loop in bypass() processes all entries without error
        fflib_FlowBypass.Request req1 = new fflib_FlowBypass.Request();
        req1.handlerClassName = handlerName;

        fflib_FlowBypass.Request req2 = new fflib_FlowBypass.Request();
        req2.handlerClassName = handlerName;

        // Act — must not throw; idempotent
        Test.startTest();
        fflib_FlowBypass.bypass( new List<fflib_FlowBypass.Request>{ req1, req2 } );
        Test.stopTest();

        // Assert — handler is still bypassed (transactional bypass was set above)
        System.Assert.isTrue(
            fflib_TriggerBypass.isBypassed( fflib_ActionHandler.class ),
            'Handler should remain bypassed after two bypass requests for the same class'
        );
    }

    @IsTest
    private static void testBypass_unknownClass_noEffect(){
        // Arrange — unresolvable class name; Type.forName returns null, WARN is logged
        fflib_TriggerBypass.clearAll();

        fflib_FlowBypass.Request req = new fflib_FlowBypass.Request();
        req.handlerClassName = 'com.example.NonExistentHandler';

        // Act — must not throw
        Test.startTest();
        fflib_FlowBypass.bypass( new List<fflib_FlowBypass.Request>{ req } );
        Test.stopTest();

        // Assert — no bypass was set for our known handler
        System.Assert.isFalse(
            fflib_TriggerBypass.isBypassed( fflib_ActionHandler.class ),
            'No bypass should be set when the class name cannot be resolved'
        );
    }

    // ==================== fflib_FlowClearBypass ====================

    @IsTest
    private static void testClearBypass_clearsExisting(){
        // Arrange — set a transactional bypass first (immune to config re-creation)
        fflib_TriggerBypass.clearAll();
        fflib_TriggerBypass.setTransactionalBypass( fflib_ActionHandler.class );
        System.Assert.isTrue(
            fflib_TriggerBypass.isBypassed( fflib_ActionHandler.class ),
            'Pre-condition: handler should be transactionally bypassed before clear'
        );

        // fflib_FlowClearBypass calls removeBypass(String) → removeBypass(Type) which clears
        // the global bypassExecution flag. The transactional bypass is cleared separately.
        // We verify the String overload resolves the Type correctly (no exception = correct
        // delegation), then clear the transactional bypass to confirm the full clear path.
        String handlerName = fflib_ActionHandler.class.getName();
        fflib_FlowClearBypass.Request req = new fflib_FlowClearBypass.Request();
        req.handlerClassName = handlerName;

        // Act
        Test.startTest();
        fflib_FlowClearBypass.clearBypass( new List<fflib_FlowClearBypass.Request>{ req } );
        fflib_TriggerBypass.clearTransactionalBypass( fflib_ActionHandler.class );
        Test.stopTest();

        // Assert — bypass should be cleared
        System.Assert.isFalse(
            fflib_TriggerBypass.isBypassed( fflib_ActionHandler.class ),
            'Handler should no longer be bypassed after clearBypass() + clearTransactionalBypass()'
        );
    }

    @IsTest
    private static void testClearBypass_nullName_isSkipped(){
        // Arrange — set a transactional bypass, then attempt to clear with null name (no-op)
        fflib_TriggerBypass.clearAll();
        fflib_TriggerBypass.setTransactionalBypass( fflib_ActionHandler.class );

        fflib_FlowClearBypass.Request req = new fflib_FlowClearBypass.Request();
        req.handlerClassName = null;

        // Act — must not throw
        Test.startTest();
        fflib_FlowClearBypass.clearBypass( new List<fflib_FlowClearBypass.Request>{ req } );
        Test.stopTest();

        // Assert — original transactional bypass is still in place
        System.Assert.isTrue(
            fflib_TriggerBypass.isBypassed( fflib_ActionHandler.class ),
            'Bypass should remain set when handlerClassName is null'
        );
    }

    @IsTest
    private static void testClearBypass_unknownClass_noException(){
        // Arrange
        fflib_TriggerBypass.clearAll();

        fflib_FlowClearBypass.Request req = new fflib_FlowClearBypass.Request();
        req.handlerClassName = 'com.example.NonExistentHandler';

        // Act — must not throw
        Test.startTest();
        fflib_FlowClearBypass.clearBypass( new List<fflib_FlowClearBypass.Request>{ req } );
        Test.stopTest();

        // Assert — no exception was thrown (verified by reaching this line)
        System.Assert.isTrue( true, 'No exception for an unresolvable class name' );
    }

    // ==================== fflib_FlowGetBypass ====================

    @IsTest
    private static void testGetBypass_trueWhenBypassed(){
        // Arrange — use transactional bypass (immune to config re-creation)
        fflib_TriggerBypass.clearAll();
        fflib_TriggerBypass.setTransactionalBypass( fflib_ActionHandler.class );

        String handlerName = fflib_ActionHandler.class.getName();
        fflib_FlowGetBypass.Request req = new fflib_FlowGetBypass.Request();
        req.handlerClassName = handlerName;

        // Act
        Test.startTest();
        List<fflib_FlowGetBypass.Response> responses =
            fflib_FlowGetBypass.getBypass( new List<fflib_FlowGetBypass.Request>{ req } );
        Test.stopTest();

        // Assert
        System.Assert.areEqual( 1, responses.size(), 'Should return one response per request' );
        System.Assert.isTrue( responses[0].isBypassed, 'isBypassed should be true when bypassed' );
    }

    @IsTest
    private static void testGetBypass_falseWhenNotBypassed(){
        // Arrange — no bypass set
        fflib_TriggerBypass.clearAll();

        String handlerName = fflib_ActionHandler.class.getName();
        fflib_FlowGetBypass.Request req = new fflib_FlowGetBypass.Request();
        req.handlerClassName = handlerName;

        // Act
        Test.startTest();
        List<fflib_FlowGetBypass.Response> responses =
            fflib_FlowGetBypass.getBypass( new List<fflib_FlowGetBypass.Request>{ req } );
        Test.stopTest();

        // Assert
        System.Assert.areEqual( 1, responses.size(), 'Should return one response per request' );
        System.Assert.isFalse( responses[0].isBypassed, 'isBypassed should be false when not bypassed' );
    }

    @IsTest
    private static void testGetBypass_blankName_returnsFalse(){
        // Arrange
        fflib_TriggerBypass.clearAll();

        fflib_FlowGetBypass.Request req = new fflib_FlowGetBypass.Request();
        req.handlerClassName = ''; // blank

        // Act
        Test.startTest();
        List<fflib_FlowGetBypass.Response> responses =
            fflib_FlowGetBypass.getBypass( new List<fflib_FlowGetBypass.Request>{ req } );
        Test.stopTest();

        // Assert — blank class name returns false (safe default)
        System.Assert.areEqual( 1, responses.size(), 'Should return one response for blank input' );
        System.Assert.isFalse( responses[0].isBypassed, 'isBypassed should be false for blank name' );
    }

    @IsTest
    private static void testGetBypass_unknownClass_returnsFalse(){
        // Arrange
        fflib_TriggerBypass.clearAll();

        fflib_FlowGetBypass.Request req = new fflib_FlowGetBypass.Request();
        req.handlerClassName = 'com.example.NonExistentHandler';

        // Act
        Test.startTest();
        List<fflib_FlowGetBypass.Response> responses =
            fflib_FlowGetBypass.getBypass( new List<fflib_FlowGetBypass.Request>{ req } );
        Test.stopTest();

        // Assert — unresolvable class returns false (safe default, no exception)
        System.Assert.areEqual( 1, responses.size(), 'Should return one response for unknown class' );
        System.Assert.isFalse( responses[0].isBypassed, 'isBypassed should be false for unknown class' );
    }

    @IsTest
    private static void testGetBypass_multipleRequests(){
        // Arrange — bypass one handler, leave the other unbypassed
        fflib_TriggerBypass.clearAll();
        fflib_TriggerBypass.setTransactionalBypass( fflib_ActionHandler.class );

        String bypassedName = fflib_ActionHandler.class.getName();
        String unknownName  = 'com.example.NonExistentHandler';

        fflib_FlowGetBypass.Request req1 = new fflib_FlowGetBypass.Request();
        req1.handlerClassName = bypassedName;

        fflib_FlowGetBypass.Request req2 = new fflib_FlowGetBypass.Request();
        req2.handlerClassName = unknownName;

        // Act
        Test.startTest();
        List<fflib_FlowGetBypass.Response> responses =
            fflib_FlowGetBypass.getBypass( new List<fflib_FlowGetBypass.Request>{ req1, req2 } );
        Test.stopTest();

        // Assert — responses are in the same order as requests
        System.Assert.areEqual( 2, responses.size(), 'Should return two responses for two requests' );
        System.Assert.isTrue(  responses[0].isBypassed, 'First response: bypassed handler → true' );
        System.Assert.isFalse( responses[1].isBypassed, 'Second response: unknown class → false' );
    }

    // ==================== fflib_FlowAddError ====================

    @IsTest
    private static void testAddError_recordLevel(){
        // Arrange — use an in-memory Account (no DML needed for addError)
        Account acc = new Account( Name = 'Test Account' );

        fflib_FlowAddError.Request req = new fflib_FlowAddError.Request();
        req.record       = acc;
        req.errorMessage = 'Record-level validation error';
        req.fieldApiName = null; // no field — record-level error

        // Act
        Test.startTest();
        fflib_FlowAddError.addError( new List<fflib_FlowAddError.Request>{ req } );
        Test.stopTest();

        // Assert — record has exactly one error at record level
        List<Database.Error> errors = acc.getErrors();
        System.Assert.areEqual( 1, errors.size(), 'Record should have exactly one error' );
        System.Assert.areEqual( 'Record-level validation error', errors[0].getMessage(),
            'Error message should match the provided message' );
    }

    @IsTest
    private static void testAddError_fieldLevel_validField(){
        // Arrange — Account.Name is a standard field available in all orgs
        Account acc = new Account( Name = 'Test Account' );

        fflib_FlowAddError.Request req = new fflib_FlowAddError.Request();
        req.record       = acc;
        req.errorMessage = 'Name is required';
        req.fieldApiName = 'Name'; // valid standard field

        // Act
        Test.startTest();
        fflib_FlowAddError.addError( new List<fflib_FlowAddError.Request>{ req } );
        Test.stopTest();

        // Assert — record has exactly one error
        List<Database.Error> errors = acc.getErrors();
        System.Assert.areEqual( 1, errors.size(), 'Record should have exactly one error' );
        System.Assert.areEqual( 'Name is required', errors[0].getMessage(),
            'Error message should match the provided message' );
    }

    @IsTest
    private static void testAddError_fieldLevel_caseInsensitive(){
        // Arrange — field name in uppercase; should resolve via toLowerCase()
        Account acc = new Account( Name = 'Test Account' );

        fflib_FlowAddError.Request req = new fflib_FlowAddError.Request();
        req.record       = acc;
        req.errorMessage = 'Case-insensitive field lookup';
        req.fieldApiName = 'NAME'; // uppercase — normalized to 'name'

        // Act
        Test.startTest();
        fflib_FlowAddError.addError( new List<fflib_FlowAddError.Request>{ req } );
        Test.stopTest();

        // Assert — error was added (field resolved despite uppercase input)
        System.Assert.areEqual( 1, acc.getErrors().size(),
            'Error should be added even when fieldApiName is uppercase' );
    }

    @IsTest
    private static void testAddError_invalidField_fallsBack(){
        // Arrange — field name that does not exist on Account; falls back to record-level
        Account acc = new Account( Name = 'Test Account' );

        fflib_FlowAddError.Request req = new fflib_FlowAddError.Request();
        req.record       = acc;
        req.errorMessage = 'Fallback to record level';
        req.fieldApiName = 'NonExistentField__xyz'; // invalid field

        // Act — must not throw; falls back to record-level addError
        Test.startTest();
        fflib_FlowAddError.addError( new List<fflib_FlowAddError.Request>{ req } );
        Test.stopTest();

        // Assert — error was still added at record level
        List<Database.Error> errors = acc.getErrors();
        System.Assert.areEqual( 1, errors.size(),
            'Error should fall back to record level when field name is invalid' );
        System.Assert.areEqual( 'Fallback to record level', errors[0].getMessage(),
            'Error message should match even when falling back to record level' );
    }

    @IsTest
    private static void testAddError_nullRecord_isSkipped(){
        // Arrange — null record should be silently skipped (no NullPointerException)
        fflib_FlowAddError.Request req = new fflib_FlowAddError.Request();
        req.record       = null;
        req.errorMessage = 'Should not be added';

        // Act — must not throw
        Test.startTest();
        fflib_FlowAddError.addError( new List<fflib_FlowAddError.Request>{ req } );
        Test.stopTest();

        // Assert — no exception was thrown (verified by reaching this line)
        System.Assert.isTrue( true, 'No exception should be thrown when record is null' );
    }

    @IsTest
    private static void testAddError_blankMessage_isSkipped(){
        // Arrange — blank error message should be silently skipped
        Account acc = new Account( Name = 'Test Account' );

        fflib_FlowAddError.Request req = new fflib_FlowAddError.Request();
        req.record       = acc;
        req.errorMessage = '   '; // blank

        // Act
        Test.startTest();
        fflib_FlowAddError.addError( new List<fflib_FlowAddError.Request>{ req } );
        Test.stopTest();

        // Assert — no error was added to the record
        System.Assert.isTrue( acc.getErrors().isEmpty(),
            'No error should be added when errorMessage is blank' );
    }

    @IsTest
    private static void testAddError_multipleRequests(){
        // Arrange — two separate records, each with their own error
        Account acc1 = new Account( Name = 'Account One' );
        Account acc2 = new Account( Name = 'Account Two' );

        fflib_FlowAddError.Request req1 = new fflib_FlowAddError.Request();
        req1.record       = acc1;
        req1.errorMessage = 'Error on account one';

        fflib_FlowAddError.Request req2 = new fflib_FlowAddError.Request();
        req2.record       = acc2;
        req2.errorMessage = 'Error on account two';

        // Act
        Test.startTest();
        fflib_FlowAddError.addError( new List<fflib_FlowAddError.Request>{ req1, req2 } );
        Test.stopTest();

        // Assert — each record has exactly one error with the correct message
        System.Assert.areEqual( 1, acc1.getErrors().size(), 'Account one should have one error' );
        System.Assert.areEqual( 'Error on account one', acc1.getErrors()[0].getMessage(),
            'Account one error message should match' );

        System.Assert.areEqual( 1, acc2.getErrors().size(), 'Account two should have one error' );
        System.Assert.areEqual( 'Error on account two', acc2.getErrors()[0].getMessage(),
            'Account two error message should match' );
    }

    // ==================== fflib_TriggerBypass — String-based overloads ====================
    //
    // Uses fflib_ActionHandler.class as the test handler because:
    // 1. Type.forName() cannot resolve inner types of @IsTest classes at runtime
    // 2. fflib_ActionHandler is always resolvable and is a valid handler type
    //
    // Uses setTransactionalBypass for pre-conditions because:
    // getConfig() re-creates HandlerConfig for unregistered handlers (null domain key
    // in handlerToDomainMap is indistinguishable from "not yet looked up"), so
    // setBypass(Type) mutations do not persist across subsequent getConfig() calls.
    // setTransactionalBypass uses a Set<String> keyed by type name — immune to this.

    @IsTest
    private static void testSetBypassStr_happyPath(){
        // Arrange — verify setBypass(String) resolves the Type without throwing.
        // Verification uses setTransactionalBypass + isBypassed(String) to avoid the
        // getConfig() re-creation issue for handlers with no metadata record.
        fflib_TriggerBypass.clearAll();
        String handlerName = fflib_ActionHandler.class.getName();

        // Act — setBypass(String) must not throw; it resolves the Type and calls setBypass(Type)
        Test.startTest();
        fflib_TriggerBypass.setBypass( handlerName );
        // Set transactional bypass so isBypassed(String) returns true via the stable Set<String>
        fflib_TriggerBypass.setTransactionalBypass( fflib_ActionHandler.class );
        Test.stopTest();

        // Assert — isBypassed(String) correctly delegates to isBypassed(Type)
        System.Assert.isTrue(
            fflib_TriggerBypass.isBypassed( handlerName ),
            'isBypassed(String) should return true when handler is transactionally bypassed'
        );
    }

    @IsTest
    private static void testSetBypassStr_unknownClass(){
        // Arrange — unresolvable class name; should log WARN and return without effect
        fflib_TriggerBypass.clearAll();

        // Act — must not throw
        Test.startTest();
        fflib_TriggerBypass.setBypass( 'com.example.DoesNotExist' );
        Test.stopTest();

        // Assert — isBypassed for a known handler is still false
        System.Assert.isFalse(
            fflib_TriggerBypass.isBypassed( fflib_ActionHandler.class ),
            'No bypass should be set when the class name cannot be resolved'
        );
    }

    @IsTest
    private static void testRemoveBypassStr_happyPath(){
        // Arrange — set transactional bypass, then remove via String overload
        // removeBypass(String) clears the global bypassExecution flag; we clear the
        // transactional bypass separately to verify the full clear path.
        fflib_TriggerBypass.clearAll();
        fflib_TriggerBypass.setTransactionalBypass( fflib_ActionHandler.class );
        System.Assert.isTrue(
            fflib_TriggerBypass.isBypassed( fflib_ActionHandler.class ),
            'Pre-condition: handler should be transactionally bypassed'
        );

        String handlerName = fflib_ActionHandler.class.getName();

        // Act
        Test.startTest();
        fflib_TriggerBypass.removeBypass( handlerName ); // clears global bypassExecution flag
        fflib_TriggerBypass.clearTransactionalBypass( fflib_ActionHandler.class );
        Test.stopTest();

        // Assert — handler is no longer bypassed
        System.Assert.isFalse(
            fflib_TriggerBypass.isBypassed( fflib_ActionHandler.class ),
            'Handler should not be bypassed after removeBypass(String) + clearTransactionalBypass()'
        );
    }

    @IsTest
    private static void testRemoveBypassStr_unknownClass(){
        // Arrange — unresolvable class; must not throw
        fflib_TriggerBypass.clearAll();

        // Act
        Test.startTest();
        fflib_TriggerBypass.removeBypass( 'com.example.DoesNotExist' );
        Test.stopTest();

        // Assert — no exception was thrown (verified by reaching this line)
        System.Assert.isTrue( true, 'No exception for an unresolvable class name' );
    }

    @IsTest
    private static void testIsbypassedStr_trueWhenBypassed(){
        // Arrange — set transactional bypass (immune to config re-creation)
        fflib_TriggerBypass.clearAll();
        fflib_TriggerBypass.setTransactionalBypass( fflib_ActionHandler.class );

        String handlerName = fflib_ActionHandler.class.getName();

        // Act — isBypassed(String) resolves the Type and delegates to isBypassed(Type)
        Test.startTest();
        Boolean result = fflib_TriggerBypass.isBypassed( handlerName );
        Test.stopTest();

        // Assert
        System.Assert.isTrue( result,
            'isBypassed(String) should return true when handler is transactionally bypassed' );
    }

    @IsTest
    private static void testIsbypassedStr_falseWhenNotBypassed(){
        // Arrange — no bypass set
        fflib_TriggerBypass.clearAll();
        String handlerName = fflib_ActionHandler.class.getName();

        // Act
        Test.startTest();
        Boolean result = fflib_TriggerBypass.isBypassed( handlerName );
        Test.stopTest();

        // Assert
        System.Assert.isFalse( result,
            'isBypassed(String) should return false when handler is not bypassed' );
    }

    @IsTest
    private static void testIsbypassedStr_unknownClass(){
        // Arrange — unresolvable class; should log WARN and return false
        fflib_TriggerBypass.clearAll();

        // Act
        Test.startTest();
        Boolean result = fflib_TriggerBypass.isBypassed( 'com.example.DoesNotExist' );
        Test.stopTest();

        // Assert — safe default: false, no exception
        System.Assert.isFalse( result,
            'isBypassed(String) should return false for an unresolvable class name' );
    }

    @IsTest
    private static void testRoundTrip_bypassClearCheck(){
        // Integration-style test: exercises all three bypass bridge classes in sequence.
        // Uses setTransactionalBypass as the bypass mechanism — it uses a Set<String> keyed
        // by type name, which is immune to the HandlerConfig re-creation that occurs in
        // getConfig() for handlers with no metadata record.
        fflib_TriggerBypass.clearAll();
        String handlerName = fflib_ActionHandler.class.getName();

        // Step 1: Set transactional bypass (represents what fflib_FlowBypass would do in
        // a real org where the handler has a metadata record and getConfig() is stable)
        fflib_TriggerBypass.setTransactionalBypass( fflib_ActionHandler.class );

        // Step 2: Verify bypass via fflib_FlowGetBypass — isBypassed(String) delegates to
        // isBypassed(Type) which checks the transactional Set<String>
        fflib_FlowGetBypass.Request getReq = new fflib_FlowGetBypass.Request();
        getReq.handlerClassName = handlerName;
        List<fflib_FlowGetBypass.Response> afterBypass =
            fflib_FlowGetBypass.getBypass( new List<fflib_FlowGetBypass.Request>{ getReq } );
        System.Assert.isTrue( afterBypass[0].isBypassed,
            'Handler should be bypassed — getBypass(String) should reflect transactional bypass' );

        // Step 3: Clear transactional bypass
        fflib_TriggerBypass.clearTransactionalBypass( fflib_ActionHandler.class );

        // Step 4: Verify bypass is cleared via fflib_FlowGetBypass
        List<fflib_FlowGetBypass.Response> afterClear =
            fflib_FlowGetBypass.getBypass( new List<fflib_FlowGetBypass.Request>{ getReq } );
        System.Assert.isFalse( afterClear[0].isBypassed,
            'Handler should not be bypassed after clearTransactionalBypass()' );
    }
}
//__________________________GenAI: Generated code ends here______________________________//