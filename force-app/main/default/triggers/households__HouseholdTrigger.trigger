trigger HouseholdTrigger on Household__c (before insert, before update, after undelete) {

	if (Trigger.isUndelete) {
		Id[] houseIds = new List<Id>();
		for (Household__c house : Trigger.new) {
			houseIds.add(house.Id);
		}
		Household__c[] houses = [SELECT Id, PrimaryAccount__c, SecondaryAccount__c from Household__c WHERE Id IN : houseIds];
		HouseholdTrigger.verifyContactFields(houses);

	} else if (HouseholdTrigger.areHouseholdTriggersEnabled()) {
	 	if (Trigger.isInsert) {
			HouseholdTrigger.contactsOnHouseholdsNotEditableInsert(Trigger.new);
		}
		else HouseholdTrigger.contactsOnHouseholdsNotEditableEdit(Trigger.new, Trigger.old);
	}
}