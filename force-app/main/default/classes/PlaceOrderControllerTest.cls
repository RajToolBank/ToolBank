@isTest
public class PlaceOrderControllerTest {
	@isTest
    private static void testPlaceOrder() {
        String recordTypeid  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Member Agency').getRecordTypeId();
        String recordTypeid2  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliate').getRecordTypeId();
        Account acc = TestDataFactory.createAccount('test',recordTypeid);
        Account affiliate = TestDataFactory.createAccount('test2',recordTypeid2);
        
        contact con = TestDataFactory.createContact(acc.Id);
        
        acc.parentId = affiliate.Id;
        update acc;
        
        Product2 tool = TestDataFactory.createProduct('Tool');
        Product2 tool2 = TestDataFactory.createProduct('Tool');
        PricebookEntry toolpbe = TestDataFactory.createPricebookEntry(tool.Id);
        PricebookEntry toolpbe2 = TestDataFactory.createPricebookEntry(tool2.Id);
        
        List<Asset> asset = [Select Id FROM Asset];
        for(Asset asst: asset){
            asst.Total_Stock_Historical__c =  10;
            asst.Quantity = 10;
            
        }
        update asset;
        
        Order ord = TestDataFactory.createOrder(acc.Id,con.Id,affiliate.id);
        orderItem ordItem = TestDataFactory.createOrderItem(ord.Id,toolpbe.Id,asset[0].id);
        Order ord2 = TestDataFactory.createOrder(acc.Id,con.Id,affiliate.id);
        orderItem ordItem2 = TestDataFactory.createOrderItem(ord2.Id,toolpbe.Id,asset[0].id);
        
        List<orderItem> ordItemList = new List<orderItem>{ordItem};
        List<order> orderList = new List<order>{ord};

        String ordDetailJson = '{"name": "ordName","zip": "zip"}';
        String ordToolJson = '{"name": "ordName","zip": "zip"}';
        String ordJson = '{"order": '+ordDetailJson+',"tools": '+ordToolJson+'}';
        
        Profile Prof = [Select Id from Profile where Name = 'TB Members' limit 1];
        User comunityUser = TestDataFactory.createCustomerUser(con,Prof);
        
        System.runAs(comunityUser) {
            
            Test.startTest();
            String accId = PlaceOrderController.accid();
            User us = PlaceOrderController.getAgencyContact();
            List<Account> accList = PlaceOrderController.getAffiliate();
            PlaceOrderController.returnAssets('te',affiliate.Id);
            List<String> zipcodes = PlaceOrderController.zipCodes();
            PlaceOrderController.placeOrder(JSON.serialize(ordJson));
            Test.stopTest();
        }
    }
    
    @isTest
    private static void testPlaceOrder2() {
        String recordTypeid  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Member Agency').getRecordTypeId();
        String recordTypeid2  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliate').getRecordTypeId();
        Account acc = TestDataFactory.createAccount('test',recordTypeid);
        Account affiliate = TestDataFactory.createAccount('test2',recordTypeid2);
        
        contact con = TestDataFactory.createContact(acc.Id);
        
        acc.parentId = affiliate.Id;
        update acc;
        
        Affiliate_Account__c affAcc = TestDataFactory.createAffiliateAccount(acc.Id);
        affAcc.user__c = UserInfo.getUserId();
        update affAcc;
        
        Product2 tool = TestDataFactory.createProduct('Tool');
        Product2 tool2 = TestDataFactory.createProduct('Tool');
        PricebookEntry toolpbe = TestDataFactory.createPricebookEntry(tool.Id);
        PricebookEntry toolpbe2 = TestDataFactory.createPricebookEntry(tool2.Id);
        
        Test.startTest();
        PlaceOrderController.accid();
        PlaceOrderController.getAgencyContact();
        PlaceOrderController.getAffiliate();
        PlaceOrderController.returnAssets('te',affiliate.Id);
        PlaceOrderController.zipCodes();
        //PlaceOrderController.placeOrder(JSON.serialize(ordcls));
        Test.stopTest();
    }
}