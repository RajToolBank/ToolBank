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

}