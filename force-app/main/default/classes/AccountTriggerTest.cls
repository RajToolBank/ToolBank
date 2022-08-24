@isTest
public class AccountTriggerTest {
    
    @isTest
    private static void unitTest_1(){
        
        String recordTypeid  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliate').getRecordTypeId();
        TestDataFactory.createAccount('test',recordTypeid);
        Product2 tool = TestDataFactory.createProduct('Tool');
        PricebookEntry toolpbe = TestDataFactory.createPricebookEntry(tool.Id);
        

        TestDataFactory.createAccount('test3',recordTypeid);
        
    }
}