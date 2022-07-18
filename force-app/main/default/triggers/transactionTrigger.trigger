trigger transactionTrigger on Transaction__c (before insert,  after insert) {

    if(trigger.isBefore)
     TransactionTriggerHandler.updqteQuantity(trigger.new);
    if(trigger.isafter)
     TransactionTriggerHandler.transaction(trigger.new);
}