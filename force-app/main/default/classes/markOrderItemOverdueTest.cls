@isTest
public class markOrderItemOverdueTest {
    
    @isTest
    private static void unitTest_1(){

        String recordTypeid  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Member Agency').getRecordTypeId();
        Account acc = TestDataFactory.createAccount('test',recordTypeid);
        String recordTypeid2  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliate').getRecordTypeId();
        
        contact con = TestDataFactory.createContact(acc.Id);
        Product2 tool = TestDataFactory.createProduct('Tool');
        Product2 addCharges = TestDataFactory.createProduct('Additional Charges');
        PricebookEntry toolpbe = TestDataFactory.createPricebookEntry(tool.Id);
        PricebookEntry pbeAdd = TestDataFactory.createPricebookEntry(addCharges.Id);
        Account Affiliate = TestDataFactory.createAccount('test2',recordTypeid2);
        Asset asset = [Select Id FROM Asset];
        asset.Total_Stock_Historical__c =  10;
        asset.Quantity = 10;
        update asset;
        Order ord = TestDataFactory.createOrder(acc.Id,con.Id,Affiliate.Id);
        orderItem ordItem = TestDataFactory.createOrderItem(ord.Id,toolpbe.Id,asset.id);
        TestDataFactory.createOrderItem(ord.Id,pbeAdd.Id,Null);

        ordItem.status__c = 'Fulfilled';
        ordItem.Schedule_Return_Date__c = Date.today().addDays(-2);

        update ordItem;

        markOrderItemOverdue obj = new markOrderItemOverdue();
        Database.executeBatch(obj,200);

        Test.startTest();
        markOrderItemOverdue sh1 = new markOrderItemOverdue();
        String sch = '0 0 1 * * ?'; 
        system.schedule('Orders overdue', sch, sh1);
        Test.stopTest();
    }
}