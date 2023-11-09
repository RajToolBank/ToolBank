trigger DebugLogTrigger on DebugLog__e (after insert) {
    DebugLogtriggerHandler.afterInsert(Trigger.new);
}