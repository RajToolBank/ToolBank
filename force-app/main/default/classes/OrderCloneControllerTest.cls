@isTest
public class OrderCloneControllerTest {
    
    @isTest
    static void cloneOrderTest(){
        String recordTypeid  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Member Agency').getRecordTypeId();
        Account acc = TestDataFactory.createAccount('test',recordTypeid);
        String recordTypeid2  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliate').getRecordTypeId();
        
        contact con = TestDataFactory.createContact(acc.Id);
        Product2 tool = TestDataFactory.createProduct('Tool');
        Product2 tool2 = TestDataFactory.createProduct('Tool');
        PricebookEntry toolpbe = TestDataFactory.createPricebookEntry(tool.Id);
        PricebookEntry toolpbe2 = TestDataFactory.createPricebookEntry(tool2.Id);
        Account affiliate = TestDataFactory.createAccount('test2',recordTypeid2);
        acc.parentId = affiliate.Id;
        update acc;
        affiliate.Affiliate_Handling_Fee__c = 3;
        update affiliate;
        List<Asset> asset = [Select Id FROM Asset];
        for(Asset asst: asset){
            asst.Total_Stock_Historical__c =  10;
            asst.Quantity = 10;
            
        }
        update asset;
        Order ord2 = TestDataFactory.createOrder(acc.Id,con.Id,affiliate.id);
        orderItem ordItem2 = TestDataFactory.createOrderItem(ord2.Id,toolpbe.Id,asset[0].id);
        OrderCloneController.cloneOrder(ord2.Id,Date.today().addDays(10),'9:00 AM','2 weeks');
        OrderCloneController.getBusinessHours(ord2.Id);
    }
}