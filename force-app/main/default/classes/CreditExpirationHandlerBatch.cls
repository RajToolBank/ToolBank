public class CreditExpirationHandlerBatch implements Database.Batchable<Sobject> {
 
    public Database.QueryLocator start(Database.BatchableContext BC){

        return Database.getQueryLocator([SELECT Id,Amount_Remaining__c,Account__c,Amount__c,Amount_Used__c,Expiration_Date__c FROM Credit__c WHERE Expiration_Date__c = TODAY]);
    }

    public void execute(Database.BatchableContext BC, List<Credit__c> scope){
        for(Credit__c credit: scope){
            credit.IsActive__c = false;
        }

        update scope;
    }

    public void finish(Database.BatchableContext BC){

    }

}
