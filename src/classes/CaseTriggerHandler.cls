public class CaseTriggerHandler {

	public void onAfterInsert(List<Case__c> newList) {
		List<Case__c> caseWithCareGiverList = new List<Case__c>();
		for(Case__c c : newList) {
			if(String.isNotBlank(c.Caregiver__c)) {
				caseWithCareGiverList.add(c);
			}
		}
		if(!caseWithCareGiverList.isEmpty()) createCaseCaregiverRelationships(caseWithCareGiverList);
	}

	public void onAfterUpdate(List<Case__c> newList, Map<Id, Case__c> oldMap) {
		List<Case__c> caseWithCareGiverList = new List<Case__c>();
		List<Case__C> caseNameChangedList = new List<Case__C>();
		for(Case__c c : newList) {
			if(String.valueOf(c.Caregiver__c) != oldMap.get(c.Id).Caregiver__c && String.isNotBlank(String.valueOf(c.Caregiver__c))) {
				caseWithCareGiverList.add(c);
			}
			if(c.Name != oldMap.get(c.Id).Name) {
				caseNameChangedList.add(c);
			}
		}
		if(!caseWithCareGiverList.isEmpty()) createCaseCaregiverRelationships(caseWithCareGiverList);
		if(!caseNameChangedList.isEmpty()) updateRelationshipExplanation(caseNameChangedList);
	}

	private void updateRelationshipExplanation(List<Case__c> newList) {
		Map<Id, Case__c> caseMap = new Map<Id, Case__c>(newList);
		List<Relationship__c> relationshipList = [SELECT Id, Case__c, Case_Related__c, Explanation__c FROM Relationship__c WHERE Case__c IN :caseMap.keySet() OR Case_Related__c IN :caseMap.keySet()];
		for(Relationship__c r : relationshipList) {
			Id cId = String.isNotBlank(r.Case__c) ? r.Case__c : r.Case_Related__c;
			String caseId = cId;
			caseId = caseId.substring(0, 15);
			String caseName = caseMap.get(cId).Name;
			String placeholderName = '';
			if(r.Explanation__c.contains('[autoname]')) {
				r.Explanation__c = r.Explanation__c.replace('[autoname]', caseName);
			} else if(r.Explanation__c.contains(caseId)) {
				r.Explanation__c = r.Explanation__c.replace(caseId, caseName);
			}
		}
		update relationshipList;
	}

	private void createCaseCaregiverRelationships(List<Case__c> caseWithCareGiverList) {
		Set<Id> contactIdSet = new Set<Id>();
		for(Case__c c : caseWithCareGiverList) {
			contactIdSet.add(c.Caregiver__c);
		}
		Map<Id, Contact> caregiverMap = new Map<Id, Contact>([SELECT Id, Name, AccountId, Account.Name, Caregiver_Relationship_to_Infant__c FROM Contact WHERE Id IN :contactIdSet]);
		List<Relationship__c> relationshipList = new List<Relationship__c>();
		for(Case__c c : caseWithCareGiverList) {
			Relationship__c r = new Relationship__c();
			r.Case_Related__c = c.Id;
			r.Contact__c = c.Caregiver__c;
			r.Type__c = caregiverMap.get(c.Caregiver__c).Caregiver_Relationship_to_Infant__c;
			r.Explanation__c = caregiverMap.get(c.Caregiver__c).Name + ' is the ' + r.Type__c + ' of ' + c.Name;
			relationshipList.add(r);
			r = new Relationship__c();
			r.Case__c = c.Id;
			r.Account_Related__c = caregiverMap.get(c.Caregiver__c).AccountId;
			r.Type__c = 'Household Member';
			r.Explanation__c = c.Name + ' is the ' + r.Type__c + ' of ' + caregiverMap.get(c.Caregiver__c).Account.Name;
			relationshipList.add(r);
		}
		insert relationshipList;
	}
}