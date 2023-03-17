@isTest
public class BatchUpdatePriceOnInventoryTest {
    
    @isTest
    static void unitTest_1(){
        String recordTypeid  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Member Agency').getRecordTypeId();
        Account acc = TestDataFactory.createAccount('test',recordTypeid);
        String recordTypeid2  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliate').getRecordTypeId();
        
        contact con = TestDataFactory.createContact(acc.Id);
        Product2 tool = TestDataFactory.createProduct('Tool');
        Product2 tool2 = TestDataFactory.createProduct('Tool');
        PricebookEntry toolpbe = TestDataFactory.createPricebookEntry(tool.Id);
        PricebookEntry toolpbe2 = TestDataFactory.createPricebookEntry(tool2.Id);
        toolpbe.IsActive = true;
        toolpbe2.IsActive = true;
        update new List<PricebookEntry>{toolpbe,toolpbe2};
        Account affiliate = TestDataFactory.createAccount('test2',recordTypeid2);
        acc.parentId = affiliate.Id;
        update acc;
        affiliate.Affiliate_Handling_Fee__c = 3;
        update affiliate;
        List<Asset> asset = [Select Id FROM Asset];
        for(Asset asst: asset){
            asst.Total_Stock_Historical__c =  10;
            asst.Quantity = 10;
            
        }
        update asset;

        BatchUpdatePriceOnInventory.runBatch();
    }
}