@isTest
public class FileControllerTest {
    
    @isTest
    static void unitTest_1(){
        // Create test data
        String recordTypeid  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Member Agency').getRecordTypeId();
        String recordTypeid2  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliate').getRecordTypeId();
        Account acc = TestDataFactory.createAccount('test',recordTypeid);
        Account affiliate = TestDataFactory.createAccount('test2',recordTypeid2);
        contact con = TestDataFactory.createContact(acc.Id);
        Zip_Code__c zipCode = TestDataFactory.createZipCode('14522');
        
        acc.parentId = affiliate.Id;
        update acc;
        
        Product2 tool = TestDataFactory.createProduct('Tool');
        Product2 tool2 = TestDataFactory.createProduct('Tool');
        PricebookEntry toolpbe = TestDataFactory.createPricebookEntry(tool.Id);
        PricebookEntry toolpbe2 = TestDataFactory.createPricebookEntry(tool2.Id);
        
        List<Asset> asset = [Select Id FROM Asset limit 10];
        for(Asset asst: asset){
            asst.Total_Stock_Historical__c =  10;
            asst.Quantity = 10;
        }
        update asset;
        
        Order ord = TestDataFactory.createOrder(acc.Id,con.Id,affiliate.id);
        orderItem ordItem = TestDataFactory.createOrderItem(ord.Id,toolpbe.Id,asset[0].id);
        
        ContentVersion conVer = new ContentVersion();
        conVer.ContentLocation = 'S';
        conVer.PathOnClient = 'Payment_Receipt_'+Date.today().format()+'.png';
        conVer.Title = 'Payment_Receipt_'+Date.today().format()+'.png'+'_sponsored';
        conVer.Active__c = true;
        conVer.VersionData = EncodingUtil.base64Decode('blob');
        insert conVer; 
        
        Id conDoc = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:conVer.Id].ContentDocumentId;
        
        ContentDocumentLink conDocLink = New ContentDocumentLink();
        conDocLink.LinkedEntityId = affiliate.Id;
        conDocLink.ContentDocumentId = conDoc;  //ContentDocumentId Id from ContentVersion
        conDocLink.shareType = 'V';
        insert conDocLink;
        
        List<Object> fileUpload = new List<Object>();
        Map<String, Object> file1 = new Map<String, Object>{
            'name' => 'TestFile1',
            'contentVersionId' => conVer.Id,
            'documentId' => conDoc
        };
        fileUpload.add(file1);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(ord);
        PaymentReceipt_Ctrl obj = new PaymentReceipt_Ctrl(sc);
        
        // Call the method to test
        Test.startTest();
        Boolean isAffiliate = PaymentReceipt_Ctrl.checkAffiliate(affiliate.Id);
        PaymentReceipt_Ctrl.uploadFiles(JSON.serialize(fileUpload));
        FileController.getFilesByAccount(affiliate.Id);
        List<Object> fileUpdate = new List<Object>();
        Map<String, Object> file2 = new Map<String, Object>{
            'fileId' => conVer.Id,
            'isActive' => false
        };
        fileUpdate.add(file2);
        FileController.updateFileRecords(JSON.serialize(fileUpdate));
        Test.stopTest();
    }
}