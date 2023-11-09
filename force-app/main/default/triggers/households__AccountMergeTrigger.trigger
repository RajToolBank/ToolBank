trigger AccountMergeTrigger on Account (after delete, after undelete) {

	if (Trigger.isDelete) {
		AccountMerge.updateRGMembers(Trigger.old);
	}

	if (Trigger.isUndelete) {
		Id[] accountIds = new List<Id>();
		for (Account acc : Trigger.new) {
			accountIds.add(acc.Id);
		}
		HouseholdMember__c[] members = new List<HouseholdMember__c>();

		for (HouseholdMember__c m : [select Id, Unique_Key__c, isPrimary__c, isSecondary__c, Account__c, Household__c from HouseholdMember__c where Account__c in :accountIds]){
			members.add(m);
		}
		UndeleteAccount.maxMemberLimitTrigger(Trigger.new, members);
   		UndeleteAccount.primarySecondaryMemberTriggerPre(Trigger.new, members);

   		Household__c[] houses = new List<Household__c>();
   		for (Household__c h : [select Id, PrimaryAccount__c, SecondaryAccount__c from Household__c where (PrimaryAccount__c in :accountIds) OR (SecondaryAccount__c in :accountIds)]){
			houses.add(h);
		}
		HouseholdTrigger.verifyContactFields(houses);


	}
}