@isTest
public class PlaceOrderControllerTest {
    @isTest
    private static void testPlaceOrder() {
        String recordTypeid  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Member Agency').getRecordTypeId();
        String recordTypeid2  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliate').getRecordTypeId();
        Account acc = TestDataFactory.createAccount('test',recordTypeid);
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
        
        String ordDetailJson = '{"name": "Test Order",'+
            '"zip": "14522",'+
            '"serv": "None of the above.",'+
            '"proVenue": ["Agency Facility", "Public Space or Venue", "Residence or Home"],'+
            '"proType": ["Demolition/Clearing", "Disaster Recovery/Response", "Environment Conservation"],'+
            '"impactArea": ["Animal Welfare", "Health", "Education"],'+
            '"accountId": "'+acc.Id+'",'+
            '"contactId": "'+con.Id+'",'+
            '"pickdate": "'+Date.today()+'",'+
            '"pickTime": "9:00 AM",'+
            '"retDate": "'+Date.today()+5+'",'+
            '"home": "5",'+
            '"duration": "1 week",'+
            '"affiliateid": "'+affiliate.Id+'",'+
            '"peopledirectlyserved": "1",'+
            '"numberProject": "1",'+
            '"onsitehours": "1",'+
            '"volunteersnumber": "1",'+
            '"peopleImImpacted": "1",'+
            '"staff": "1",'+
            '"projectVolunteerHr": "1",'+
            '"volunteersource": "General Community Volunteers",'+
            '"corpname": "Test Corporation"}';
        
        String ordToolJson = '['+ 
            '{"quantity": "2",'+
            '"retailPrice": "11.5",'+
            '"affiliatefee": "5.5",'+
            '"assetId": "'+asset[0].Id+'",'+
            '"pbeid": "'+toolpbe.Id+'"},'+
            '{"quantity": "2",'+
            '"retailPrice": "11.5",'+
            '"affiliatefee": "5.5",'+
            '"assetId": "'+asset[0].Id+'",'+
            '"pbeid": "'+toolpbe.Id+'"}]';
        
        String ordJson = '{"order": '+ordDetailJson+',"tools": '+ordToolJson+'}';
        
        Profile Prof = [Select Id from Profile where Name = 'TB Members' limit 1];
        User comunityUser = TestDataFactory.createCustomerUser(con,Prof);
        
        System.runAs(comunityUser) {
            Test.startTest();
            PlaceOrderController.getFlag();
            String accId = PlaceOrderController.accid();
            PlaceOrderController.UserClass us = PlaceOrderController.getAgencyContact('',accId);
            List<Account> accList = PlaceOrderController.getAffiliate();
            PlaceOrderController.returnAssets('',affiliate.Id);
            List<String> zipcodes = PlaceOrderController.zipCodes();
            PlaceOrderController.placeOrder(ordJson);
            PlaceOrderController.getBusinessHours(affiliate.Id);
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
        PlaceOrderController.getAgencyContact(acc.Id,affiliate.Id);
        PlaceOrderController.getAffiliate();
        PlaceOrderController.returnAssets('te',affiliate.Id);
        PlaceOrderController.zipCodes();
        PlaceOrderController.getPicklistValuesApex('Project_Type__c');
        Test.stopTest();
    }
}