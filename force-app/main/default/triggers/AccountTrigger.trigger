trigger AccountTrigger on Account (after insert) {

    if(trigger.isAfter && (trigger.isInsert || trigger.isupdate))
        AccountTriggerHelper.createInventories(trigger.new, trigger.oldMap, trigger.isupdate);
}