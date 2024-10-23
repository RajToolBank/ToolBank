public class TraceFlagSchedular implements Schedulable {
    
    public void execute(SchedulableContext SC) {
        scheduleTraceFlag();
    }


    @future(callout=true)
    public static void scheduleTraceFlag(){
        String UserIdsLabel = label.DebugLogUserIds;
        List<String> UserIdsList = UserIdsLabel.split(',');
        TraceFlagSetup.setupDebugLogs(UserIdsList,'USER_DEBUG');
    }
}