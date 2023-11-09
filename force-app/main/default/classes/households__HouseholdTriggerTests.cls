public class HouseholdTriggerTests {
    static testMethod void addInvalidPrimaryAccount() {
        Household__c h = new Household__c(name='HouseholdTest');
        insert h;

        Account a = new Account(name='test');
        insert a;

        h.PrimaryAccount__c = a.Id;

        try {
            HouseholdTrigger.memberBeingInserted = true;
            update h;
        } catch (System.DmlException e){
            System.assert(e.getMessage().contains(HouseholdTrigger.ERROR_MSG_INVALID_CONTACT_ACCOUNT));
        }
    }

    static testMethod void addInvalidSecondaryAccount() {
        Household__c h = new Household__c(name='HouseholdTest');
        insert h;

        Account a = new Account(name='test');
        insert a;

        h.SecondaryAccount__c = a.Id;

        try {
            HouseholdTrigger.memberBeingInserted = true;
            update h;
        } catch (System.DmlException e){
            System.assert(e.getMessage().contains(HouseholdTrigger.ERROR_MSG_INVALID_CONTACT_ACCOUNT));
        }
    }

    static testMethod void addInvalidPrimarySecondaryAccount() {
        Household__c h = new Household__c(name='HouseholdTest');
        insert h;

        Account a1 = new Account(name='test');
        insert a1;
        Account a2 = new Account(name='test');
        insert a2;
        h.PrimaryAccount__c = a1.Id;
        h.SecondaryAccount__c = a2.Id;

        try {
            HouseholdTrigger.memberBeingInserted = true;
            update h;
        } catch (System.DmlException e){
            System.assert(e.getMessage().contains(HouseholdTrigger.ERROR_MSG_INVALID_CONTACT_ACCOUNT));
        }
    }

    static testMethod void invalidHouseholdUpdate() {
        Household__c h = new Household__c(name='HouseholdTest');
        insert h;

        Account a = new Account(name='test');
        insert a;
        h.PrimaryAccount__c = a.Id;

        try {
            update h;
        } catch (System.DmlException e){
            System.assert(e.getMessage().contains(HouseholdTrigger.ERROR_MSG_INVALID_RG_UPDATE));
        }
    }

    public static testMethod void deletePrimaryContact() {
        Household__c h = new Household__c(name='HouseholdTest');
        insert h;

        Account a = new Account(name='test');
        insert a;

        HouseholdMember__c hm1 = new HouseholdMember__c(Household__c=h.Id,Account__c=a.Id, isPrimary__c=true);
        insert hm1;

        HouseholdTrigger.assertPrimary(h, a);
        hm1 = [select Id, Household__c, Account__c from HouseholdMember__c where Id = :hm1.Id];
        delete hm1;

        h = [select PrimaryAccount__c from Household__c where Id = :h.Id];
        System.assert(h.PrimaryAccount__c == null);
    }

    static testMethod void deleteSecondaryContact() {
        Household__c h = new Household__c(name='HouseholdTest');
        insert h;

        Account a = new Account(name='test');
        insert a;

        HouseholdMember__c hm1 = new HouseholdMember__c(Household__c=h.Id,Account__c=a.Id, isSecondary__c=true);
        insert hm1;

        HouseholdTrigger.assertSecondary(h, a);
        hm1 = [select Id, Household__c, Account__c from HouseholdMember__c where Id = :hm1.Id];
        delete hm1;

        h = [select SecondaryAccount__c from Household__c where Id = :h.Id];
        System.assert(h.SecondaryAccount__c == null);
    }

    static testMethod void deletePrimarySecondaryContact() {
        Household__c h = new Household__c(name='HouseholdTest');
        insert h;

        Account a1 = new Account(name='test');
        insert a1;
        Account a2 = new Account(name='test');
        insert a2;

        HouseholdMember__c hm1 = new HouseholdMember__c(Household__c=h.Id,Account__c=a1.Id, isPrimary__c=true);
        insert hm1;

        HouseholdMember__c hm2 = new HouseholdMember__c(Household__c=h.Id,Account__c=a2.Id, isSecondary__c=true);
        insert hm2;

        HouseholdMember__c[] toDelete = new List<HouseholdMember__c>();
        //hm1 = [select Id from HouseholdMember__c where Account__c = hm1.Account__c and household__c = hm1.household__c];
        //hm2 = [select Id from HouseholdMember__c where Account__c = hm2.Account__c and household__c = hm2.household__c];
        //toDelete = [select Id from HouseholdMember__c where Account__c in (hm1.Account__c, hm2.Account__c)];
        toDelete.add(hm1);
        toDelete.add(hm2);

        HouseholdTrigger.assertPrimary(h, a1);
        HouseholdTrigger.assertSecondary(h, a2);

        delete toDelete;

        h = [select PrimaryAccount__c, SecondaryAccount__c from Household__c where Id = :h.Id];
        System.assert(h.PrimaryAccount__c == null);
        System.assert(h.SecondaryAccount__c == null);
    }

    static testMethod void deletePrimaryThenSecondaryContact() {
        Household__c h = new Household__c(name='HouseholdTest');
        insert h;

        Account a1 = new Account(name='test');
        insert a1;
        Account a2 = new Account(name='test');
        insert a2;
        HouseholdMember__c hm1 = new HouseholdMember__c(Household__c=h.Id,Account__c=a1.Id, isPrimary__c=true);
        insert hm1;

        HouseholdMember__c hm2 = new HouseholdMember__c(Household__c=h.Id,Account__c=a2.Id, isSecondary__c=true);
        insert hm2;

        HouseholdTrigger.assertPrimary(h, a1);
        HouseholdTrigger.assertSecondary(h, a2);

        delete hm1;

        h = [select PrimaryAccount__c, SecondaryAccount__c from Household__c where Id = :h.Id];
        System.assert(h.PrimaryAccount__c == null);
        System.assert(h.SecondaryAccount__c != null);

        delete hm2;

        h = [select PrimaryAccount__c, SecondaryAccount__c from Household__c where Id = :h.Id];
        System.assert(h.PrimaryAccount__c == null);
        System.assert(h.SecondaryAccount__c == null);
    }

    static testMethod void deleteSecondaryThenPrimaryContact() {
        Household__c h = new Household__c(name='HouseholdTest');
        insert h;

        Account a1 = new Account(name='test');
        insert a1;
        Account a2 = new Account(name='test');
        insert a2;

        HouseholdMember__c hm1 = new HouseholdMember__c(Household__c=h.Id,Account__c=a1.Id, isPrimary__c=true);
        insert hm1;

        HouseholdMember__c hm2 = new HouseholdMember__c(Household__c=h.Id,Account__c=a2.Id, isSecondary__c=true);
        insert hm2;

        HouseholdTrigger.assertPrimary(h, a1);
        HouseholdTrigger.assertSecondary(h, a2);

        delete hm2;

        h = [select PrimaryAccount__c, SecondaryAccount__c from Household__c where Id = :h.Id];
        System.assert(h.PrimaryAccount__c != null);
        System.assert(h.SecondaryAccount__c == null);

        delete hm1;

        h = [select PrimaryAccount__c, SecondaryAccount__c from Household__c where Id = :h.Id];
        System.assert(h.PrimaryAccount__c == null);
        System.assert(h.SecondaryAccount__c == null);
    }

    static testMethod void bulkInsertAccountIntoMultipleHouseholds() {
        Household__c h1 = new Household__c(name='HouseholdTest');
        insert h1;

        Household__c h2 = new Household__c(name='HouseholdTest');
        insert h2;

        Account a1 = new Account(name='test');
        insert a1;

        HouseholdMember__c[] hm = new List<HouseholdMember__c>();
        hm.add(new HouseholdMember__c(Household__c=h1.Id,Account__c=a1.Id, isPrimary__c=true));
        hm.add(new HouseholdMember__c(Household__c=h2.Id,Account__c=a1.Id, isPrimary__c=true));
        insert hm;
        HouseholdTrigger.assertPrimary(h1, a1);
        HouseholdTrigger.assertPrimary(h2, a1);
    }

}