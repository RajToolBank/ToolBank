trigger HouseholdMemberUndeleteTrigger on HouseholdMember__c (after undelete) {
	for (HouseholdMember__c member : Trigger.new) {
		if (member.HardDeleted__c) {
			member.addError(HouseholdTrigger.ERROR_MSG_CANNOT_UNDELETE);
		}
	}
}