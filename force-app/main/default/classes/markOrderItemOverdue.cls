public with sharing class markOrderItemOverdue implements Database.Batchable<Sobject>, Schedulable{
 
    public Database.QueryLocator start(Database.BatchableContext BC){

        return Database.getQueryLocator([SELECT Id,Schedule_Return_Date__c FROM OrderItem WHERE (Status__c =: 'Fulfilled' OR Status__c=: 'Partially Returned' OR Status__c=: 'Overdue') ]);
    }

    public void execute(Database.BatchableContext BC, List<OrderItem> scope){
       for(orderitem item: scope){
        if(item.Schedule_Return_Date__c < Date.today())
            item.status__c = 'Overdue';
        else item.status__c = 'Fulfilled';
        
       }

       update scope;
    }

    public void finish(Database.BatchableContext BC){

    }

    public void execute(SchedulableContext sc){
        markOrderItemOverdue batch = New markOrderItemOverdue();
        database.executeBatch(batch, 200);
    }
}