trigger CreditTrigger on Credit__c (after insert, after update, after Delete) {

    CreditTriggerHelper.rollupCredits(trigger.new, trigger.oldMap, trigger.isInsert, trigger.isUpdate);
}