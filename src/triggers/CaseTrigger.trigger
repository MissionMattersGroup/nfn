trigger CaseTrigger on Case__c (after insert, after update) {

	CaseTriggerHandler handler = new CaseTriggerHandler();
	if(Trigger.isAfter) {
		if(Trigger.isInsert) {
			handler.onAfterInsert(Trigger.new);
		} else if(Trigger.isUpdate) {
			handler.onAfterUpdate(Trigger.new, Trigger.oldMap);
		}
	}
}