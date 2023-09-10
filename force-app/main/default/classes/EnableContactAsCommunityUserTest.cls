@isTest
public class EnableContactAsCommunityUserTest {
    

    @isTest
    private static void unitTest_1(){
        String recordTypeid  = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Member Agency').getRecordTypeId();
        Account acc = TestDataFactory.createAccount('test',recordTypeid);
        Contact con = TestDataFactory.createContact(acc.id);
        EnableContactAsCommunityUser.createCommuinityUser(con.id);
        EnableContactAsCommunityUser.resetPassword(con.id);
    }
}