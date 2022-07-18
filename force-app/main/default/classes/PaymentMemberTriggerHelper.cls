public with sharing class PaymentMemberTriggerHelper {
    
    public static void createPaymentCredit(List<Payments_TB__c> triggerNew){

        Map<Id, List<Payments_TB__c>> orderIdToPaymentListMap = new Map<Id, List<Payments_TB__c>>();
        for(Payments_TB__c payment: triggerNew){
            if(payment.Payment_Method__c == 'Organizational Credit'){
                if(!orderIdToPaymentListMap.containsKey(payment.order__c))
                    orderIdToPaymentListMap.put(payment.order__c, new list<Payments_TB__c>());
                
                orderIdToPaymentListMap.get(payment.order__c).add(payment);
            }
        }
        Map<Id, List<Payments_TB__c>> accIdToPaymentListMap = new Map<Id, List<Payments_TB__c>>();
        Map<Id, List<Id>> accIdToOrderIdListMap = new Map<Id, List<Id>>();
        for(Order order: [SELECT Id, AccountId FROM ORDER WHERE Id IN: orderIdToPaymentListMap.keySet()]){
            if(!accIdToPaymentListMap.containsKey(order.AccountId))
                accIdToPaymentListMap.put(order.AccountId, orderIdToPaymentListMap.get(order.Id));

            if(!accIdToOrderIdListMap.containsKey(order.AccountId))
                accIdToOrderIdListMap.put(order.AccountId, new list<Id>());
            
            accIdToOrderIdListMap.get(order.AccountId).add(order.Id);
        }

        Map<Id, List<Id>> orderIdToCreditIdListMap = new Map<Id, List<Id>>();
        Map<Id, Credit__c> creditIdToCreditMap = new Map<Id, Credit__c>();
        for(Credit__c credit: [SELECT Id,Organization__c, Amount__c,Amount_Used__c 
                         FROM Credit__c 
                         WHERE Organization__c IN:accIdToOrderIdListMap.keySet() 
                         AND Amount_Remaining__c != Null 
                         AND Amount_Remaining__c != 0 
                         AND (Expiration_Date__c > TODAY 
                         OR Expiration_Date__c = Null) 
                         ORDER BY Expiration_Date__c NULLS Last 
                         ]){
            creditIdToCreditMap.put(credit.Id,credit);
            

            if(accIdToOrderIdListMap.containsKey(credit.Organization__c)){
                for(Id orderId: accIdToOrderIdListMap.get(credit.Organization__c)){
                    if(!orderIdToCreditIdListMap.containsKey(orderId))
                        orderIdToCreditIdListMap.put(orderId, new list<Id>());
            
                    orderIdToCreditIdListMap.get(orderId).add(credit.Id);
                }
            }
            
        }

        List<Credit_Payment_Intersect__c> creditPaymentList = new List<Credit_Payment_Intersect__c>();

            for(Payments_TB__c payment: triggerNew){
                if(payment.Payment_Method__c == 'Organizational Credit'){
                    if(orderIdToCreditIdListMap.containsKey(payment.order__c)){
                        Decimal payAmount = payment.Amount__c!= Null?payment.Amount__c:0;
                        for(Id creditId: orderIdToCreditIdListMap.get(payment.order__c)){
                            Credit__c credit = creditIdToCreditMap.get(creditId);
                            Decimal amount = credit.Amount__c != Null?credit.Amount__c:0;
                            Decimal amountUsed = credit.Amount_Used__c != Null?credit.Amount_Used__c:0;
                            Decimal available = amount-amountUsed;
                            if(available > 0){
                            
                                Decimal remaining = available -payAmount;
                                Credit_Payment_Intersect__c creditPayment = new Credit_Payment_Intersect__c();
                                creditPayment.Payment_by_Member__c = payment.id;
                                creditPayment.Credit__c = credit.id;
                                creditPayment.Amount__c = remaining>=0?payAmount:available;
                                credit.Amount_Used__c = amountUsed+(remaining>=0?payAmount:available);
                                payAmount = payAmount - creditPayment.Amount__c;
                                creditPaymentList.add(creditPayment);
                                if(remaining>=0)
                                    break;
                            }
                        }
                    }
                }
            }
        

        if(!creditIdToCreditMap.values().isEmpty())
            update creditIdToCreditMap.values();

        if(!creditPaymentList.isEmpty())
            insert creditPaymentList;

    }


    public static void deletePayment(List<Payments_TB__c> triggerOld){

        List<Payments_TB__c> PaymentGotDeleted = new List<Payments_TB__c>();
        for(Payments_TB__c payment: triggerOld){
            if(payment.Payment_Method__c == 'Organizational Credit'){
                PaymentGotDeleted.add(payment);
            }
        }
        system.debug(PaymentGotDeleted);
        Map<Id, Decimal> creditIdToAmountMap = new Map<Id, Decimal>();
        for(Credit_Payment_Intersect__c creditPayment:  [SELECT Id,
                                                        Credit__c,
                                                        Credit__r.Amount__c,
                                                        Amount__c
                                                        FROM Credit_Payment_Intersect__c 
                                                        WHERE Payment_by_Member__c IN:PaymentGotDeleted
                                                        AND (Credit__r.Expiration_Date__c > TODAY 
                                                        OR Credit__r.Expiration_Date__c = Null) ])
        {
            if(!creditIdToAmountMap.containsKey(creditPayment.Credit__c))
                creditIdToAmountMap.put(creditPayment.Credit__c, creditPayment.Credit__r.Amount__c);

            Decimal creditAmount = creditIdToAmountMap.get(creditPayment.Credit__c);
            creditAmount = creditAmount+creditPayment.Amount__c;

            creditIdToAmountMap.put(creditPayment.Credit__c, creditAmount);


        }
        system.debug(creditIdToAmountMap);
        List<Credit__c> creditListToUpdate = new List<Credit__c>();
        for(Id creditId: creditIdToAmountMap.keySet()){
            Credit__c credit = new Credit__c();
            credit.Id = creditId;
            credit.Amount__c = creditIdToAmountMap.get(creditId);
            creditListToUpdate.add(credit);
        }
        system.debug(creditListToUpdate);
        if(!creditListToUpdate.isEmpty())
            update creditListToUpdate;
                                                                

    }


}