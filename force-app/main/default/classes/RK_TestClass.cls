@isTest
public class RK_TestClass {
    @isTest
    private static void testUpcomingOrder() {
        String recordTypeid  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Member Agency').getRecordTypeId();
        String recordTypeid2  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliate').getRecordTypeId();
        Account acc = TestDataFactory.createAccount('test',recordTypeid);
        Account affiliate = TestDataFactory.createAccount('test2',recordTypeid2);
        
        contact con = TestDataFactory.createContact(acc.Id);
        
        acc.parentId = affiliate.Id;
        update acc;
        
        Profile Prof = [Select Id from Profile where Name = 'TB Members' limit 1];
        TestDataFactory.createCustomerUser(con,Prof);
        user comunityUser = [SELECT Id,contactId FROM User where contactId = :con.Id AND Profile.Name ='TB Members' and isActive = true limit 1];
        
        System.runAs(comunityUser) {
            
            Test.startTest();
            PageReference myVfPage = Page.UpcomingOrderInfo;
            Test.setCurrentPage(myVfPage); 
            UpcomingOrderInfo_Ctrl controller = new UpcomingOrderInfo_Ctrl();
            controller.navigatePage();
            controller.viewAllPage();
            Test.stopTest();
        }
    }
    
    @isTest
    private static void testPastOrder() {
        String recordTypeid  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Member Agency').getRecordTypeId();
        String recordTypeid2  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliate').getRecordTypeId();
        Account acc = TestDataFactory.createAccount('test',recordTypeid);
        Account affiliate = TestDataFactory.createAccount('test2',recordTypeid2);
        
        contact con = TestDataFactory.createContact(acc.Id);
        
        acc.parentId = affiliate.Id;
        update acc;
        
        Profile Prof = [Select Id from Profile where Name = 'TB Members' limit 1];
        TestDataFactory.createCustomerUser(con,Prof);
        user comunityUser = [SELECT Id FROM User where contactId = :con.Id AND Profile.Name ='TB Members' and isActive = true limit 1];
        
        System.runAs(comunityUser) {
            
            Test.startTest();
            PageReference myVfPage = Page.PastOrderInfo;
            Test.setCurrentPage(myVfPage); 
            PastOrderInfo_Ctrl controller = new PastOrderInfo_Ctrl();
            controller.navigatePage();
            controller.viewAllPage();
            Test.stopTest();
        }
    }
    
    @isTest
    private static void testShowAccounts() {
        String recordTypeid  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Member Agency').getRecordTypeId();
        String recordTypeid2  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliate').getRecordTypeId();
        Account acc = TestDataFactory.createAccount('test',recordTypeid);
        Account affiliate = TestDataFactory.createAccount('test2',recordTypeid2);
        
        contact con = TestDataFactory.createContact(acc.Id);
        
        acc.parentId = affiliate.Id;
        update acc;
        
        Profile Prof = [Select Id from Profile where Name = 'TB Members' limit 1];
		TestDataFactory.createCustomerUser(con,Prof);
        user comunityUser = [SELECT Id FROM User where contactId = :con.Id AND Profile.Name ='TB Members' and isActive = true limit 1];
        
        System.runAs(comunityUser) {
            
            Test.startTest();
            List<Contact> conList = new List<Contact>();
            conList.add(con);
            PageReference myVfPage = Page.show_AccountsinCommunity;
            myVfPage.getParameters().put('id', String.valueOf(acc.Id));
            Test.setCurrentPage(myVfPage); 
            ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(conList);
            show_AccountsinCommunityCtrl controller = new show_AccountsinCommunityCtrl();
            controller.conEdit = con.Id;
            controller.showSec();
            controller.insertContact();
            controller.editContact();
            controller.updateContact();
            controller.cancelContact();
            controller.viewAllContacts();
            controller.getContacts();
            controller.goBack();
            controller.editAccount();
            controller.saveAccount();
            controller.cancelAccount();
            Test.stopTest();
        }
    }
    
    @isTest
    private static void testContactUs() {
        String recordTypeid  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Member Agency').getRecordTypeId();
        String recordTypeid2  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliate').getRecordTypeId();
        Account acc = TestDataFactory.createAccount('test',recordTypeid);
        Account affiliate = TestDataFactory.createAccount('test2',recordTypeid2);
        
        contact con = TestDataFactory.createContact(acc.Id);
        
        acc.parentId = affiliate.Id;
        update acc;
        
        Profile Prof = [Select Id from Profile where Name = 'TB Members' limit 1];
        TestDataFactory.createCustomerUser(con,Prof);
        user comunityUser = [SELECT Id,contact.account.parentId FROM User where contactId != null AND Profile.Name ='TB Members' and isActive = true limit 1];
system.debug('comunityUser :: '+comunityUser);
        System.runAs(comunityUser) {
            Account affiliateAcc = new Account(Id = comunityUser.contact.account.parentId);
            affiliateAcc.Name = 'ToolBank_Training_Org';
        	//update affiliateAcc;
            
            Test.startTest();
            PageReference myVfPage = Page.RK_ContactUSCommunityPage;
            myVfPage.getParameters().put('id', String.valueOf(acc.Id));
            Test.setCurrentPage(myVfPage); 
            RK_ContactUs controller = new RK_ContactUs();
            controller.getListBusinessHours();
            Test.stopTest();
        }
    }
}