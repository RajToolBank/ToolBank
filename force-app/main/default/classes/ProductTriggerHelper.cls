public with sharing class ProductTriggerHelper {
   

    public static void createInventories(List<Product2> prodList){


        List<Asset> assestList=new List<Asset>();
        List<String> recordTypeIds = label.Affiliate_Record_Type_Ids.split(';');
        for(Account acc: [SELECT id FROM Account WHERE recordTypeId IN:recordTypeIds]){
            for(Product2 prod: prodList){
                if( prod.Type__c !='Additional Charges'){
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