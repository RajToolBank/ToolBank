@isTest
public class OrderCancelOrItemDeleteControllerTest {
    
    
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
        
        ord.status = 'Cancelled';
        OrderCancelOrItemDeleteController.orderRecursion = false;
        update ord;
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
        asset.Quantity = 7;
        update asset;
        Order ord = TestDataFactory.createOrder(acc.Id,con.Id,Affiliate.Id);
        orderItem ordItem = TestDataFactory.createOrderItem(ord.Id,toolpbe.Id,asset.id);
        
        Order ord2 = TestDataFactory.createOrder(acc.Id,con.Id,Affiliate.Id);
        orderItem ordItem2 = TestDataFactory.createOrderItem(ord2.Id,toolpbe.Id,asset.id);
        
        Order ord3 = TestDataFactory.createOrder(acc.Id,con.Id,Affiliate.Id);
        orderItem ordItem3 = TestDataFactory.createOrderItem(ord3.Id,toolpbe.Id,asset.id);
        
        
        ord2.status = 'Cancelled';
        system.debug('itemlist from Test: '+[SELECT Id, LastModifiedDate FROM orderItem]);
        update ord2;
        
        
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
        asset.Quantity = 7;
        update asset;
        Order ord = TestDataFactory.createOrder(acc.Id,con.Id,Affiliate.Id);
        orderItem ordItem = TestDataFactory.createOrderItem(ord.Id,toolpbe.Id,asset.id);
        
        Order ord2 = TestDataFactory.createOrder(acc.Id,con.Id,Affiliate.Id);
        orderItem ordItem2 = TestDataFactory.createOrderItem(ord2.Id,toolpbe.Id,asset.id);
        
        
        delete ordItem2;
        
    }
    @isTest
    static void unitTest_4(){
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
        asset.Quantity = 7;
        update asset;
        Order ord = TestDataFactory.createOrder(acc.Id,con.Id,Affiliate.Id);
        orderItem ordItem = TestDataFactory.createOrderItem(ord.Id,toolpbe.Id,asset.id);
        
        Order ord2 = TestDataFactory.createOrder(acc.Id,con.Id,Affiliate.Id);
        orderItem ordItem2 = TestDataFactory.createOrderItem(ord2.Id,toolpbe.Id,asset.id);
        
        List<Task> taskList = new List<Task>();
        Task tas = new Task(WhatId = ord2.Id, type = 'Return', ActivityDate = Date.today(), Subject = ord2.OrderNumber+' - Return Task');
        taskList.add(tas);
        Task tas2 = new Task(WhatId = ord2.Id, type = 'Pick-Up', ActivityDate = Date.today(), Subject = ord2.OrderNumber+' - Pick-Up Task');
        taskList.add(tas2);
        insert taskList;
        
        ord.status = 'Confirmed';
        ord2.status = 'Confirmed';
        ord.EffectiveDate = Date.today();
        ord.Scheduled_Pickup_Time__c = DateTime.now().time();
        ord2.EffectiveDate = Date.today();
        ord2.Scheduled_Pickup_Time__c = DateTime.now().time();
        update ord;
        update ord2;
        ord.status = 'Fulfilled';
        ord2.status = 'Fulfilled';
        update ord;
        update ord2;
        ord.status = 'Returned';
        ord2.status = 'Returned';
        update ord;
        update ord2;
    }
}