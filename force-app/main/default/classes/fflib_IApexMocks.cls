/**
 * Interface class for fflib_ApexMocks
 * Allowing to override the mocks.mock() method, in case of a scenario where Test.createStub() isn't feasible
 * - E.g. when aiming to mock inner-classes
 * - E.g. when aiming to mock fflib_ApexMocks which throws an Exception on override being specified for doThrowWhen
 *
 * Applied in a.o. fflib_ApplicationTest to allow testing and verifying the application of defineMock()
 *
 * @created    April 2024
 */
public interface fflib_IApexMocks{
    Object mock( Type classToMock );
}