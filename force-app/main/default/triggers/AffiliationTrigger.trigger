trigger AffiliationTrigger on npe5__Affiliation__c (after update) {

    if(trigger.isAfter && trigger.isUpdate)
        AffiliationTriggerHelper.upateAffiliationStatus(trigger.new, trigger.oldMap);
}