@isTest
public class EnableContactAsCommunityUserTest {
    

    @isTest
    private static void unitTest_1(){
        String recordTypeid  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Member Agency').getRecordTypeId();
        String recordTypeidAff  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliate').getRecordTypeId();
        Account accAff = TestDataFactory.createAccount('Affiliate',recordTypeidAff);
        Account acc = TestDataFactory.createAccount('test',recordTypeid);
        acc.parentId = accAff.Id;
        update acc;
        Contact con = TestDataFactory.createContact(acc.id);
        con.npsp__Primary_Affiliation__c = acc.Id;
        update con;
        EnableContactAsCommunityUser.createCommuinityUser(con.id);
        EnableContactAsCommunityUser.resetPassword(con.id);
    }
    
     @isTest
    private static void unitTest_2(){
        String recordTypeid  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Member Agency').getRecordTypeId();
        String recordTypeidAff  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliate').getRecordTypeId();
        Account accAff = TestDataFactory.createAccount('Affiliate',recordTypeidAff);
        Account acc = TestDataFactory.createAccount('test',recordTypeid);
        acc.parentId = accAff.Id;
        update acc;
        Contact con = TestDataFactory.createContact(acc.id);
        con.npsp__Primary_Affiliation__c = acc.Id;
        update con;
        Test.startTest();
        EnableContactAsCommunityUser.createCommuinityUser(con.id);
        EnableContactAsCommunityUser.disableContact(con.id);
        EnableContactAsCommunityUser.disableContactFlag(con.id);
        Generic_Event__e  gEvent = new Generic_Event__e();
        gEvent.RecordId__c = con.id;
        EventBus.publish(gEvent);
        Test.stopTest();
    }
    
}