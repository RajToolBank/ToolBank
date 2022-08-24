@isTest
public class CreditTriggerTest {
    
    @isTest
    private static void unitTest_1(){
        String recordTypeid  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Member Agency').getRecordTypeId();
        Account acc = TestDataFactory.createAccount('name',recordTypeid);
        Credit__c credit1 =  TestDataFactory.createCredit(acc.Id,Date.today());
        Credit__c credit2 = TestDataFactory.createCredit(acc.Id,Date.today().addDays(2));
        credit1.Amount__c = 105;
        credit2.isActive__c = false;
        update credit1;
    }

    @isTest
    private static void unitTest_2(){
        String recordTypeid  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Member Agency').getRecordTypeId();
        Account acc = TestDataFactory.createAccount('name',recordTypeid);
        Credit__c credit2 = TestDataFactory.createCredit(acc.Id,Date.today().addDays(2));
        credit2.isActive__c = false;
        update credit2;

        credit2.isActive__c = true;
        update credit2;

        delete credit2;
    }
}