@isTest
public class ReturnOrderControllerTest {
    @isTest
    private static void testReturnOrder() {
        String recordTypeid  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Member Agency').getRecordTypeId();
        String recordTypeid2  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliate').getRecordTypeId();
        Account acc = TestDataFactory.createAccount('test', recordTypeid);
        Account affiliate = TestDataFactory.createAccount('test2',recordTypeid2);
        contact con = TestDataFactory.createContact(acc.Id);
        Zip_Code__c zipCode = TestDataFactory.createZipCode('14522');
        
        acc.parentId = affiliate.Id;
        update acc;
        
        Product2 tool = TestDataFactory.createProduct('Tool');
        Product2 tool2 = TestDataFactory.createProduct('Tool');
        PricebookEntry toolpbe = TestDataFactory.createPricebookEntry(tool.Id);
        PricebookEntry toolpbe2 = TestDataFactory.createPricebookEntry(tool2.Id);
        
        List<Asset> asset = [Select Id FROM Asset limit 10];
        for(Asset asst: asset){
            asst.Total_Stock_Historical__c =  10;
            asst.Quantity = 10;
        }
        update asset;
        
        Order ord = TestDataFactory.createOrder(acc.Id,con.Id,affiliate.id);
        orderItem ordItem = TestDataFactory.createOrderItem(ord.Id,toolpbe.Id,asset[0].id);
        Order ord2 = TestDataFactory.createOrder(acc.Id,con.Id,affiliate.id);
        orderItem ordItem2 = TestDataFactory.createOrderItem(ord2.Id,toolpbe.Id,asset[0].id);
        
        String ordItemJson = '['+
            '{"Id": "'+ordItem.Id+'",'+
            '"assetId": "'+asset[0].Id+'",'+
            '"unitPrice": "5.0",'+
            '"orderid": "'+ord.Id+'",'+
            '"borrowed": 5,'+
            '"pbeid": "'+toolpbe.Id+'",'+
            '"affiliatefee": "50.0",'+
            '"lost": 1,'+
            '"damaged": 1,'+
            '"returnqty": 1,'+
            '"borrowedPeriod": "1 week",'+
            '"status": "Returned",'+
            '"returnDate": "'+Date.today()+5+'",'+
            '"EffectiveDate": "'+Date.today()+'"},'+
            '{"Id": "'+ordItem2.Id+'",'+
            '"assetId": "'+asset[0].Id+'",'+
            '"unitPrice": "5.0",'+
            '"orderid": "'+ord2.Id+'",'+
            '"borrowed": 5,'+
            '"pbeid": "'+toolpbe.Id+'",'+
            '"affiliatefee": "50.0",'+
            '"lost": 1,'+
            '"damaged": 1,'+
            '"returnqty": 1,'+
            '"borrowedPeriod": "1 week",'+
            '"status": "Returned",'+
            '"returnDate": "'+Date.today()+5+'",'+
            '"EffectiveDate": "'+Date.today()+'"}]';
        
        Profile Prof = [Select Id from Profile where Name = 'TB Members' limit 1];
        User comunityUser = TestDataFactory.createCustomerUser(con,Prof);
        
        ReturnOrderController.saveOrder(ordItemJson);
        
        System.runAs(comunityUser) {
            Test.startTest();
            ReturnOrderController.getOrderItems(ord.Id);
            //ReturnOrderController.saveOrder(ordItemJson);
            Test.stopTest();
        }
    }
}