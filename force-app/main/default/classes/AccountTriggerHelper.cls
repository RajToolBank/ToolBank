public with sharing class AccountTriggerHelper {
    
    public static void createInventories(list<Account> accList){

        // Query products
        // insert assets
       
        List<Asset> assestList=new List<Asset>();
        List<Product2> prodList = [SELECT Id,name,Description FROM Product2 WHERE IsActive=true AND Type__c !='Additional Charges'];
        for(Account acc: accList){
            if(label.Affiliate_Record_Type_Ids.containsIgnoreCase(acc.recordTypeId)){
                for(product2 prod: prodList){
                    
                        Asset asset = new Asset();
                        asset.accountId = acc.id;
                        asset.product2Id = prod.id;
                        asset.Description = prod.Description;
                        asset.name = prod.name;
                        assestList.add(asset);
                }
            }
        }

        if(!assestList.isEmpty())
            insert assestList;

    }
}