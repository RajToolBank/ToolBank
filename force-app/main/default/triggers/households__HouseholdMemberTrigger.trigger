trigger HouseholdMemberTrigger on HouseholdMember__c (before insert, before update, before delete, after undelete) {
	if (HouseholdTrigger.areMemberTriggersEnabled()) {
		HouseholdTrigger.memberBeingInserted = true;
		if (Trigger.isInsert || Trigger.isUpdate) {
			HouseholdTrigger.hardDeletedNotEditable(Trigger.new);
			if (Trigger.isInsert) {
				HouseholdTrigger.maxMemberLimitTrigger(Trigger.new);
			}
			HouseholdTrigger.uniqueMemberTrigger(Trigger.new);
			HouseholdTrigger.multipleContactStatusTrigger(Trigger.new);
   			HouseholdTrigger.primarySecondaryMemberTriggerPre(Trigger.new);
		} else if (Trigger.isUndelete) {
			HouseholdTrigger.maxMemberLimitTrigger(Trigger.new);
   			HouseholdTrigger.primarySecondaryMemberTriggerPre(Trigger.new);
		} else {
			HouseholdTrigger.updateHouseholdContactStatus(Trigger.old);
		}
	}
}