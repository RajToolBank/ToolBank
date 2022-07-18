public with sharing class markOrderItemOverdue implements Database.Batchable<Sobject> {
 
    public Database.QueryLocator start(Database.BatchableContext BC){

        return Database.getQueryLocator([SELECT Id FROM OrderItem WHERE (Status__c =: 'Fulfilled' OR Status__c=: 'Partially Returned' ) AND Schedule_Return_Date__c < TODAY]);
    }

    public void execute(Database.BatchableContext BC, List<OrderItem> scope){
       for(orderitem item: scope){
            item.status__c = 'Overdue';
        
       }

       update scope;
    }

    public void finish(Database.BatchableContext BC){

    }
}
