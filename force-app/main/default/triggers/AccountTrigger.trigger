trigger AccountTrigger on Account (after insert) {

    if(trigger.isAfter && trigger.isInsert)
        AccountTriggerHelper.createInventories(trigger.new);
}