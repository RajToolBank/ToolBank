@isTest
public class RK_BatchRollUpOrdersTest {
	@isTest
    private static void testPastOrder() {
        String recordTypeid  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Member Agency').getRecordTypeId();
        String recordTypeid2  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Affiliate').getRecordTypeId();
        Account acc = TestDataFactory.createAccount('test',recordTypeid);
        Account affiliate = TestDataFactory.createAccount('test2',recordTypeid2);
        contact con = TestDataFactory.createContact(acc.Id);
        acc.parentId = affiliate.Id;
        update acc;
        Order ord = TestDataFactory.createOrder(acc.Id,con.id,affiliate.Id);
        ord.Status = 'Confirmed';
        update ord;
        
        Test.startTest();
        RK_BatchRollUpOrdersSchedular sh1 = new RK_BatchRollUpOrdersSchedular();
        String sch = '0 0 1 * * ?'; 
        system.schedule('Orders Roll-up', sch, sh1);
        Test.stopTest();
    }
}