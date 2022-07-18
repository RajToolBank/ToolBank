public with sharing class AccountTriggerHelper {
    
    public static void createInventories(list<Account> accList){

        // Query products
        // insert assets
       
        List<Asset> assestList=new List<Asset>();
        List<Product2> prodList = [SELECT Id,name FROM Product2 WHERE IsActive=true];
        for(Account acc: accList){
            if(acc.recordTypeId == '012020000000KwbAAE' || acc.recordTypeId == '012020000000MHfAAM'){
                for(product2 prod: prodList){
                    
                        Asset asset = new Asset();
                        asset.accountId = acc.id;
                        asset.product2Id = prod.id;
                        asset.name = prod.name;
                        assestList.add(asset);
                }
            }
        }

        if(!assestList.isEmpty())
            insert assestList;

    }
}
