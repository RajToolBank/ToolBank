@isTest
public class CreditExpirationHandlerBatchTest {
    
    @isTest
    private static void unitTest_1(){
        String recordTypeid  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Member Agency').getRecordTypeId();
        Account acc = TestDataFactory.createAccount('name',recordTypeid);
        TestDataFactory.createCredit(acc.Id,Date.today().addDays(-2));
        TestDataFactory.createCredit(acc.Id,Date.today().addDays(2));

        CreditExpirationHandlerBatch obj = new CreditExpirationHandlerBatch();

        Database.executebatch(obj,200);
    }

    @isTest
    private static void unitTest_2(){
        String recordTypeid  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Member Agency').getRecordTypeId();
        Account acc = TestDataFactory.createAccount('name',recordTypeid);
        TestDataFactory.createCredit(acc.Id,Date.today());
        TestDataFactory.createCredit(acc.Id,Date.today().addDays(-2));

        CreditExpirationHandlerBatchScheduler obj = new CreditExpirationHandlerBatchScheduler();
        String sch = '20 30 8 10 2 ?';
        String jobID = system.schedule('Merge Job', sch, obj);
    }
}