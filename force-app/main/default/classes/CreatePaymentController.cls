public without sharing class CreatePaymentController {
    
    @AuraEnabled(cacheable=true)
    public static order getOrderDetails(String recordId){

        return [SELECT Id,Name,Amount_Owed__c,Available_Credits__c,OrderNumber FROM Order WHERE Id=: recordId];
    }

    @AuraEnabled
    public static String createPayment(String payment){

        Map<String,object> paymentObj = (Map<String,object>)JSON.deserializeUntyped(payment);
        Payments_TB__c pay = new Payments_TB__c();
        pay.Order__c = (String)paymentObj.get('orderId');
        pay.Comment__c = (String)paymentObj.get('comments');
        pay.Amount__c = String.isNotBlank((String)paymentObj.get('amount'))? Double.valueOf((String)paymentObj.get('amount')):0;
        pay.Payment_Method__c = (String)paymentObj.get('method');
        insert pay;
        return 'Success';
    }
}