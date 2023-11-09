/* duplicate of some household trigger functions, except that
 * errors are added to the parent account instead of
 * the householdMember
 */

public class UndeleteAccount {

	public static void maxMemberLimitTrigger(Account[] accs, HouseholdMember__c[] triggerMembers) {
		Map<Id, HouseholdMember__c[]> householdToMembers = HouseholdTrigger.getHouseholdToMembersMap(triggerMembers);
		Map<Id, Household__c> householdMap = HouseholdTrigger.getUniqueHouseholds(triggerMembers);
		Map<Id, Account> accountMap = idToAccount(accs);
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
					Account a = accountMap.get(member.Account__c);
					a.addError(HouseholdTrigger.ERROR_MSG_MAX_MEMBERS);
				}
			}
		}
	}

	/**
	 *Makes sure that all primary and secondary contact assignments are valid.  1 primary and
	 * 1 secondary per household.
	 **/
	public static void primarySecondaryMemberTriggerPre(Account[] accs, HouseholdMember__c[] triggerMembers) {
		Map<Id, HouseholdMember__c[]> householdToMembers = HouseholdTrigger.getHouseholdToMembersMap(triggerMembers);
		Map<Id, Household__c> householdMap = HouseholdTrigger.getUniqueHouseholds(triggerMembers);
		Household__c[] householdsBeingChanged = householdMap.values();
		Household__c[] householdsToUpdate = new List<Household__c>();
		Map<Id, Account> accountMap = idToAccount(accs);

		for (Household__c house : householdsBeingChanged) {
			Boolean problem = false;
			Map<String, Id> priority = new Map<String, Id>();
			HouseholdMember__c[] members = householdToMembers.get(house.Id);

			if ((house.PrimaryAccount__c != null) && !HouseholdTrigger.containsAccount(triggerMembers, house.PrimaryAccount__c)) {
				priority.put(HouseholdTrigger.MEMBER_PRIORITY_PRIMARY, house.PrimaryAccount__c);
			}
			if ((house.SecondaryAccount__c != null) && !HouseholdTrigger.containsAccount(triggerMembers, house.SecondaryAccount__c)) {
				priority.put(HouseholdTrigger.MEMBER_PRIORITY_SECONDARY, house.SecondaryAccount__c);
			}

			for (HouseholdMember__c member : members) {
				if (member.isPrimary__c == true){
					if (priority.get(HouseholdTrigger.MEMBER_PRIORITY_PRIMARY) == null) {
						priority.put(HouseholdTrigger.MEMBER_PRIORITY_PRIMARY, member.Account__c);
					} else {
						problem = true;
						break;
					}
				} else if (member.isSecondary__c == true){
					if (priority.get(HouseholdTrigger.MEMBER_PRIORITY_SECONDARY) == null) {
						priority.put(HouseholdTrigger.MEMBER_PRIORITY_SECONDARY, member.Account__c);
					} else {
						problem = true;
						break;
					}
				}
			}
			if (problem) {
				for (HouseholdMember__c member : members) {
					Account a = accountMap.get(member.Account__c);
					a.addError(HouseholdTrigger.ERROR_MSG_DUPLICATE_CONTACTS);
				}
			} else {
				house.PrimaryAccount__c = priority.get(HouseholdTrigger.MEMBER_PRIORITY_PRIMARY);
				house.SecondaryAccount__c = priority.get(HouseholdTrigger.MEMBER_PRIORITY_SECONDARY);
				householdsToUpdate.add(house);
			}
		}
		update householdsToUpdate;
	}




	static Map<Id, Account> idToAccount(Account[] accs) {
		Map<Id, Account> accountMap = new Map<Id, Account>();

		for (Account a : accs) {
			accountMap.put(a.Id, a);
		}

		return accountMap;
	}

}