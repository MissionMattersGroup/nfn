trigger TimeEntryTrigger on Time_Entry__c (after insert, after update, after delete) {

	TimeEntryTriggerHandler handler = new TimeEntryTriggerHandler();

	if(Trigger.isAfter) {
		if(Trigger.isInsert) {
			handler.onAfterInsert(Trigger.new);
		} else if(Trigger.isUpdate) {
			handler.onAfterUpdate(Trigger.new, Trigger.oldMap);
		} else if(Trigger.isDelete) {
			handler.onAfterDelete(Trigger.old);
		}
	}
}