public with sharing class DebugLogUtil {

    // Define the Platform Event
    private final DebugLog__e logEvent;
    
    // Constructor
    public DebugLogUtil() {
        logEvent = new DebugLog__e();
    }
    public void publishDebugLog(String log, String className, String methodName, String lineNumber, String relatedRecordId, Id userId) {
        logEvent.ApexClass__c = className;
        logEvent.ApexMethod__c = methodName;
        logEvent.LogMessage__c = log;
        logEvent.LogLineNumber__c = lineNumber;
        logEvent.RecordId__c = relatedRecordId;
        logEvent.RunningUser__c = userId;

        EventBus.publish(logEvent);
    }
    
    public void publishExceptionLog(Exception ex, String className, String methodName, String lineNumber, String relatedRecordId, Id userId) {
        logEvent.ApexClass__c = className;
        logEvent.ApexMethod__c = methodName;
        logEvent.LogLineNumber__c = lineNumber;
        logEvent.RecordId__c = relatedRecordId;
        logEvent.RunningUser__c = userId;
        logEvent.LogMessage__c = ex?.getMessage();
        logEvent.StackTrace__c = ex?.getStackTraceString();

        EventBus.publish(logEvent);
    }
}