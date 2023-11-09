public class UndeleteHouseholdMemberTests {

    public static String ERROR_MSG_UNDELETE_DUPLICATE = ' custom uniqueness constraint would be violated by the proposed operation';

    public static testMethod void memberLimitUndelete_1_20() {

        Household__c h = new Household__c(name='HouseholdTest');
        insert h;

        Integer numMembers = 20;
        Account[] accs = new Account[numMembers];
        for (Integer i = 0; i < numMembers; i++){
            Account a = new Account(name = 'test');
            accs[i] = a;
        }
        insert accs;
        HouseholdMember__c[] members = new HouseholdMember__c[numMembers];
        HouseholdMember__c hm;
        for (Integer i = 0; i < numMembers; i++){
            hm = new HouseholdMember__c(Household__c=h.Id,Account__c=accs[i].Id);
            members[i] = hm;
        }


        insert members;
        HouseholdTrigger.assertNumMembers(h, 20);
        delete members;
        Account a = new Account(name='test');
        insert a;
        hm = new HouseholdMember__c(Household__c=h.Id,Account__c=a.Id);
        insert hm;
        HouseholdTrigger.assertNumMembers(h, 1);

        try {
            undelete members;
        } catch (Exception e) {

        }
        HouseholdTrigger.assertNumMembers(h, 1);
    }

    public static testMethod void memberLimitUndelete_21() {
        Household__c h = new Household__c(name='HouseholdTest');
        insert h;

        Integer numMembers = 20;
        Account[] accs = new Account[numMembers];
        for (Integer i = 0; i < numMembers; i++){
            Account a = new Account(name = 'test');
            accs[i] = a;
        }
        insert accs;
        HouseholdMember__c[] members = new HouseholdMember__c[numMembers];
        for (Integer i = 0; i < numMembers; i++){

            HouseholdMember__c hm = new HouseholdMember__c(Household__c=h.Id,Account__c=accs[i].Id);
            members[i] = hm;
        }

        insert members;
        delete members;
        Account a = new Account(name='test');
        insert a;
        HouseholdMember__c hm = new HouseholdMember__c(Household__c=h.Id,Account__c=a.Id);
        insert hm;
        delete hm;
        try {
            HouseholdMember__c[] temp = members;
            temp.add(hm);
            undelete temp;
        } catch (DMLException e){
            System.assert(e.getMessage().contains(HouseholdTrigger.ERROR_MSG_MAX_MEMBERS));
        }
        HouseholdTrigger.assertNumMembers(h, 0);
    }

    public static testMethod void memberLimitUndelete_20_1() {
        Household__c h = new Household__c(name='HouseholdTest');
        insert h;

        Integer numMembers = 20;
        Account[] accs = new Account[numMembers];
        for (Integer i = 0; i < numMembers; i++){
            Account a = new Account(name = 'test');
            accs[i] = a;
        }
        insert accs;
        HouseholdMember__c[] members = new HouseholdMember__c[numMembers];
        for (Integer i = 0; i < numMembers; i++){

            HouseholdMember__c hm = new HouseholdMember__c(Household__c=h.Id,Account__c=accs[i].Id);
            members[i] = hm;
        }
        insert members;

        HouseholdTrigger.assertNumMembers(h, 20);
        delete members;
        Account a = new Account(name='test');
        insert a;

        HouseholdMember__c hm = new HouseholdMember__c(Household__c=h.Id,Account__c=a.Id);
        insert hm;
        try {
            undelete members;
            System.assert(false);
        } catch (System.DmlException e){
            System.assert(e.getMessage().contains(HouseholdTrigger.ERROR_MSG_MAX_MEMBERS));
        }

        HouseholdTrigger.assertNumMembers(h, 1);
    }

    static testMethod void primaryMemberUndeleteDuplicate(){
        Household__c h = new Household__c(name='HouseholdTest');
        insert h;
        Account a1 = new Account(name='test');
        insert a1;
        Account a2 = new Account(name='test');
        insert a2;

        HouseholdMember__c hm1 = new HouseholdMember__c(Household__c=h.Id,Account__c=a1.Id, isPrimary__c = true);
        insert hm1;
        HouseholdTrigger.assertPrimary(h, a1);
        delete hm1;
        HouseholdMember__c hm2 = new HouseholdMember__c(Household__c=h.Id,Account__c=a2.Id, isPrimary__c = true);
        insert hm2;
        HouseholdTrigger.assertPrimary(h, a2);
        try {
            undelete hm1;
        } catch (DMLException e) {
            System.assert(e.getMessage().contains(HouseholdTrigger.ERROR_MSG_DUPLICATE_CONTACTS));
        }
        HouseholdTrigger.assertPrimary(h, a2);
    }

    static testMethod void secondaryMemberUndeleteDuplicate(){
        Household__c h = new Household__c(name='HouseholdTest');
        insert h;
        Account a1 = new Account(name='test');
        insert a1;
        Account a2 = new Account(name='test');
        insert a2;

        HouseholdMember__c hm1 = new HouseholdMember__c(Household__c=h.Id,Account__c=a1.Id, isSecondary__c = true);
        insert hm1;
        HouseholdTrigger.assertSecondary(h, a1);
        delete hm1;
        HouseholdMember__c hm2 = new HouseholdMember__c(Household__c=h.Id,Account__c=a2.Id, isSecondary__c = true);
        insert hm2;
        HouseholdTrigger.assertSecondary(h, a2);
        try {
            undelete hm1;
        } catch (DMLException e) {
            System.assert(e.getMessage().contains(HouseholdTrigger.ERROR_MSG_DUPLICATE_CONTACTS));
        }
        HouseholdTrigger.assertSecondary(h, a2);
    }

    static testMethod void primarySecondaryMemberUndeleteBothDuplicates(){
        Household__c h = new Household__c(name='HouseholdTest');
        insert h;
        Account a1 = new Account(name='test');
        insert a1;
        Account a2 = new Account(name='test');
        insert a2;
        Account a3 = new Account(name='test');
        insert a3;
        Account a4 = new Account(name='test');
        insert a4;
        HouseholdMember__c hm1 = new HouseholdMember__c(Household__c=h.Id,Account__c=a1.Id, isPrimary__c = true);
        insert hm1;
        HouseholdMember__c hm2 = new HouseholdMember__c(Household__c=h.Id,Account__c=a2.Id, isSecondary__c = true);
        insert hm2;
        HouseholdTrigger.assertPrimary(h, a1);
        HouseholdTrigger.assertSecondary(h, a2);
        delete hm1;
        delete hm2;
        HouseholdMember__c hm3 = new HouseholdMember__c(Household__c=h.Id,Account__c=a3.Id, isPrimary__c = true);
        insert hm3;
        HouseholdMember__c hm4 = new HouseholdMember__c(Household__c=h.Id, Account__c=a4.Id, isSecondary__c = true);
        insert hm4;
        HouseholdTrigger.assertPrimary(h, a3);
        HouseholdTrigger.assertSecondary(h, a4);
        try {
            undelete hm1;
        } catch (DMLException e) {
            System.assert(e.getMessage().contains(HouseholdTrigger.ERROR_MSG_DUPLICATE_CONTACTS));
        }
        try {
            undelete hm2;
        } catch (DMLException e) {
            System.assert(e.getMessage().contains(HouseholdTrigger.ERROR_MSG_DUPLICATE_CONTACTS));
        }
        HouseholdTrigger.assertPrimary(h, a3);
        HouseholdTrigger.assertSecondary(h, a4);
    }

    static testMethod void uniqueMemberUndeleteDuplicate(){
        Household__c h = new Household__c(name='HouseholdTest');
        insert h;
        Account a1 = new Account(name='test');
        insert a1;

        HouseholdMember__c hm1 = new HouseholdMember__c(Household__c=h.Id,Account__c=a1.Id,isPrimary__c = true);
        insert hm1;
        delete hm1;
        HouseholdMember__c hm2 = new HouseholdMember__c(Household__c=h.Id,Account__c=a1.Id,isSecondary__c = true);
        insert hm2;
        try {
            undelete hm1;
        } catch (System.DmlException e){
            System.debug(e.getMessage());
            System.assert(e.getMessage().contains(ERROR_MSG_UNDELETE_DUPLICATE));

        }

        HouseholdTrigger.assertNumMembers(h, 1);
        delete hm2;
        HouseholdTrigger.assertNumMembers(h, 0);
        undelete hm1;
        HouseholdTrigger.assertNumMembers(h, 1);
    }

    static testMethod void uniqueMemberUndeleteIterative(){
        Household__c h = new Household__c(name='HouseholdTest');
        insert h;
        Account a1 = new Account(name='test');
        insert a1;

        HouseholdMember__c hm1 = new HouseholdMember__c(Household__c=h.Id,Account__c=a1.Id,isPrimary__c = true);
        insert hm1;
        delete hm1;
        HouseholdMember__c hm2 = new HouseholdMember__c(Household__c=h.Id,Account__c=a1.Id,isSecondary__c = true);
        insert hm2;
        delete hm2;
        HouseholdTrigger.assertNumMembers(h, 0);
        undelete hm2;
        HouseholdTrigger.assertNumMembers(h, 1);
        try {
            undelete hm1;
        } catch (System.DmlException e){
            System.assert(e.getMessage().contains(ERROR_MSG_UNDELETE_DUPLICATE));
        }

        HouseholdTrigger.assertNumMembers(h, 1);
    }



    static testMethod void primarySecondaryMemberUndeleteDuplicate(){
        Household__c h = new Household__c(name='HouseholdTest');
        insert h;
        Account a1 = new Account(name='test');
        insert a1;
        Account a2 = new Account(name='test');
        insert a2;

        HouseholdMember__c hm1 = new HouseholdMember__c(Household__c=h.Id,Account__c=a1.Id,isPrimary__c = true);
        insert hm1;
        HouseholdMember__c hm2 = new HouseholdMember__c(Household__c=h.Id,Account__c=a2.Id,isSecondary__c = true);
        insert hm2;
        delete hm1;
        hm2.isPrimary__c = true;
        hm2.isSecondary__c = false;
        update hm2;
        try {
            undelete hm1;
            System.assert(false);
        } catch (System.DmlException e){
            System.assert(e.getMessage().contains(HouseholdTrigger.ERROR_MSG_DUPLICATE_CONTACTS));
        }
        HouseholdTrigger.assertPrimary(h, a2);
    }

    static testMethod void undeletePrimarySecondaryContacts() {
        Household__c h = new Household__c(name='HouseholdTest');
        insert h;
        Account a1 = new Account(name='test');
        insert a1;
        Account a2 = new Account(name='test');
        insert a2;

        HouseholdMember__c hm1 = new HouseholdMember__c(Household__c=h.Id,Account__c=a1.Id,isPrimary__c = true);
        insert hm1;
        HouseholdMember__c hm2 = new HouseholdMember__c(Household__c=h.Id,Account__c=a2.Id,isSecondary__c = true);
        insert hm2;
        delete hm1;
        delete hm2;
        HouseholdTrigger.assertNumMembers(h, 0);
        undelete hm1;
        undelete hm2;

        HouseholdTrigger.assertPrimary(h, a1);
        HouseholdTrigger.assertSecondary(h, a2);
    }

    static testMethod void deletePrimaryAccount() {
        Household__c h = new Household__c(name='HouseholdTest');
        insert h;
        Account a1 = new Account(name='test');
        insert a1;
        Account a2 = new Account(name='test');
        insert a2;

        HouseholdMember__c hm1 = new HouseholdMember__c(Household__c=h.Id,Account__c=a1.Id,isPrimary__c = true);
        insert hm1;
        HouseholdMember__c hm2 = new HouseholdMember__c(Household__c=h.Id,Account__c=a2.Id,isSecondary__c = true);
        insert hm2;
        try {
            delete a1;
            delete a2;
        } catch (DMLException e) {
            return;
        }

        HouseholdTrigger.assertNumMembers(h, 0);

        h = [select id, primaryaccount__c, SecondaryAccount__c, TotalMembers__c from Household__c where id = :h.Id];
        System.assert(h.PrimaryAccount__c == null);
        System.assert(h.SecondaryAccount__c == null);
        HouseholdTrigger.assertTotalMembers(h, 0);
    }

    static testMethod void undeleteSlaveChildrenFromMerge() {
        Household__c h1 = new Household__c(name='HouseholdTest');
        insert h1;
        Household__c h2 = new Household__c(name='HouseholdTest');
        insert h2;
        Account a1 = new Account(name='test');
        insert a1;
        Account a2 = new Account(name='test');
        insert a2;
        Account a3 = new Account(name='test');
        insert a3;

        HouseholdMember__c hm1 = new HouseholdMember__c(Household__c=h1.Id,Account__c=a1.Id);
        insert hm1;
        HouseholdMember__c hm2 = new HouseholdMember__c(Household__c=h2.Id,Account__c=a2.Id, isPrimary__c=true);
        insert hm2;
        HouseholdMember__c hm3 = new HouseholdMember__c(Household__c=h2.Id,Account__c=a3.Id);
        insert hm3;

        HouseholdTrigger.assertNumMembers(h1, 1);
        HouseholdTrigger.assertNumMembers(h2, 2);
        HouseholdTrigger.assertPrimary(h2, a2);
        Account[] accs = new List<Account>();
        accs.add(a2);
        accs.add(a3);
        try {
            merge a1 accs;
        } catch (DMLException e) {
            return;
        }

        HouseholdTrigger.assertNumMembers(h1, 1);
        HouseholdTrigger.assertNumMembers(h2, 1);
        HouseholdTrigger.AssertPrimary(h2, a1);

        try { //You shouldn't be able to undelete deleted children of deleted accounts
            undelete hm3;
            System.assert(false);
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
    }

    //&&&&&&&&&&&&&&&&&&&&&&&&&&&&&ACCOUNT UNDELETE TESTS&&&&&&&&&&&&&&&&

    public static testMethod void memberLimitAccountUndelete_1_20() {

        Household__c h = new Household__c(name='HouseholdTest');
        insert h;

        HouseholdMember__c hm;

        Integer numMembers = 20;
        HouseholdMember__c[] members = new HouseholdMember__c[numMembers];
        Account[] accs = new Account[numMembers];
        for (Integer i = 0; i < numMembers; i++){
            Account a = new Account(name = 'test');
            accs[i] = a;
        }
        insert accs;
        for (Integer i = 0; i < numMembers; i++) {
            hm = new HouseholdMember__c(Household__c=h.Id,Account__c=accs[i].Id);
            members[i] = hm;
        }
        insert members;
        HouseholdTrigger.assertNumMembers(h, 20);
        try {
            delete accs;
        } catch (DMLException e) {
            return;
        }
        Account a = new Account(name='test');
        insert a;
        hm = new HouseholdMember__c(Household__c=h.Id,Account__c=a.Id);
        insert hm;
        HouseholdTrigger.assertNumMembers(h, 1);

        try {
            undelete accs;
        } catch (Exception e) {
            System.assert(e.getMessage().contains(HouseholdTrigger.ERROR_MSG_MAX_MEMBERS.substring(28)));
        }
        HouseholdTrigger.assertNumMembers(h, 1);
    }

    public static testMethod void memberLimitAccountUndelete_20_1() {
        Household__c h = new Household__c(name='HouseholdTest');
        insert h;

        Integer numMembers = 20;
        HouseholdMember__c[] members = new HouseholdMember__c[numMembers];
        Account[] accs = new Account[numMembers];
        for (Integer i = 0; i < numMembers; i++){
            Account a = new Account(name = 'test');
            accs[i] = a;
        }
        insert accs;
        for (Integer i = 0; i < numMembers; i++){

            HouseholdMember__c hm = new HouseholdMember__c(Household__c=h.Id,Account__c=accs[i].Id);
            members[i] = hm;
        }
        insert members;

        HouseholdTrigger.assertNumMembers(h, 20);
        try {
            delete accs;
        } catch (DMLException e) {
            return;
        }
        Account a = new Account(name='test');
        insert a;

        HouseholdMember__c hm = new HouseholdMember__c(Household__c=h.Id,Account__c=a.Id);
        insert hm;
        delete hm;
        undelete accs;

        try {
            undelete hm;
        } catch (DMLException e) {
            System.assert(e.getMessage().contains(HouseholdTrigger.ERROR_MSG_MAX_MEMBERS.substring(28)));
        }

        HouseholdTrigger.assertNumMembers(h, 20);
    }


    static testMethod void primaryMemberAccountUndeleteDuplicate(){
        Household__c h = new Household__c(name='HouseholdTest');
        insert h;
        Account a1 = new Account(name='test');
        insert a1;
        Account a2 = new Account(name='test');
        insert a2;

        HouseholdMember__c hm1 = new HouseholdMember__c(Household__c=h.Id,Account__c=a1.Id, isPrimary__c = true);
        insert hm1;
        HouseholdTrigger.assertPrimary(h, a1);
        try {
            delete a1;
        } catch (DMLException e) {
            return;
        }
        HouseholdMember__c hm2 = new HouseholdMember__c(Household__c=h.Id,Account__c=a2.Id, isPrimary__c = true);
        insert hm2;
        HouseholdTrigger.assertPrimary(h, a2);
        try {
            undelete a1;
        } catch (DMLException e) {
            System.assert(e.getMessage().contains(HouseholdTrigger.ERROR_MSG_DUPLICATE_CONTACTS));
        }
        HouseholdTrigger.assertPrimary(h, a2);
    }

    static testMethod void secondaryMemberAccountUndeleteDuplicate(){
        Household__c h = new Household__c(name='HouseholdTest');
        insert h;
        Account a1 = new Account(name='test');
        insert a1;
        Account a2 = new Account(name='test');
        insert a2;

        HouseholdMember__c hm1 = new HouseholdMember__c(Household__c=h.Id,Account__c=a1.Id, isSecondary__c = true);
        insert hm1;
        HouseholdTrigger.assertSecondary(h, a1);
        try {
            delete a1;
        } catch (DMLException e) {
            return;
        }
        HouseholdMember__c hm2 = new HouseholdMember__c(Household__c=h.Id,Account__c=a2.Id, isSecondary__c = true);
        insert hm2;
        HouseholdTrigger.assertSecondary(h, a2);
        try {
            undelete a1;
        } catch (DMLException e) {
            System.assert(e.getMessage().contains(HouseholdTrigger.ERROR_MSG_DUPLICATE_CONTACTS));
        }
        HouseholdTrigger.assertSecondary(h, a2);
    }

    static testMethod void primaryMemberAccountUndeleteHouseholdThenAccount(){
        Household__c h = new Household__c(name='HouseholdTest');
        insert h;

        Household__c h2 = new Household__c(name='HouseholdTest');
        insert h2;
        Account a1 = new Account(name='test');
        insert a1;
        Account a2 = new Account(name='test');
        insert a2;


        HouseholdMember__c hm1 = new HouseholdMember__c(Household__c=h.Id,Account__c=a1.Id, isPrimary__c = true);
        insert hm1;
        HouseholdMember__c hm2 = new HouseholdMember__c(Household__c=h2.Id,Account__c=a1.Id, isPrimary__c = true);
        insert hm2;
        HouseholdMember__c hm3 = new HouseholdMember__c(Household__c=h.Id,Account__c=a2.Id, isSecondary__c = true);
        insert hm3;
        HouseholdMember__c hm4 = new HouseholdMember__c(Household__c=h2.Id,Account__c=a2.Id, isSecondary__c = true);
        insert hm4;
        HouseholdTrigger.assertPrimary(h, a1);
        HouseholdTrigger.assertPrimary(h2, a1);
        HouseholdTrigger.assertSecondary(h, a2);
        HouseholdTrigger.assertSecondary(h2, a2);
        try {
            delete h;
        } catch (DMLException e) {
            return;
        }

        try {
            delete a1;
        } catch (DMLException e) {
            return;
        }
        HouseholdTrigger.assertSecondary(h2, a2);
        undelete h;

        h = [select Id, PrimaryAccount__c, SecondaryAccount__c from Household__c where Id = :h.Id];
        System.assert(h.PrimaryAccount__c == null);
        HouseholdTrigger.assertSecondary(h, a2);

        h2 = [select Id, PrimaryAccount__c, SecondaryAccount__c from Household__c where Id = :h2.Id];
        System.assert(h2.PrimaryAccount__c == null);
        HouseholdTrigger.assertSecondary(h2, a2);

        undelete a1;

        h = [select Id, PrimaryAccount__c from Household__c where Id = :h.Id];
        System.assert(h.PrimaryAccount__c == null);
        HouseholdTrigger.assertSecondary(h, a2);

        HouseholdTrigger.assertPrimary(h2, a1);
        HouseholdTrigger.assertSecondary(h2, a2);
    }


    static testMethod void hardDeleteChange() {
        Household__c h = new Household__c(name='HouseholdTest');
        insert h;
        Account a1 = new Account(name='test');
        insert a1;
        HouseholdMember__c hm1 = new HouseholdMember__c(Household__c=h.Id,Account__c=a1.Id, isSecondary__c = true, hardDeleted__c = true);
        try {
            insert hm1;
        } catch (DMLException e) {
            System.assert(e.getMessage().contains(HouseholdTrigger.ERROR_MSG_CANNOT_MODIFY_HARDDELETED));
        }

        hm1.HardDeleted__c = false;
        insert hm1;
        hm1.HardDeleted__c = true;
        try {
            update hm1;
        } catch (DMLException e) {
            System.assert(e.getMessage().contains(HouseholdTrigger.ERROR_MSG_CANNOT_MODIFY_HARDDELETED));
        }
    }
}