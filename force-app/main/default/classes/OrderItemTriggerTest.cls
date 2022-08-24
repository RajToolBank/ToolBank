@isTest
public class OrderItemTriggerTest {
 
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
        ordItem.Check_Out_Quantity__c = 5;
        update ordItem;

        OrderItemHelperClass.recursion = false;
        ordItem.Lost__c = 1;
        ordItem.Damaged__c = 1;
        ordItem.Check_In_Quantity__c = 3;
        update ordItem;

        OrderItemHelperClass.recursion = false;
        ordItem.Status__c = 'Confirmed';
        update ordItem;

        OrderItemHelperClass.recursion = false;
        ordItem.Status__c = 'Fulfilled';
        update ordItem;

        OrderItemHelperClass.recursion = false;
        ordItem.Status__c = 'Cancelled';
        update ordItem;

        OrderItemHelperClass.recursion = false;
        ordItem.Status__c = 'Overdue';
        update ordItem;

        OrderItemHelperClass.recursion = false;
        ordItem.Status__c = 'Returned';
        update ordItem;

        OrderItemHelperClass.recursion = false;
        ordItem.Status__c = 'Closed';
        update ordItem;

        OrderItemHelperClass.recursion = false;
        ordItem.Status__c = 'Unpaid';
        update ordItem;

        OrderItemHelperClass.recursion = false;
        ordItem.Status__c = 'Partially Returned';
        update ordItem;

    }
}