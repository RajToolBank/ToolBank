trigger PaymentMemberTrigger on Payments_TB__c (after insert,before delete) {

    if(trigger.isAfter && trigger.isInsert)
        PaymentMemberTriggerHelper.createPaymentCredit(trigger.new);
    
    if(trigger.isbefore && trigger.isDelete)
        PaymentMemberTriggerHelper.deletePayment(trigger.Old);
}