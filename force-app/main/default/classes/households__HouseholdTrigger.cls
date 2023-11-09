public class HouseholdTrigger {

    public static final Integer MAX_MEMBERS = 20;
    public static final String MEMBER_PRIORITY_PRIMARY = 'Primary';
    public static final String MEMBER_PRIORITY_SECONDARY = 'Secondary';
    // NOTE: Trigger message changes must be coordinated with householdcontroller.apex
    public static final String ERROR_MSG_MAX_MEMBERS = 'ERROR_MSG_MAX_MEMBERS:Relationship Groups cannot contain more than ' + MAX_MEMBERS +' members';
    public static final String ERROR_MSG_DUPLICATE_CONTACTS = 'ERROR_MSG_DUPLICATE_CONTACTS:A household cannot have more than one primary or secondary contact assigned';
    public static final String ERROR_MSG_DUPLICATE_MEMBERS = 'ERROR_MSG_DUPLICATE_MEMBERS:duplicate value found';
    public static final String ERROR_MSG_INVALID_CONTACT_ACCOUNT = 'ERROR_MSG_INVALID_CONTACT_ACCOUNT:Primary and secondary contact status can only be assigned to members of the relationship group';
    public static final String ERROR_MSG_INVALID_RG_UPDATE = 'ERROR_MSG_INVALID_RG_UPDATE:The Primary and Secondary fields cannot be edited directly.  Please set contact status on the Relationship Group Members instead.  If this is the result of a Clone operation, clear the primary and secondary fields before cloning.';
    public static final String ERROR_MSG_DUPLICATE_STATUS = 'ERROR_MSG_DUPLICATE_STATUS:Relationship Group members cannot be both primary and secondary contact for the same household.';
    public static final String ERROR_MSG_CANNOT_UNDELETE = 'Relationship Group members deleted through an account merge may not be undeleted.';
    public static final String ERROR_MSG_CANNOT_MODIFY_HARDDELETED = 'The field HardDeleted__c on the RelationshipGroupMember object is not editable.';

    /* If this is true, then a householdMember is being edited or inserted and the household
       triggers need to be disabled, because the updates being made to household contacts
       are necessary.  */
    public static Boolean memberBeingInserted = false;
    private static Boolean memberTriggersEnabled = true;
    private static Boolean householdTriggersEnabled = true;

    static Account[] testAccounts;

    public static boolean areMemberTriggersEnabled() {
        return memberTriggersEnabled;
    }

    /*
        disables all triggers on member objects
    */
    public static void disableMemberTriggers() {
        memberTriggersEnabled = false;
    }

    public static void enableMemberTriggers() {
        memberTriggersEnabled = true;
    }

    public static void disableHouseholdTriggers() {
        householdTriggersEnabled = false;
    }

    public static void enableHouseholdTriggers() {
        householdTriggersEnabled = true;
    }
    public static boolean areHouseholdTriggersEnabled() {
        return householdTriggersEnabled;
    }

    public static void maxMemberLimitTrigger(HouseholdMember__c[] triggerMembers) {
        Map<Id, HouseholdMember__c[]> householdToMembers = HouseholdTrigger.getHouseholdToMembersMap(triggerMembers);
        Map<Id, Household__c> householdMap = HouseholdTrigger.getUniqueHouseholds(triggerMembers);
        Household__c[] householdsBeingChanged = householdMap.values();
        for (Household__c house : householdsBeingChanged) {
            HouseholdMember__c[] members = householdToMembers.get(house.Id);
            Integer totalMembers;
            if (house.TotalMembers__c == null) {
                totalMembers = 0;
            }
            else {
                totalMembers = house.TotalMembers__c.intValue();
            }
            if (totalMembers + members.size() > 20) {
                for (HouseholdMember__c member : members) {
                    member.addError(ERROR_MSG_MAX_MEMBERS);
                }
            }
        }

    }



    /**
     *do not allow contacts to be directly edited on households when they're *updated*
     **/
    public static void contactsOnHouseholdsNotEditableEdit(Household__c[] triggerMembersNew, Household__c[] triggerMembersOld) {
        if (!memberBeingInserted) {
            Integer i;
            for (i = 0; i < triggerMembersNew.size(); i++) {
                if ((triggerMembersNew[i].PrimaryAccount__c != triggerMembersOld[i].PrimaryAccount__c) ||
                    (triggerMembersNew[i].SecondaryAccount__c != triggerMembersOld[i].SecondaryAccount__c)) {
                    triggerMembersNew[i].addError(ERROR_MSG_INVALID_RG_UPDATE);
                }
            }
        }
    }

    /**
     *do not allow contacts to be directly set on households when they're *created*
     **/
    public static void contactsOnHouseholdsNotEditableInsert(Household__c[] triggerMembers) {
        for (Household__c member : triggerMembers) {
            if ((member.PrimaryAccount__c != null) || (member.SecondaryAccount__c != null)) {
                member.addError(ERROR_MSG_INVALID_RG_UPDATE);
            }
        }
    }

    public static void hardDeletedNotEditable(HouseholdMember__c[] triggerMembers) {
        for (HouseholdMember__c member : triggerMembers) {
            if (member.HardDeleted__c == true) {
                member.addError(ERROR_MSG_CANNOT_MODIFY_HARDDELETED);
            }
        }
    }
    /**
     *update the primary and secondary contact fields on the household when the members
     *change status
     * The tricky part of this trigger is that if you're deleting both the primary and
     * secondary contacts from a household at once, you want to combine those two changes
     * into one update.  Otherwise, you'll end up with the second update overwriting the first.
     * So whenever a house gets updated, it goes into tempHouseMap, and this map is checked
     * before householdMap for the house to change.  That way all changes are being made
     * on the same object.
     **/

    public static void updateHouseholdContactStatus(HouseholdMember__c[] triggerMembers) {
        Integer i;
        Map<Id, Household__c> householdMap = HouseholdTrigger.getUniqueHouseholds(triggerMembers);
        Map<Id, Household__c> tempHouseMap = new Map<Id, Household__c>();
        Household__c[] householdsToUpdate = new List<Household__c>();
        for (i = 0; i < triggerMembers.size(); i++) {

            if (triggerMembers[i].isPrimary__c == true) {
                Household__c house;
                if (tempHouseMap.containsKey(triggerMembers[i].Household__c))
                    house = tempHouseMap.get(triggerMembers[i].Household__c);
                else
                    house = householdMap.get(triggerMembers[i].Household__c);
                house.PrimaryAccount__c = null;
                tempHouseMap.remove(house.Id);
                tempHouseMap.put(house.Id, house);
            }
            else if (triggerMembers[i].isSecondary__c == true) {
                Household__c house;
                if (tempHouseMap.containsKey(triggerMembers[i].Household__c))
                    house = tempHouseMap.get(triggerMembers[i].Household__c);
                else
                    house = householdMap.get(triggerMembers[i].Household__c);
                house.SecondaryAccount__c = null;
                tempHouseMap.remove(house.Id);
                tempHouseMap.put(house.Id, house);
            }
        }
        householdsToUpdate = tempHouseMap.values();
        update householdsToUpdate;
    }



    public static Id[] getIdList(Household__c[] houses) {
        Id[] idList = new List<Id>();
        for (Household__c house : houses) {
            if (house.PrimaryAccount__c != null)
                idList.add(house.PrimaryAccount__c);
            if (house.SecondaryAccount__c != null)
                idList.add(house.SecondaryAccount__c);
        }
        return idList;
    }

    /**
     *Ensure that RG members are not set as both primary and secondary on a household
     **/
    public static void multipleContactStatusTrigger(HouseholdMember__c[] triggerMembers) {
        for (HouseholdMember__c member : triggerMembers) {
            if ((member.isPrimary__c == true) && (member.isSecondary__c == true)) {
                member.addError(ERROR_MSG_DUPLICATE_STATUS);
            }
        }
    }

    /**
     *Makes sure that all primary and secondary contact assignments are valid.  1 primary and
     * 1 secondary per household.
     **/
    public static void primarySecondaryMemberTriggerPre(HouseholdMember__c[] triggerMembers) {
        Map<Id, HouseholdMember__c[]> householdToMembers = HouseholdTrigger.getHouseholdToMembersMap(triggerMembers);
        Map<Id, Household__c> householdMap = HouseholdTrigger.getUniqueHouseholds(triggerMembers);
        Household__c[] householdsBeingChanged = householdMap.values();
        Household__c[] householdsToUpdate = new List<Household__c>();

        for (Household__c house : householdsBeingChanged) {
            Boolean problem = false;
            Map<String, Id> priority = new Map<String, Id>();
            HouseholdMember__c[] members = householdToMembers.get(house.Id);

            if ((house.PrimaryAccount__c != null) && !containsAccount(triggerMembers, house.PrimaryAccount__c)) {
                priority.put(MEMBER_PRIORITY_PRIMARY, house.PrimaryAccount__c);
            }
            if ((house.SecondaryAccount__c != null) && !containsAccount(triggerMembers, house.SecondaryAccount__c)) {
                priority.put(MEMBER_PRIORITY_SECONDARY, house.SecondaryAccount__c);
            }

            for (HouseholdMember__c member : members) {
                if (member.isPrimary__c == true){
                    if (priority.get(MEMBER_PRIORITY_PRIMARY) == null) {
                        priority.put(MEMBER_PRIORITY_PRIMARY, member.Account__c);
                    } else {
                        problem = true;
                        break;
                    }
                } else if (member.isSecondary__c == true){
                    if (priority.get(MEMBER_PRIORITY_SECONDARY) == null) {
                        priority.put(MEMBER_PRIORITY_SECONDARY, member.Account__c);
                    } else {
                        problem = true;
                        break;
                    }
                }
            }
            if (problem) {
                for (HouseholdMember__c member : members) {
                    member.addError(ERROR_MSG_DUPLICATE_CONTACTS);
                }
            } else {
                house.PrimaryAccount__c = priority.get(MEMBER_PRIORITY_PRIMARY);
                house.SecondaryAccount__c = priority.get(MEMBER_PRIORITY_SECONDARY);
                householdsToUpdate.add(house);
            }
        }
        update householdsToUpdate;
    }

    public static void verifyContactFields(Household__c[] houses) {
        Map<String, HouseholdMember__c> contacts = getAllContactIds(houses);
        for (Household__c house : houses) {
            String key = ''+house.Id+house.PrimaryAccount__c;
            if ((house.PrimaryAccount__c != null) && (contacts.get(key) == null)) {
                house.PrimaryAccount__c = null;
            }
            key = ''+house.Id+house.SecondaryAccount__c;
            if ((house.SecondaryAccount__c != null) && (contacts.get(key) == null)) {
                house.SecondaryAccount__c = null;
            }
        }

        disableHouseholdTriggers();
        try {
            update houses;
        } finally {
            enableHouseholdTriggers();
        }
    }

    private static Map<String, HouseholdMember__c> getAllContactIds(Household__c[] houses) {
        Id[] contactIds = new List<Id>();
        Id[] householdIds = new List<Id>();
        Map<String, HouseholdMember__c> members = new Map<String, HouseholdMember__c>();
        for (Household__c house : houses) {
            if (house.PrimaryAccount__c != null) {
                contactIds.add(house.PrimaryAccount__c);
            }
            if (house.SecondaryAccount__c != null) {
                contactIds.add(house.SecondaryAccount__c);
            }
            householdIds.add(house.Id);
        }
        for (HouseholdMember__c h : [SELECT Id, Unique_Key__c FROM HouseholdMember__c WHERE Household__c IN :householdIds AND Account__c IN :contactIds]) {
            members.put(h.Unique_Key__c, h);
        }
        return members;
    }



    public static Boolean containsAccount(HouseholdMember__c[] memberList, Id acc) {
        for (HouseholdMember__c member : memberList) {
            if (member.Account__c == acc) {
                return true;
            }
        }
        return false;
    }

    /**
     * creates unique member key(pair of account/household).
     * this is a (before insert) trigger
     * The Unique_Key__c field has the 'unique' attribute which
     * ensures uniqueness across all RG members without the need
     * for a trigger.
     */
    public static void uniqueMemberTrigger(HouseholdMember__c[] triggerMembers){

        for (HouseholdMember__c member : triggerMembers) {
            member.Unique_Key__c = '' + member.Household__c + member.Account__c;
        }

    }

    public static Map<Id, Household__c> getUniqueHouseholds(HouseholdMember__c[] members){

        Set<Id> ids = new Set<Id>();
        for (HouseholdMember__c member : members){
            ids.add(member.Household__c);
        }
        Household__c[] households = new List<Household__c>();
        for (Household__c h : [select Id, PrimaryAccount__c, SecondaryAccount__c, TotalMembers__c from Household__c where Id IN  :ids]) {
            households.add(h);
        }

        Map<Id, Household__c> uniqueHouseholds = new Map<Id, Household__c>();
        for (Household__c household : households){
            uniqueHouseholds.put(household.Id, household);
        }

        return uniqueHouseholds;
    }


    public static Map<Id, HouseholdMember__c[]> getHouseholdToMembersMap(HouseholdMember__c[] members){
        Map<Id, HouseholdMember__c[]> householdToMembers = new Map<Id, HouseholdMember__c[]>();
        for (HouseholdMember__c member : members){
            HouseholdMember__c[] subset = householdToMembers.get(member.Household__c);
            if (subset == null){
                subset = new HouseholdMember__c[]{};
            }
            subset.add(member);
            householdToMembers.put(member.Household__c, subset);
        }
        return householdToMembers;
    }

    public static testMethod void memberLimitInsert_21() {
        Household__c h = new Household__c(name='HouseholdTest');
        insert h;

        Integer numMembers = 21;
        Account[] accs = new Account[numMembers];
        for (Integer i = 0; i < numMembers; i++){
            Account a = new Account(name = 'test');
            accs[i] = a;
        }
        insert accs;
        HouseholdMember__c[] members = new HouseholdMember__c[numMembers];
        for (Integer i = 0; i < numMembers; i++){
            HouseholdMember__c hm = new HouseholdMember__c(Household__c=h.Id,Account__c=accs[i].id);
            members[i] = hm;
        }
        try {
            insert members;
            System.assert(false);
        } catch (System.DmlException e){
            System.assert(e.getMessage().contains(ERROR_MSG_MAX_MEMBERS));
        }
        assertNumMembers(h, 0);
    }

    public static testMethod void memberLimitInsert_20_1() {
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

        assertNumMembers(h, 20);

        Account a = new Account(name = 'test');
        insert a;

        HouseholdMember__c hm = new HouseholdMember__c(Household__c=h.Id,Account__c=a.Id);

        try {
            insert hm;
            System.assert(false);
        } catch (System.DmlException e){
            System.assert(e.getMessage().contains(ERROR_MSG_MAX_MEMBERS));
        }

        assertNumMembers(h, 20);
    }

    public static testMethod void memberLimitInsert_1_20() {

        Household__c h = new Household__c(name='HouseholdTest');
        insert h;

        Account a = new Account(name = 'test');
        insert a;

        HouseholdMember__c hm = new HouseholdMember__c(Household__c=h.Id,Account__c=a.Id);
        insert hm;

        assertNumMembers(h, 1);

        Integer numMembers = 20;
        Account[] accs = new Account[numMembers];
        for (Integer i = 0; i < numMembers; i++){
            Account a2 = new Account(name = 'test');
            accs[i] = a2;
        }
        insert accs;
        HouseholdMember__c[] members = new HouseholdMember__c[numMembers];
        for (Integer i = 0; i < numMembers; i++){
            hm = new HouseholdMember__c(Household__c=h.Id,Account__c=accs[i].Id);
            members[i] = hm;
        }

        try {
            insert members;
            Household__c foo = [select Id, TotalMembers__c from Household__c where name = 'HouseholdTest'];
            System.assert(false);
        } catch (System.DmlException e){
            System.assert(e.getMessage().contains(ERROR_MSG_MAX_MEMBERS));
        }

        assertNumMembers(h, 1);
    }

    static testMethod void memberLimitInsertGovernor() {

        Test.startTest();

        Household__c h = new Household__c(name='HouseholdTest');
        insert h;

        Integer numMembers = 20;
        Account[] accs = new Account[numMembers];
        HouseholdMember__c[] members = new HouseholdMember__c[]{};

        for (Integer i = 0; i < numMembers; i++){
            Account a = new Account(name = 'test');
            accs[i] = a;
        }
        insert accs;

        for (Integer i = 0; i < numMembers; i++){
            HouseholdMember__c hm = new HouseholdMember__c(Household__c=h.Id,Account__c=accs[i].Id);
            members.add(hm);
        }
        insert members;

        assertNumMembers(h, 20);

        Test.stopTest();

    }

    static testMethod void primarySecondaryMemberInsertUpdate(){
        Household__c h = new Household__c(name='HouseholdTest');
        insert h;
        Account a1 = new Account(name = 'test');
        insert a1;
        Account a2 = new Account(name = 'test');
        insert a2;

        HouseholdMember__c hm1 = new HouseholdMember__c(Household__c=h.Id,Account__c=a1.Id, isPrimary__c=true);
        insert hm1;
        HouseholdMember__c hm2 = new HouseholdMember__c(Household__c=h.Id,Account__c=a2.Id,isSecondary__c=true);
        insert hm2;
        assertPrimary(h, a1);
        assertSecondary(h, a2);

        hm1.isPrimary__c = false;
        update hm1;
        assertNumPrimariesSecondaries(h, 0, 1);
        assertSecondary(h, a2);

        hm2.isSecondary__c = false;
        hm2.isPrimary__c = true;
        update hm2;
        assertPrimary(h, a2);
        assertNumPrimariesSecondaries(h, 1, 0);

        hm1.isSecondary__c = true;
        update hm1;
        assertPrimary(h, a2);
        assertSecondary(h, a1);

        hm2.isPrimary__c = false;
        update hm2;
        assertNumPrimariesSecondaries(h, 0, 1);
        assertSecondary(h, a1);

    }

    static testMethod void primaryMemberInsertDuplicate(){
        Household__c h = new Household__c(name='HouseholdTest');
        insert h;
        Account a1 = new Account(name = 'test');
        insert a1;

        Account a2 = new Account(name = 'test');
        insert a2;

        HouseholdMember__c hm1 = new HouseholdMember__c(Household__c=h.Id,Account__c=a1.Id, isPrimary__c = true);
        insert hm1;
        HouseholdMember__c hm2 = new HouseholdMember__c(Household__c=h.Id,Account__c=a2.Id, isPrimary__c = true);
        try {
            insert hm2;
            System.assert(false);
        } catch (System.DmlException e){
            System.assert(e.getMessage().contains(ERROR_MSG_DUPLICATE_CONTACTS));
        }
        assertPrimary(h, a1);
    }

    static testMethod void primaryMemberInsertDuplicateBulk(){
        Household__c h = new Household__c(name='HouseholdTest');
        insert h;
        Account a1 = new Account(name = 'test');
        insert a1;

        Account a2 = new Account(name = 'test');
        insert a2;

        HouseholdMember__c hm1 = new HouseholdMember__c(Household__c=h.Id,Account__c=a1.Id,isPrimary__c = true);
        HouseholdMember__c hm2 = new HouseholdMember__c(Household__c=h.Id,Account__c=a2.Id,isPrimary__c = true);
        HouseholdMember__c[] hms = new HouseholdMember__c[2];
        hms[0] = hm1;
        hms[1] = hm2;

        try {
            insert hms;
            System.assert(false);
        } catch (System.DmlException e){
            System.assert(e.getMessage().contains(ERROR_MSG_DUPLICATE_CONTACTS));
        }

        assertNumPrimariesSecondaries(h, 0, 0);
    }

    static testMethod void secondaryMemberInsertDuplicateBulk(){
        Household__c h = new Household__c(name='HouseholdTest');
        insert h;
        Account a1 = new Account(name = 'test');
        insert a1;

        Account a2 = new Account(name = 'test');
        insert a2;

        HouseholdMember__c hm1 = new HouseholdMember__c(Household__c=h.Id,Account__c=a1.Id,isSecondary__c = true);
        HouseholdMember__c hm2 = new HouseholdMember__c(Household__c=h.Id,Account__c=a2.Id,isSecondary__c = true);
        HouseholdMember__c[] hms = new HouseholdMember__c[2];
        hms[0] = hm1;
        hms[1] = hm2;

        try {
            insert hms;
            System.assert(false);
        } catch (System.DmlException e){
            System.assert(e.getMessage().contains(ERROR_MSG_DUPLICATE_CONTACTS));
        }

        assertNumPrimariesSecondaries(h, 0, 0);
    }

    static testMethod void primarySecondaryMemberUpdateDuplicate(){
        Household__c h = new Household__c(name='HouseholdTest');
        insert h;
        Account a1 = new Account(name = 'test');
        insert a1;

        Account a2 = new Account(name = 'test');
        insert a2;
        HouseholdMember__c hm1 = new HouseholdMember__c(Household__c=h.Id,Account__c=a1.Id,isPrimary__c = true);
        insert hm1;
        HouseholdMember__c hm2 = new HouseholdMember__c(Household__c=h.Id,Account__c=a2.Id,isSecondary__c = true);
        insert hm2;

        hm2.isPrimary__c = true;
        try {
            update hm2;
            System.assert(false);
        } catch (System.DmlException e){
            System.assert(e.getMessage().contains(ERROR_MSG_DUPLICATE_CONTACTS));
        }
        assertPrimary(h, a1);
    }

    static testMethod void primaryMemberUpdateDuplicateBulkPrimaryExists(){
        Household__c h = new Household__c(name='HouseholdTest');
        insert h;
        Account a1 = new Account(name = 'test');
        insert a1;

        Account a2 = new Account(name = 'test');
        insert a2;

        Account a3 = new Account(name = 'test');
        insert a3;

        HouseholdMember__c hm1 = new HouseholdMember__c(Household__c=h.Id,Account__c=a1.Id,isPrimary__c = true);
        insert hm1;
        assertPrimary(h, a1);
        HouseholdMember__c hm2 = new HouseholdMember__c(Household__c=h.Id,Account__c=a2.Id);
        insert hm2;
        HouseholdMember__c hm3 = new HouseholdMember__c(Household__c=h.Id,Account__c=a3.Id);
        insert hm3;

        hm2.isPrimary__c = true;
        hm3.isPrimary__c = true;

        HouseholdMember__c[] members = new HouseholdMember__c[2];
        members[0] = hm2;
        members[1] = hm3;

        try {
            update members;
            System.assert(false);
        } catch (System.DmlException e){
            System.assert(e.getMessage().contains(ERROR_MSG_DUPLICATE_CONTACTS));
        }

        assertPrimary(h, a1);
    }

    static testMethod void primaryMemberUpdateDuplicateBulkNoPrimary(){
        Household__c h = new Household__c(name='HouseholdTest');
        insert h;
        Account a1 = new Account(name = 'test');
        insert a1;

        Account a2 = new Account(name = 'test');
        insert a2;

        HouseholdMember__c hm1 = new HouseholdMember__c(Household__c=h.Id,Account__c=a1.Id);
        insert hm1;
        HouseholdMember__c hm2 = new HouseholdMember__c(Household__c=h.Id,Account__c=a2.Id);
        insert hm2;

        hm1.isPrimary__c = true;
        hm2.isPrimary__c = true;

        HouseholdMember__c[] members = new HouseholdMember__c[2];
        members[0] = hm1;
        members[1] = hm2;

        try {
            update members;
            System.assert(false);
        } catch (System.DmlException e){
            System.assert(e.getMessage().contains(ERROR_MSG_DUPLICATE_CONTACTS));
        }

        assertNumPrimariesSecondaries(h, 0, 0);
    }

    static testMethod void secondaryMemberUpdateDuplicateBulkNoPrimary(){
        Household__c h = new Household__c(name='HouseholdTest');
        insert h;
        Account a1 = new Account(name = 'test');
        insert a1;

        Account a2 = new Account(name = 'test');
        insert a2;

        HouseholdMember__c hm1 = new HouseholdMember__c(Household__c=h.Id,Account__c=a1.Id);
        insert hm1;
        HouseholdMember__c hm2 = new HouseholdMember__c(Household__c=h.Id,Account__c=a2.Id);
        insert hm2;

        hm1.isSecondary__c = true;
        hm2.isSecondary__c = true;

        HouseholdMember__c[] members = new HouseholdMember__c[2];
        members[0] = hm1;
        members[1] = hm2;

        try {
            update members;
            System.assert(false);
        } catch (System.DmlException e){
            System.assert(e.getMessage().contains(ERROR_MSG_DUPLICATE_CONTACTS));
        }

        assertNumPrimariesSecondaries(h, 0, 0);
    }


    static testMethod void uniqueMemberInsertDuplicateBulk(){
        Household__c h = new Household__c(name='HouseholdTest');
        insert h;
        Account a1 = new Account(name = 'test');
        insert a1;

        HouseholdMember__c hm1 = new HouseholdMember__c(Household__c=h.Id,Account__c=a1.Id,isPrimary__c = true);
        HouseholdMember__c hm2 = new HouseholdMember__c(Household__c=h.Id,Account__c=a1.Id,isSecondary__c = true);
        HouseholdMember__c[] members = new HouseholdMember__c[2];
        members[0] = hm1;
        members[1] = hm2;

        try {
            insert members;
            System.assert(false);
        } catch (System.DmlException e){
            System.assert(e.getMessage().contains(ERROR_MSG_DUPLICATE_MEMBERS.substring(28)));

        }

        assertNumMembers(h, 0);
    }

    static testMethod void uniqueMemberCannotUpdate(){
        Household__c h = new Household__c(name='HouseholdTest');
        insert h;
        Account a1 = new Account(name = 'test');
        insert a1;

        Account a2 = new Account(name = 'test');
        insert a2;
        HouseholdMember__c hm1 = new HouseholdMember__c(Household__c=h.Id,Account__c=a1.Id,isPrimary__c = true);
        insert hm1;
        HouseholdMember__c hm2 = new HouseholdMember__c(Household__c=h.Id,Account__c=a2.Id,isSecondary__c = true);
        insert hm2;
        try {
            hm2.Account__c = a1.Id;
            System.assert(false);
        } catch (System.SObjectException e){
            System.assert(e.getMessage().contains('Field is not writeable:') && e.getMessage().contains('Account__c'));
        }
        assertMemberExistsOnce(h, a1);
        assertMemberExistsOnce(h, a2);
    }

    static testMethod void updateContactsAfterUndelete() {
        Household__c h = new Household__c(name='HouseholdTest');
        insert h;
        Account a1 = new Account(name = 'test');
        insert a1;

        Account a2 = new Account(name = 'test');
        insert a2;
        HouseholdMember__c hm1 = new HouseholdMember__c(Household__c=h.Id,Account__c=a1.Id,isPrimary__c = true);
        insert hm1;
        HouseholdMember__c hm2 = new HouseholdMember__c(Household__c=h.Id,Account__c=a2.Id,isSecondary__c = true);
        insert hm2;
        assertPrimary(h, a1);
        assertSecondary(h, a2);
        delete h;
        try {
            delete a1;
            delete a2;
        } catch (DMLException e) {
            return;
        }

        undelete h;
        System.assert(h.PrimaryAccount__c == null);
        System.assert(h.SecondaryAccount__c == null);
        undelete a1;
        undelete a2;
        System.assert(h.PrimaryAccount__c == null);
        System.assert(h.SecondaryAccount__c == null);
    }

    static testMethod void updateContactsAfterUndeleteAccountsFirst() {
        Household__c h = new Household__c(name='HouseholdTest');
        insert h;
        Account a1 = new Account(name = 'test');
        insert a1;

        Account a2 = new Account(name = 'test');
        insert a2;
        HouseholdMember__c hm1 = new HouseholdMember__c(Household__c=h.Id,Account__c=a1.Id,isPrimary__c = true);
        insert hm1;
        HouseholdMember__c hm2 = new HouseholdMember__c(Household__c=h.Id,Account__c=a2.Id,isSecondary__c = true);
        insert hm2;
        assertPrimary(h, a1);
        assertSecondary(h, a2);
        try {
            delete a1;
            delete a2;
        } catch (DMLException e) {
            return;
        }

        delete h;
        undelete a1;
        undelete a2;
        undelete h;
        System.assert(h.PrimaryAccount__c == null);
        System.assert(h.SecondaryAccount__c == null);

    }

    static testMethod void updateTotalMembersAfterUndelete() {
        Household__c h = new Household__c(name='HouseholdTest');
        insert h;
        Account a1 = new Account(name = 'test');
        insert a1;

        Account a2 = new Account(name = 'test');
        insert a2;
        HouseholdMember__c hm1 = new HouseholdMember__c(Household__c=h.Id,Account__c=a1.Id,isPrimary__c = true);
        insert hm1;
        HouseholdMember__c hm2 = new HouseholdMember__c(Household__c=h.Id,Account__c=a2.Id,isSecondary__c = true);
        insert hm2;
        assertPrimary(h, a1);
        assertSecondary(h, a2);
        assertTotalMembers(h, 2);
        delete h;
        try {
            delete a1;
            delete a2;
        } catch (DMLException e) {
            return;
        }

        undelete h;
        h = [select totalmembers__c, PrimaryAccount__c, SecondaryAccount__c from household__c where id = :h.id];
        assertTotalMembers(h, 0);
        System.assert(h.PrimaryAccount__c == null);
        System.assert(h.SecondaryAccount__c == null);
        undelete a1;
        undelete a2;
        assertTotalMembers(h, 0);
        System.assert(h.PrimaryAccount__c == null);
        System.assert(h.SecondaryAccount__c == null);
    }

    static testMethod void updateTotalMembersAfterUndeleteAccountsFirst() {
        Household__c h = new Household__c(name='HouseholdTest');
        insert h;
        Account a1 = new Account(name = 'test');
        insert a1;

        Account a2 = new Account(name = 'test');
        insert a2;
        HouseholdMember__c hm1 = new HouseholdMember__c(Household__c=h.Id,Account__c=a1.Id,isPrimary__c = true);
        insert hm1;
        HouseholdMember__c hm2 = new HouseholdMember__c(Household__c=h.Id,Account__c=a2.Id,isSecondary__c = true);
        insert hm2;
        assertPrimary(h, a1);
        assertSecondary(h, a2);
        assertTotalMembers(h, 2);
        try {
            delete a1;
            delete a2;
        } catch (DMLException e) {
            return;
        }

        delete h;
        undelete a1;
        undelete a2;
        undelete h;
        h = [select totalmembers__c, PrimaryAccount__c, SecondaryAccount__c from household__c where id = :h.id];
        assertTotalMembers(h, 0);
        System.assert(h.PrimaryAccount__c == null);
        System.assert(h.SecondaryAccount__c == null);

    }

    public static void assertTotalMembers(Household__c h, Integer numMembers) {
        h = [SELECT totalMembers__c from Household__c where Id = :h.Id];
        System.assert(h.TotalMembers__c == numMembers);
    }

    public static void assertNumMembers(Household__c h, Integer numMembers){
        HouseholdMember__c[] members = [select Id from HouseholdMember__c where Household__c = :h.Id];
        System.assert(members.size() == numMembers);
    }

    public static void assertPrimary(Household__c h, Account a){
        HouseholdMember__c[] members = [select Id from HouseholdMember__c where Household__c = :h.Id AND Account__c = :a.Id AND isPrimary__c = true];
        System.assert(members.size() == 1);

        Household__c hh = [select Id, PrimaryAccount__c, SecondaryAccount__c from Household__c where Id = :h.Id];
        System.assert(hh.PrimaryAccount__c == a.Id);
    }

    public static void assertSecondary(Household__c h, Account a){
        HouseholdMember__c[] members = [select Id from HouseholdMember__c where Household__c = :h.Id AND Account__c = :a.Id  AND isSecondary__c = true];
        System.assert(members.size() == 1);

        Household__c hh = [select Id, PrimaryAccount__c, SecondaryAccount__c from Household__c where Id = :h.Id];
        System.assert(hh.SecondaryAccount__c == a.Id);
    }

    public static void assertNumPrimariesSecondaries(Household__c h, Integer numPrimaries, Integer numSecondaries){

        HouseholdMember__c[] members = [select Id from HouseholdMember__c where Household__c = :h.Id AND isPrimary__c = true];
        System.assert(members.size() == numPrimaries);

        members = [select Id from HouseholdMember__c where Household__c = :h.Id AND isSecondary__c = true];
        System.assert(members.size() == numSecondaries);

        Household__c hh = [select Id, PrimaryAccount__c, SecondaryAccount__c from Household__c where Id = :h.Id];
        if (numPrimaries == 0){
            System.assert(hh.PrimaryAccount__c == null);
        }
        if (numSecondaries == 0){
            System.assert(hh.SecondaryAccount__c == null);
        }
    }

    public static void assertMemberExistsOnce(Household__c h, Account a){
        HouseholdMember__c[] members = [select Id from HouseholdMember__c where Household__c = :h.Id AND Account__c = :a.Id];
        System.assert(members.size() == 1);
    }


}