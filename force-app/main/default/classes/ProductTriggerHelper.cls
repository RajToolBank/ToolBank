public with sharing class ProductTriggerHelper {
   

    public static void createInventories(List<Product2> prodList){


        List<Asset> assestList=new List<Asset>();
        for(Account acc: [SELECT id FROM Account WHERE recordTypeId = '012020000000KwbAAE' OR recordTypeId = '012020000000MHfAAM']){
            for(Product2 prod: prodList){
                Asset asset = new Asset();
                asset.accountId = acc.id;
                asset.product2Id = prod.id;
                asset.name = prod.name;
                assestList.add(asset);
            }
        }

        if(!assestList.isEmpty())
            insert assestList;
    }
}
