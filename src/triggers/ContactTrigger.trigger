trigger ContactTrigger on Contact (after insert, after update) {

    List<Id> contactIdSet = new List<Id>();
    List<String> addressFieldList = new List<String>();
	ContactTriggerHandler handler = new ContactTriggerHandler();

    if(Trigger.isAfter) {
        if(Trigger.isInsert) {
			contactIdSet.addAll(Trigger.newMap.keySet());
			handler.onAfterInsert(Trigger.new);
		} else if(Trigger.isUpdate) {
			handler.onAfterUpdate(Trigger.new, Trigger.oldMap);
		    for(Contact c : (List<Contact>)Trigger.new) {
                for(String f : addressFieldList) {
                    if(String.valueOf(c.get(f)) != String.valueOf(Trigger.oldMap.get(c.Id).get(f))) {
                        contactIdSet.add(c.Id);
                        break;
                    }
                }
            }
        }
    }
    if(!contactIdSet.isEmpty()) {
		AddressLookupUtil.updateFields(contactIdSet, 'Contact');
    }
}