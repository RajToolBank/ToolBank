@isTest
public with sharing class OrderCancelledCmpControllerTest {
    

    @isTest
    static void unitTest_1(){

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
        OrderCancelledCmpController.cancelOrder(ord.Id);
        OrderCancelledCmpController.cancelOrder(ord.Id);
        ord.status = 'Unconfirmed';
        update ord;
        OrderCancelledCmpController.deleteOrder(ord.Id);
        
        //OrderCancelledCmpController.deleteOrder(ord.Id);
    }


    @isTest
    static void unitTest_2(){

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
        OrderCancelledCmpController.cancelOrder(ord.Id);
        OrderCancelledCmpController.deleteOrder(ord.Id);
        
    }

    @isTest
    static void unitTest_3(){

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
        OrderCancelledCmpController.cancelOrder(ord.Id);
        OrderCancelledCmpController.deleteOrder(ord.Id);

        Profile Prof = [Select Id from Profile where Name = 'TB Members' limit 1];
        TestDataFactory.createCustomerUser(con,Prof);
        user comunityUser = [SELECT Id,contact.account.parentId FROM User where contactId != null AND Profile.Name ='TB Members' and isActive = true limit 1];
system.debug('comunityUser :: '+comunityUser);
        System.runAs(comunityUser) {
            OrderCancelledCmpController.cancelOrder(ord.Id);
            OrderCancelledCmpController.deleteOrder(ord.Id);
        }
        
    }

}