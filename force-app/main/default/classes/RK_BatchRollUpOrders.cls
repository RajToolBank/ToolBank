global class RK_BatchRollUpOrders implements Database.Batchable<sObject>, Database.Stateful {
    public List<String> statusExempted = new List<String>{'Unconfirmed', 'Cancelled'};
    Map<Id,Account> mapIdtoAccount = new Map<Id,Account>();
    //public String accId = '0010200000IFjIl';
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator('Select Id,TotalAmount,People_Directly_Served__c, Status, AccountId from Order where Createddate >= LAST_N_DAYS:365 AND Status NOT IN :statusExempted');
    }
    global void execute(Database.BatchableContext BC,List<Order> scope) {
        
        for(Order ord :scope) {
            if(!String.isBlank(ord.AccountId)) {
                if(mapIdtoAccount.containsKey(Ord.AccountId)) {
                    Account acc = mapIdtoAccount.get(Ord.AccountId);
                    acc.Yearly_Retail_Amount__c = (acc.Yearly_Retail_Amount__c != null?acc.Yearly_Retail_Amount__c:0)+(ord.TotalAmount != null?ord.TotalAmount:0);
                    acc.Yearly_People_Served__c = (acc.Yearly_People_Served__c != null?acc.Yearly_People_Served__c:0)+(ord.People_Directly_Served__c!= null?ord.People_Directly_Served__c:0);
                } else {
                    Account acc = new Account(Id = ord.AccountId);
                    acc.Yearly_Retail_Amount__c = ord.TotalAmount;
                    acc.Yearly_People_Served__c = ord.People_Directly_Served__c;
                    mapIdtoAccount.put(ord.AccountId, acc);
                }
            }
        }
    }
    global void finish(Database.BatchableContext BC) {
        if(!mapIdtoAccount.values().isEmpty()) {
            update mapIdtoAccount.values();
        }
    }
}