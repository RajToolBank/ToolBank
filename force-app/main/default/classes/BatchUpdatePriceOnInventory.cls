public without Sharing class BatchUpdatePriceOnInventory implements Database.Batchable<sObject>{
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([SELECT Id, product2Id,product2.Name,product2.ProductCode,product2.Family,product2.Description, UnitPrice FROM PricebookEntry WHERE Isactive = true and product2.Isactive = true]);
    }


    public void execute(Database.BatchableContext BC, List<PricebookEntry> pricebookEntryList) {  
        
        Map<Id, PricebookEntry> productIdToPbeMap = new Map<Id, PricebookEntry>();
        for(PricebookEntry pbe: pricebookEntryList){
            productIdToPbeMap.put(pbe.product2Id,pbe);
        }

        List<Asset> assetList = new List<Asset>();
        for(Asset asset: [SELECT Id, product2Id FROM Asset WHERE product2Id IN: productIdToPbeMap.keySet()]){
            Decimal unitPrice = productIdToPbeMap.get(asset.product2Id).UnitPrice;
            asset.Retail_Price__c = unitPrice;
            asset.Price = unitPrice;
            asset.Name =  productIdToPbeMap.get(asset.product2Id).product2.Name;
            asset.Description = productIdToPbeMap.get(asset.product2Id).product2.Description;
            assetList.add(asset);
        }

        if( assetList!= null && assetList.size() > 0)
            update assetList;

    }

    public void finish(Database.BatchableContext BC) {
    }

    @AuraEnabled
    public static String runBatch(){

        BatchUpdatePriceOnInventory obj = new BatchUpdatePriceOnInventory();
        Database.executeBatch(obj,200);
        return 'Success';
    }
}