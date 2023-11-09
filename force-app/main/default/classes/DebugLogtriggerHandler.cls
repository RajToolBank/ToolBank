public class DebugLogtriggerHandler {
    
    public static void afterInsert(List<DebugLog__e> debugLogs){
        List<OrderLog__c> orderLogs = new List<OrderLog__c>();
        for(DebugLog__e logevt :debugLogs) {
            OrderLog__c odLog = new OrderLog__c();
            odLog = formOrderLog(odLog, logevt);
            orderLogs.add(odLog);
        }
        if (!Schema.sObjectType.OrderLog__c.isCreateable()) {
            return;
        }
        if(!orderLogs.isEmpty()){
            insert orderLogs;
        }
    }
    
    public static OrderLog__c formOrderLog(OrderLog__c odLog, DebugLog__e logevt){
        
        odLog.ApexClass__c = logevt.ApexClass__c;
        odLog.ApexMethod__c = logevt.ApexMethod__c;
        odLog.LogLineNumber__c = logevt.LogLineNumber__c;
        odLog.RecordId__c = logevt.RecordId__c;
        odLog.RunningUser__c = logevt.RunningUser__c;
        odLog.LogMessage__c = logevt.LogMessage__c;
        odLog.StackTrace__c = logevt.StackTrace__c;
        
        return odLog;
    }
}