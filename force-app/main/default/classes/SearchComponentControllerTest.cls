@isTest
public class SearchComponentControllerTest {
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
        
        String objectName = 'Account';
        List<String> fields = new List<String>{'Name', 'ParentId'};
            String searchTerm = 'Test';
        SearchComponentController.search(objectName, fields, searchTerm);
        SearchComponentController.search(objectName, fields, '');
        SearchComponentController.getRecentlyCreatedRecord(acc.Id, fields, objectName);
    }
}