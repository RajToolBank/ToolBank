public class AccountMerge {

/**
 *Go through list of RG Member children of deleted accounts.
 *For each child, recalculate the unique key based on the new
 *parent account.  If another RG Member has that key, delete the
 *new RG member.  Otherwise, update the member with the new unique
 *key.
 */
    public static void updateRGMembers(Account[] triggerMembers) {
        Id[] memberIds = getMasterRecordIdsFromAccounts(triggerMembers);
        HouseholdMember__c[] members = new List<HouseholdMember__c>();
        if (memberIds.size() > 0) {
            for (HouseholdMember__c member : [SELECT Id, Account__c, Unique_Key__c, Household__c, isPrimary__c, isSecondary__c, LastModifiedDate FROM HouseholdMember__c WHERE Account__c IN :memberIds])
                members.add(member);
        }
        else
            return;
        HouseholdMember__c[] toUpdate = new List<HouseholdMember__c>();
        HouseholdMember__c[] toDelete = new List<HouseholdMember__c>();
        Map<String, HouseholdMember__c> memberMap = new Map<String, HouseholdMember__c>();
        for (HouseholdMember__c member : members) {
            HouseholdMember__c temp;
            String unique = '' + member.Household__c + member.Account__c;
            //if there are no conflicting records or if the member object is associated with the master
            //account, put it in the map
            temp = memberMap.get(unique);
            if ((temp == null) || (member.Unique_Key__c == unique)){
                if (temp != null) {
                    memberMap.remove(unique);
                    toDelete.add(temp);
                }
                memberMap.put(unique, member);

            }
            else if (temp.Unique_Key__c == unique) { //if this is true, then temp is associated with the master record.  keep it in the map
                memberMap.put(temp.Unique_Key__c, temp);
                toDelete.add(member);
            }
            //ugly edge cases: merge 3 accounts.  the 2 slave accounts have RG Members in the same household
            //and the master account does not.
            //The decision handed down from on high to resolve conflicts is that whichever member has higher
            //contact status wins, and if that doesn't work, then the more recently modified record wins.
            else if ((member.isPrimary__c == true) || ((member.isSecondary__c == true) && (temp.isPrimary__c == false))) {
                memberMap.put(member.Unique_Key__c, member);
                toDelete.add(temp);
            }
            else if ((temp.isPrimary__c == true) || (temp.isSecondary__c == true) || (temp.LastModifiedDate > member.LastModifiedDate)){
                toDelete.add(member);
            }
            else {
                member.Unique_Key__c = unique;
                memberMap.put(member.Unique_Key__c, member);
                toDelete.add(temp);
            }

        }

        toUpdate = memberMap.values();
        hardDelete(toDelete);

        if (toUpdate.size() > 0) {
            update toUpdate;
        }
    }

    static void hardDelete(List<HouseholdMember__c> toDelete) {
        if (toDelete.size() > 0) {
            for (HouseholdMember__c hm : toDelete) {
                hm.HardDeleted__c = true;
            }
            HouseholdTrigger.disableMemberTriggers();
            update toDelete; //mark 'HardDeleted' as true
            delete toDelete;
            HouseholdTrigger.enableMemberTriggers();
        }
    }

    static Id[] getMasterRecordIdsFromAccounts(Account[] accounts) {
        Id[] memberIds = new List<Id>();
        for (Account acc : accounts) {
            //If the master record Id has been changed, the account is being merged.
            if ((acc.Id != acc.MasterRecordId) && (acc.MasterRecordId != null))
                memberIds.add(acc.MasterRecordId);
        }
        return memberIds;
    }

    public static testmethod void mergeTwoAccountsBelongingToSameRG() {
        Household__c h = new Household__c(name='HouseholdTest');
        insert h;
        Account a1 = new Account(name='test');
        insert a1;
        Account a2 = new Account(name='test');
        insert a2;
        HouseholdMember__c hm1 = new HouseholdMember__c(Household__c=h.Id,Account__c=a1.Id);
        insert hm1;
        HouseholdMember__c hm2 = new HouseholdMember__c(Household__c=h.Id,Account__c=a2.Id);
        insert hm2;

        try {
            merge a1 a2;
        } catch (System.DMLException e) {
            return;
        }
        HouseholdTrigger.assertNumMembers(h, 1);

        try {
            undelete hm2;
            System.assert(false);
        } catch (System.DmlException e) {
            System.assert(e.getMessage().contains(HouseholdTrigger.ERROR_MSG_CANNOT_UNDELETE));
        }
    }

    static testmethod void mergeTwoAccountsWithOneRGMember() {
        Household__c h = new Household__c(name='HouseholdTest');
        insert h;
        Account a1 = new Account(name='test');
        insert a1;
        Account a2 = new Account(name='test');
        insert a2;

        HouseholdMember__c hm1 = new HouseholdMember__c(Household__c=h.Id,Account__c=a1.Id);
        insert hm1;

        HouseholdTrigger.assertNumMembers(h, 1);
        try {
            merge a1 a2;
        } catch (System.DMLException e) {
            return;
        }
        HouseholdTrigger.assertNumMembers(h, 1);

    }

    static testmethod void mergeTwoAccountsIntoOnePrimary() {
        Household__c h = new Household__c(name='HouseholdTest');
        insert h;
        Account a1 = new Account(name='test');
        insert a1;
        Account a2 = new Account(name='test');
        insert a2;
        HouseholdMember__c hm1 = new HouseholdMember__c(Household__c=h.Id,Account__c=a1.Id, isPrimary__c = true);
        insert hm1;
        HouseholdMember__c hm2 = new HouseholdMember__c(Household__c=h.Id,Account__c=a2.Id);
        insert hm2;

        try {
            merge a1 a2;
        } catch (System.DMLException e) {
            return;
        }
        HouseholdTrigger.assertNumMembers(h, 1);
        HouseholdTrigger.assertPrimary(h, a1);
    }

    static testmethod void mergePrimaryAndSecondaryIntoPrimary() {
        Household__c h = new Household__c(name='HouseholdTest');
        insert h;
        Account a1 = new Account(name='test');
        insert a1;
        Account a2 = new Account(name='test');
        insert a2;

        HouseholdMember__c hm1 = new HouseholdMember__c(Household__c=h.Id,Account__c=a1.Id, isPrimary__c = true);
        insert hm1;
        HouseholdMember__c hm2 = new HouseholdMember__c(Household__c=h.Id,Account__c=a2.Id, isSecondary__c = true);
        insert hm2;

        try {
            merge a1 a2;
        } catch (System.DMLException e) {
            return;
        }
        HouseholdTrigger.assertNumMembers(h, 1);
        HouseholdTrigger.assertPrimary(h, a1);
        System.assert(h.SecondaryAccount__c == null);
    }

    static testmethod void deleteWithoutMerge() {

        Household__c h = new Household__c(name='HouseholdTest');
        insert h;
        Account a1 = new Account(name='test');
        insert a1;
        Account a2 = new Account(name='test');
        insert a2;

        HouseholdMember__c hm1 = new HouseholdMember__c(Household__c=h.Id,Account__c=a1.Id, isPrimary__c = true);
        insert hm1;
        HouseholdMember__c hm2 = new HouseholdMember__c(Household__c=h.Id,Account__c=a2.Id, isSecondary__c = true);
        insert hm2;

        try {
            delete a2;
        } catch (DMLException e) {
            if (e.getMessage().contains('DELETE_FAILED')) {
                return;
            }
        }

        HouseholdTrigger.assertNumMembers(h, 1);
        HouseholdTrigger.assertPrimary(h, a1);
        System.assert(h.SecondaryAccount__c == null);
    }

    static testmethod void merge3AccountsInDifferentHouseholds() {
        Household__c h1 = new Household__c(name='HouseholdTest');
        insert h1;
        Household__c h2 = new Household__c(name='HouseholdTest');
        insert h2;
        Household__c h3 = new Household__c(name='HouseholdTest');
        insert h3;
        Account a1 = new Account(name='test');
        insert a1;
        Account a2 = new Account(name='test');
        insert a2;
        Account a3 = new Account(name='test');
        insert a3;

        HouseholdMember__c hm1 = new HouseholdMember__c(Household__c=h1.Id,Account__c=a1.Id);
        insert hm1;
        HouseholdMember__c hm2 = new HouseholdMember__c(Household__c=h2.Id,Account__c=a2.Id);
        insert hm2;
        HouseholdMember__c hm3 = new HouseholdMember__c(Household__c=h3.Id,Account__c=a3.Id);
        insert hm3;

        Account[] accs = new List<Account>();
        accs.add(a2);
        accs.add(a3);
        try {
            merge a1 accs;
        } catch (System.DMLException e) {
            return;
        }

        HouseholdTrigger.assertNumMembers(h1, 1);
        HouseholdTrigger.assertNumMembers(h2, 1);
        HouseholdTrigger.assertNumMembers(h3, 1);

    }

    static testmethod void merge3AccountsInSameHousehold() {
        Household__c h1 = new Household__c(name='HouseholdTest');
        insert h1;

        Account a1 = new Account(name='test');
        insert a1;
        Account a2 = new Account(name='test');
        insert a2;
        Account a3 = new Account(name='test');
        insert a3;

        HouseholdMember__c hm1 = new HouseholdMember__c(Household__c=h1.Id,Account__c=a1.Id);
        insert hm1;
        HouseholdMember__c hm2 = new HouseholdMember__c(Household__c=h1.Id,Account__c=a2.Id, isPrimary__c=true);
        insert hm2;
        HouseholdMember__c hm3 = new HouseholdMember__c(Household__c=h1.Id,Account__c=a3.Id);
        insert hm3;

        HouseholdTrigger.assertNumMembers(h1, 3);
        HouseholdTrigger.assertPrimary(h1, a2);
        Account[] accs = new List<Account>();
        accs.add(a2);
        accs.add(a3);
        try {
            merge a1 accs;
        } catch (System.DMLException e) {
            return;
        }

        HouseholdTrigger.assertNumMembers(h1, 1);

    }

    static testmethod void merge3AccountsWhenSlavesShareHousehold() {
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
        } catch (System.DMLException e) {
            return;
        }

        HouseholdTrigger.assertNumMembers(h1, 1);
        HouseholdTrigger.assertNumMembers(h2, 1);
        HouseholdTrigger.AssertPrimary(h2, a1);

    }
}