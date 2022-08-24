@isTest
public class PaymentMemberTriggerTest {
    
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
        Credit__c credit1 =  TestDataFactory.createCredit(acc.Id,Null);
        Asset asset = [Select Id FROM Asset];
        asset.Total_Stock_Historical__c =  10;
        asset.Quantity = 10;
        update asset;
        Order ord = TestDataFactory.createOrder(acc.Id,con.Id,Affiliate.Id);
        orderItem ordItem = TestDataFactory.createOrderItem(ord.Id,toolpbe.Id,asset.id);
        Payments_TB__c payment = TestDataFactory.createpayment(ord);

        delete payment;
    }
}