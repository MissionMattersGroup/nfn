public class RelationshipTriggerHandler {

	public static Boolean isFirstRun = true;
	public static void setFirstRun() { isFirstRun = false; }

	public static void onAfterInsert(List<Relationship__c> newList, Map<Id, Relationship__c> newMap) {
		Set<Id> relationshipWithNoRecipIdSet = new Set<Id>();
		for(Relationship__c r : newList) {
			if(String.isBlank(r.Reciprocal_Relationship__c)) {
				relationshipWithNoRecipIdSet.add(r.Id);
			}
		}
		if(!relationshipWithNoRecipIdSet.isEmpty()) createReciprocalRelationships(relationshipWithNoRecipIdSet, false);
	}

	public static void onBeforeUpdate(List<Relationship__c> newList, Map<Id, Relationship__c> oldMap) {
		List<Id> recipIdList = new List<Id>();
		Set<Id> relationshipWithNoRecipIdSet = new Set<Id>();
		for(Relationship__c r : newList) {
			if(r.Type__c != oldMap.get(r.Id).Type__c) {
				relationshipWithNoRecipIdSet.add(r.Id);
				recipIdList.add(r.Reciprocal_Relationship__c);
			}
		}
		if(!recipIdList.isEmpty()) {
			delete [SELECT Id FROM Relationship__c WHERE Id IN :recipIdList];
			createReciprocalRelationships(relationshipWithNoRecipIdSet, false);
		}
	}

	private static void createReciprocalRelationships(Set<Id> relationshipIdSet, Boolean doUpdate) {
		Map<String, String> relatedObjectNameByLookupFieldMap = new Map<String, String>();
		List<String> lookupList = new List<String>();
		for(Schema.SObjectField field : Schema.getGlobalDescribe().get('Relationship__c').getDescribe().fields.getMap().values()) {
			if(field.getDescribe().getLabel().endsWith(' Related')) {
				lookupList.add(field.getDescribe().getName().replace('_Related__c', '__c'));
			}
		}
		Map<Id, Relationship__c> relationshipMap = new Map<Id, Relationship__c>((List<Relationship__c>)QueryUtility.selectStar('Relationship__c', relationshipIdSet));
		Map<String, Relationship_Settings__c> settingsMap = new Map<String, Relationship_Settings__c>();
		for(Relationship_Settings__c s : [SELECT Relationship_Name__c, Female_Reciprocal__c, Male_Reciprocal__c, Neutral_Reciprocal__c FROM Relationship_Settings__c]) {
			settingsMap.put(s.Relationship_Name__c, s);
		}
		List<Relationship__c> reciprocalRelationshipList = new List<Relationship__c>();
		Map<String, Set<String>> relatedIdSetByObjectNameMap = new Map<String, Set<String>>();
		Map<Id, Relationship__c> reciprocalRelationshipByPrimaryIdMap = new Map<Id, Relationship__c>();
		for(Relationship__c r : relationshipMap.values()) {
			if(String.isBlank(r.Type__c)) continue;
			String recipPrimaryLookup;
			String recipSecondaryLookup;
			Relationship__c recip = new Relationship__c();
			for(String lookupField : lookupList) {
				String relatedlookupField = lookupField.replace('__c', '_Related__c');
				if(String.isNotBlank(String.valueOf(r.get(lookupField)))) {
					Id primaryId = (Id)r.get(lookupField);
					String objectName = primaryId.getSObjectType().getDescribe().getName();
					reciprocalRelationshipByPrimaryIdMap.put(r.Id, recip);
					recip.put(lookupField.replace('__c', '_Related__c'), primaryId);
				}
				if(String.isNotBlank(String.valueOf(r.get(relatedlookupField)))) {
					Id secondaryId = (Id)r.get(lookupField.replace('__c', '_Related__c'));
					String objectName = secondaryId.getSObjectType().getDescribe().getName();
					if(!relatedIdSetByObjectNameMap.containsKey(objectName)) relatedIdSetByObjectNameMap.put(objectName, new Set<String>());
					Set<String> relatedIdSet = relatedIdSetByObjectNameMap.get(objectName);
					relatedIdSet.add(String.valueOf(secondaryId));
					relatedIdSetByObjectNameMap.put(objectName, relatedIdSet);
					recip.put(lookupField, (Id)r.get(lookupField.replace('__c', '_Related__c')));
				}
				reciprocalRelationshipByPrimaryIdMap.put(r.Id, recip);
			}
		}
		Map<Id, SObject> relatedObjectMap = new Map<Id, SObject>();
		Map<String, Schema.SObjectType> objMap = Schema.getGlobalDescribe();
		for(String objName : relatedIdSetByObjectNameMap.keyset()) {
			String query = 'SELECT Id, Name';
			if(objMap.get(objName).getDescribe().fields.getMap().containsKey('Gender__c')) {
				query += ', Gender__c';
			}
			query += ' FROM ' + objName + ' WHERE Id IN (\'' + String.join(new List<String>(relatedIdSetByObjectNameMap.get(objName)), '\', \'') + '\')';
			for(SObject so : Database.query(query)) {
				relatedObjectMap.put(so.Id, so);
			}
		}
		for(Relationship__c r : relationshipMap.values()) {
			Relationship__c recip = reciprocalRelationshipByPrimaryIdMap.get(r.Id);
			String genderSettingsField = 'Neutral_Reciprocal__c';
			String primaryLookup;
			String secondaryLookup;
			for(String lookupField : lookupList) {
				if(String.isNotBlank(String.valueOf(recip.get(lookupField)))) primaryLookup = lookupField;
				String relatedLookupField = lookupField.replace('__c', '_Related__c');
				if(String.isNotBlank(String.valueOf(r.get(relatedLookupField)))) {
					Id lookupId = (Id)r.get(relatedLookupField);
					SObject so = relatedObjectMap.get(lookupId);
					if(lookupId.getSObjectType().getDescribe().fields.getMap().containsKey('Gender__c') && String.isNotBlank(String.valueOf(so.get('Gender__c')))) {
						genderSettingsField = String.valueOf(so.get('Gender__c')) + '_Reciprocal__c';
					}
					secondaryLookup = relatedLookupField;
				}
			}
			recip.Type__c = String.valueOf(settingsMap.get(r.Type__c).get(genderSettingsField));
			recip.Reciprocal_Relationship__c = r.Id;
			recip.Relationship_From__c = r.Relationship_From__c;
			recip.Relationship_To__c = r.Relationship_To__c;
			recip.Status__c = r.Status__c;
			List<String> explanationList = r.Explanation__c.split(' is the ', 2);
			String secondaryName = explanationList[0];
			String primaryName = explanationList[1].split(r.Type__c + ' of ', 2)[1];
			recip.Explanation__c = primaryName + ' is the ' + recip.Type__c + ' of ' + secondaryName;
			reciprocalRelationshipList.add(recip);
		}
		if(!reciprocalRelationshipList.isEmpty()) insert reciprocalRelationshipList;
		List<Relationship__c> relationshipUpdateList = new List<Relationship__c>();
		for(Relationship__c recip : reciprocalRelationshipList) {
			Relationship__c r = relationshipMap.get(recip.Reciprocal_Relationship__c);
			r.Reciprocal_Relationship__c = recip.Id;
			relationshipUpdateList.add(r);
		}
		if(doUpdate) {
			update relationshipUpdateList;
		}
	}
}
