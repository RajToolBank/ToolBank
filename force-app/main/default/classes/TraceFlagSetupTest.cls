@IsTest
public class TraceFlagSetupTest {
    @IsTest
    static void testSetupDebugLogs() {
        // Prepare test data
        String testUserId = UserInfo.getUserId(); // Use the current user ID for testing
        List<String> testUserIds = new List<String>{testUserId};
        String logType = 'USER_DEBUG';

        // Mock responses for Tooling API calls
        Test.setMock(HttpCalloutMock.class, new ToolingAPIMock());

        // Call the method to set up debug logs
        TraceFlagSetup.setupDebugLogs(testUserIds, logType);

    }

    @IsTest
    static void testScheduleTraceFlag() {
        // Mock responses for Tooling API calls
        Test.setMock(HttpCalloutMock.class, new ToolingAPIMock());
        TraceFlagSchedular.scheduleTraceFlag();
        TraceFlagSchedular m = new TraceFlagSchedular();
        String sch = '20 30 8 10 2 ?';
        String jobID = System.schedule('Merge Job', sch, m);
    }
}