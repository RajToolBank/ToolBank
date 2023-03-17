@isTest
public class CreateTransactionTest implements HttpCalloutMock {
    
    @isTest
    static void createTransactionTest(){
     
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

        List<CreateTransaction.PickListOption> recordTypeOptionList = CreateTransaction.getRecordType();
        String recordTypeid3  = Schema.SObjectType.Transaction__c.getRecordTypeInfosByName().get('Donation').getRecordTypeId();
        Test.setMock(HttpCalloutMock.class, new CreateTransactionTest());
        Test.startTest();
        CreateTransaction.getValues('Transaction__C', recordTypeid3, 'Sub_type__c');
        CreateTransaction.CreateTransaction(asset[0].Id, recordTypeid3, 'Corporate Donation', 3, 'test');
        Test.stopTest();
    }

    public HTTPResponse respond(HTTPRequest req) {
        
        HTTPResponse res = new HTTPResponse();
        res.setStatusCode(200);
        res.setStatus('OK');
        res.setbody(    '{"values":[{'
                        +'"label":"Maintenance",'
                        +'"value": "Maintenance"'
                        +'},'
                        +'{'
                        +'"label": "Rebranding",'
                        +'"value": "Rebranding"'
                        +'}]}');

        return res;

    }
}