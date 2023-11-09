public class DisableContactBatch implements Database.Batchable<Sobject>{
    public string contactId;
    public Database.QueryLocator start(Database.BatchableContext BC){

        return Database.getQueryLocator([SELECT Id,communityNickname, ContactId FROM USER WHERE contactId =:contactId LIMIT 1]);
    }

    public void execute(Database.BatchableContext BC, List<User> scope){
        scope[0].isActive = false;
        Integer IntrandomNumber = Integer.valueof((Math.random() * 10000));
        scope[0].communityNickname = scope[0].communityNickname+'_'+IntrandomNumber;
        scope[0].IsPortalEnabled = false;
        
            if(!Test.isRunningTest()){
                update scope;
                //disableContactFlag(contactId);
            }

    }

    public void finish(Database.BatchableContext BC){

    }
}