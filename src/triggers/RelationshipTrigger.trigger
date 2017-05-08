trigger RelationshipTrigger on Relationship__c (after insert, before update, after update) {

	if(Trigger.isAfter) {
		if(Trigger.isInsert) {
			RelationshipTriggerHandler.onAfterInsert(Trigger.new, Trigger.newMap);
		} else if(Trigger.isUpdate) {
			RelationshipTriggerHandler.onAfterUpdate(Trigger.new, Trigger.oldMap);
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
