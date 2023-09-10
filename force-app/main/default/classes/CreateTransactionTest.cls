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
        Account affiliate1 = TestDataFactory.createAccount('test1',recordTypeid2);
        Account affiliate2 = TestDataFactory.createAccount('test2',recordTypeid2);
        acc.parentId = affiliate2.Id;
        update acc;
        affiliate2.Affiliate_Handling_Fee__c = 3;
        update affiliate2;
        Asset ast = new Asset(Name = 'test', Product2Id = tool.Id, AccountId = affiliate1.Id, Quantity = 10);
        insert ast;
        //List<Asset> asset = [Select Id FROM Asset];

        List<CreateTransaction.PickListOption> recordTypeOptionList = CreateTransaction.getRecordType();
        String recordTypeid3  = Schema.SObjectType.Transaction__c.getRecordTypeInfosByName().get('Transfer').getRecordTypeId();
        String recordTypeid4  = Schema.SObjectType.Transaction__c.getRecordTypeInfosByName().get('Inventory Audit').getRecordTypeId();
        Test.setMock(HttpCalloutMock.class, new CreateTransactionTest());
        Test.startTest();
        CreateTransaction.getValues('Transaction__C', recordTypeid3, 'Sub_type__c');
        CreateTransaction.CreateTransaction(ast.Id, recordTypeid3, 'Decrease', 3, 'test',affiliate2.Id);
        CreateTransaction.CreateTransaction(ast.Id, recordTypeid4, 'Increase', 3, 'test',affiliate2.Id);
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