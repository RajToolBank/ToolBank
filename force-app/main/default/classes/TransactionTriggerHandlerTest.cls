@isTest
public class TransactionTriggerHandlerTest {
    @isTest
    private static void testTransaction() {
        String recordTypeid  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Member Agency').getRecordTypeId();
        String recordTypeid2  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliate').getRecordTypeId();
        
        Id DONATION = Schema.SObjectType.Transaction__c.getRecordTypeInfosByDeveloperName().get('Donation').getRecordTypeId(); 
        Id INTERNAL_AUDIT = Schema.SObjectType.Transaction__c.getRecordTypeInfosByDeveloperName().get('Inventory_Audit').getRecordTypeId();
        Id LOST = Schema.SObjectType.Transaction__c.getRecordTypeInfosByDeveloperName().get('Lost').getRecordTypeId();
        Id PURCHASED = Schema.SObjectType.Transaction__c.getRecordTypeInfosByDeveloperName().get('Purchased').getRecordTypeId();
        Id BACK_IN_SERVICE = Schema.SObjectType.Transaction__c.getRecordTypeInfosByDeveloperName().get('Back_In_Service').getRecordTypeId();
        Id RETIRE = Schema.SObjectType.Transaction__c.getRecordTypeInfosByDeveloperName().get('Retired').getRecordTypeId();
        
        Account acc = TestDataFactory.createAccount('test',recordTypeid);
        Account affiliate = TestDataFactory.createAccount('test2',recordTypeid2);
        contact con = TestDataFactory.createContact(acc.Id);
        Zip_Code__c zipCode = TestDataFactory.createZipCode('14522');
        
        acc.parentId = affiliate.Id;
        update acc;
        
        Product2 tool = TestDataFactory.createProduct('Tool');
        PricebookEntry toolpbe = TestDataFactory.createPricebookEntry(tool.Id);
                
        List<Asset> asset = [Select Id FROM Asset limit 10];
        for(Asset asst: asset){
            asst.Total_Stock_Historical__c =  10;
            asst.Quantity = 10;
        }
        update asset;
        
        Order ord = TestDataFactory.createOrder(acc.Id,con.Id,affiliate.id);
        orderItem ordItem = TestDataFactory.createOrderItem(ord.Id,toolpbe.Id,asset[0].id);
        
        Transaction__c tran = TestDataFactory.createTransaction(asset[0].id, BACK_IN_SERVICE, 'Other');
        Transaction__c tran2 = TestDataFactory.createTransaction(asset[0].id, INTERNAL_AUDIT, 'Increase');
        Transaction__c tran2A = TestDataFactory.createTransaction(asset[0].id, INTERNAL_AUDIT, 'Decrease');
        Transaction__c tran3 = TestDataFactory.createTransaction(asset[0].id, DONATION, 'Corporate Donation');
        Transaction__c tran4 = TestDataFactory.createTransaction(asset[0].id, LOST, '');
        Transaction__c tran5 = TestDataFactory.createTransaction(asset[0].id, PURCHASED, 'Gift Card');
        Transaction__c tran6 = TestDataFactory.createTransaction(asset[0].id, RETIRE, 'Sold');
    }
}