public class CreditExpirationHandlerBatch implements Database.Batchable<SObject> {
 
    public Database.QueryLocator start(Database.BatchableContext BC){

        return Database.getQueryLocator([SELECT Id FROM Credit__c WHERE Expiration_Date__c <TODAY]);
    }

    public void execute(Database.BatchableContext BC, List<Credit__c> scope){
        for(Credit__c credit: scope){
            credit.Is_Expired__c = true;
        }

        update scope;
    }

    public void finish(Database.BatchableContext BC){

    }

}