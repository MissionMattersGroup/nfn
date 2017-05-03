public class ContactTriggerHandler {

	public void onAfterInsert(List<Contact> newList) {
		List<Contact> contactAccountChangeList = new List<Contact>();
		for(Contact c : newList) {
			if(String.isNotBlank(c.AccountId)) contactAccountChangeList.add(c);
		}
		if(!contactAccountChangeList.isEmpty()) createRelationshipWithHousehold(contactAccountChangeList);
	}

	public void onAfterUpdate(List<Contact> newList, Map<Id, Contact> oldMap) {
		List<Contact> contactAccountChangeList = new List<Contact>();
		for(Contact c : newList) {
			if(c.AccountId != oldMap.get(c.Id).AccountId) contactAccountChangeList.add(c);
		}
		if(!contactAccountChangeList.isEmpty()) createRelationshipWithHousehold(contactAccountChangeList);
	}

	private void createRelationshipWithHousehold(List<Contact> newList) {
		List<Relationship__c> relationshipList = new List<Relationship__c>();
		Map<Id, Contact> contactMap = new Map<Id, Contact>(newList);
		Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, Name FROM Account WHERE Id IN (SELECT AccountId FROM Contact WHERE Id IN :contactMap.keySet())]);
		for(Contact c : newList) {
			Relationship__c r = new Relationship__c(Contact__c = c.Id, Account_Related__c = c.AccountId, Type__c = 'Household Member', Status__c = 'Current');
			r.Explanation__c = c.FirstName + ' ' + c.LastName + ' is the Household Member of ' + accountMap.get(c.AccountId).Name;
			relationshipList.add(r);
		}
		insert relationshipList;
	}
}