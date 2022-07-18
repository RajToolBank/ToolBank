trigger ProductTrigger on Product2 (after insert) {

    if(trigger.isAfter && trigger.isInsert)
        ProductTriggerHelper.createInventories(trigger.new);
}