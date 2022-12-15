@isTest
public class RK_AccountExpirationEmailAlertBatchTest {
    @testSetup static void setup() {
        Date setDate = Date.today()-335;
        Account acc = new Account(Name = 'Test Account', Approval_Date__c = setDate, Membership_Status__c = 'Active');
        insert acc;
        
        Contact con = new Contact(LastName = 'Test Contact', Email = 'test@test.com', Primary_Contact__c = true, AccountId = acc.Id);
        insert con;
    }
    @isTest static void testBatchClass() {
        Test.startTest();
        Database.executeBatch(new RK_AccountExpirationEmailAlertBatch());
        Test.stopTest();
    }
    @isTest static void testScheduleClass(){
        Test.startTest();
        String CRON_EXP = '0 0 1 * * ?';
        String jobId = System.schedule('JobName', CRON_EXP, new RK_AccountExpirationEmailAlertSch());
        Test.stopTest();
    }
}