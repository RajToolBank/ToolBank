@isTest
public class DebugLogtriggerHandlerTest {
    @isTest static void testPublishExceptionLog() {
        Test.startTest();
        try {
            DebugLogUtil util = new DebugLogUtil();
            String className = 'DebugLogUtil';
            String methodName = 'testPublishException';
            String LogLineNumber = '123';
            String recordId = null;
            Exception ex; //= new Exception('Test Exception');
            util.publishExceptionLog(ex, className, methodName, LogLineNumber, recordId, UserInfo.getUserId());
        } catch (Exception e) {
            System.assert(false, e.getMessage());
        }
        Test.stopTest();
    }

    @isTest static void testPublishDebugLog() {
        Test.startTest();
        try {
            DebugLogUtil util = new DebugLogUtil();
            String className = 'DebugLogUtil';
            String methodName = 'testPublishDebug';
            String LogLineNumber = '123';
            String recordId = null;
            String debugLog = 'Test';// = new Exception('Test REST API Exception');
            util.publishDebugLog(debugLog, className, methodName, LogLineNumber, recordId, UserInfo.getUserId());
        } catch (Exception e) {
            System.assert(false, e.getMessage());
        }
        Test.stopTest();
    }

}