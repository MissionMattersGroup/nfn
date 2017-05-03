trigger RelationshipTrigger on Relationship__c (after insert, before update) {

	if(Trigger.isAfter) {
		if(Trigger.isInsert) {
			if(RelationshipTriggerHandler.isFirstRun) {
				RelationshipTriggerHandler.setFirstRun();
				RelationshipTriggerHandler.onAfterInsert(Trigger.new, Trigger.newMap);
			}
		}
	} else if(Trigger.isBefore) {
		if(Trigger.isUpdate) {
			if(RelationshipTriggerHandler.isFirstRun) {
				RelationshipTriggerHandler.setFirstRun();
				RelationshipTriggerHandler.onBeforeUpdate(Trigger.new, Trigger.oldMap);
			}
		}
	}
}