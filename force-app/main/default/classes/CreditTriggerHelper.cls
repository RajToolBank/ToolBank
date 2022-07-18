public with sharing class CreditTriggerHelper {
   
    public static void rollupCredits(List<Credit__c> triggerNew, Map<id,Credit__c> triggerOld, Boolean isInsert, Boolean isUpdate){
        

        set<Id> accIdList = new set<Id>();
        Map<Id, Decimal> accIdToCreditMap = new Map<Id, Decimal>();
        if(isInsert){
            for(Credit__c credit: triggerNew){
                if(credit.isActive__c && (credit.Expiration_Date__c == Null || credit.Expiration_Date__c > system.today() )){
                    Decimal amount = credit.Amount__c != Null?credit.Amount__c:0;
                    Decimal amountUsed = credit.Amount_Used__c != Null?credit.Amount_Used__c:0;
                    Decimal remaining = amount-amountUsed;
                    accIdList.add(credit.Organization__c);

                    if(!accIdToCreditMap.containsKey(credit.Organization__c))
                        accIdToCreditMap.put(credit.Organization__c,0);
                    
                    Decimal credits = accIdToCreditMap.get(credit.Organization__c);

                    credits += remaining;

                    accIdToCreditMap.put(credit.Organization__c,credits);
                }
                
            }    
        }else if(isUpdate){
            for(Credit__c credit: triggerNew){
                if(credit.isActive__c && (credit.Expiration_Date__c == Null || credit.Expiration_Date__c >= system.today() )){
                    Decimal amount = credit.Amount__c != Null?credit.Amount__c:0;
                    Decimal amountUsed = credit.Amount_Used__c != Null?credit.Amount_Used__c:0;
                    Decimal remaining = amount-amountUsed;
                    Credit__c oldCredit = triggerOld.get(credit.Id);
                    Decimal oldAmount = oldCredit.Amount__c != Null?oldCredit.Amount__c:0;
                    Decimal oldAmountUsed = oldCredit.Amount_Used__c != Null?oldCredit.Amount_Used__c:0;
                    Decimal oldRemaining = oldAmount-oldAmountUsed;

                    if(remaining != oldRemaining){
                        accIdList.add(credit.Organization__c);

                        if(!accIdToCreditMap.containsKey(credit.Organization__c))
                            accIdToCreditMap.put(credit.Organization__c,0);
                        
                        Decimal credits = accIdToCreditMap.get(credit.Organization__c);

                        credits += (remaining - oldRemaining);

                        accIdToCreditMap.put(credit.Organization__c,credits);
                    }else if(!triggerOld.get(credit.id).isActive__c){
                        accIdList.add(credit.Organization__c);

                        if(!accIdToCreditMap.containsKey(credit.Organization__c))
                            accIdToCreditMap.put(credit.Organization__c,0);
                        
                        Decimal credits = accIdToCreditMap.get(credit.Organization__c);

                        
                        credits += remaining;
                        accIdToCreditMap.put(credit.Organization__c,credits);
                    }
                }

                if(!credit.IsActive__c && triggerOld.get(credit.id).isActive__c){
                    Decimal amount = credit.Amount__c != Null?credit.Amount__c:0;
                    Decimal amountUsed = credit.Amount_Used__c != Null?credit.Amount_Used__c:0;
                    Decimal remaining = amount-amountUsed;

                    accIdList.add(credit.Organization__c);

                    if(!accIdToCreditMap.containsKey(credit.Organization__c))
                        accIdToCreditMap.put(credit.Organization__c,0);
                    
                    Decimal credits = accIdToCreditMap.get(credit.Organization__c);
                    
                    credits -= remaining;
                    

                    accIdToCreditMap.put(credit.Organization__c,credits);
                }
                
            }
        }else{
            for(Credit__c credit: triggerOld.values()){
                if(credit.Expiration_Date__c == Null || credit.Expiration_Date__c > system.today() ){
                    Decimal amount = credit.Amount__c != Null?credit.Amount__c:0;
                    Decimal amountUsed = credit.Amount_Used__c != Null?credit.Amount_Used__c:0;
                    Decimal remaining = amount-amountUsed;

                    accIdList.add(credit.Organization__c);

                    if(!accIdToCreditMap.containsKey(credit.Organization__c))
                        accIdToCreditMap.put(credit.Organization__c,0);
                    
                    Decimal credits = accIdToCreditMap.get(credit.Organization__c);

                    credits -= remaining;

                    accIdToCreditMap.put(credit.Organization__c,credits);
                } 
            }
        }

        List<Account> accListToupdate = new List<Account>();
        for(Account acc: [SELECT Id,Available_Credits__c FROM Account WHERE id IN: accIdList]){
            if(accIdToCreditMap.containsKey(acc.Id)){
                Account account = new Account();
                account.id = acc.Id;
                Decimal credit= accIdToCreditMap.get(acc.id);
                credit += acc.Available_Credits__c != null?acc.Available_Credits__c:0;
                
                account.Available_Credits__c = credit>=0?credit:0;
                accListToupdate.add(account);
            }
        }

        if(!accListToupdate.isEmpty())
            update accListToupdate;


    }
}
