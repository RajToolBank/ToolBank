trigger ContactTrigger on Contact (before update) {
    
    //ContactTriggerHelper.SingleCurrentAffiliateValidation(trigger.new, trigger.oldMap);
    ContactTriggerHandler.primaryORExecutiveLogic(trigger.new, trigger.oldMap);
    
}