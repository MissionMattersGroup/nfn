trigger ContactTrigger on Contact (after insert, after update) {

    List<Id> contactIdSet = new List<Id>();
    List<String> addressFieldList = new List<String>();

    if(Trigger.isAfter) {
        if(Trigger.isInsert) {
			System.debug('mlh line 8');
			contactIdSet.addAll(Trigger.newMap.keySet());
		} else if(Trigger.isUpdate) {
			System.debug('mlh line 11');
		    for(Contact c : (List<Contact>)Trigger.new) {
				System.debug('mlh line 13');
                for(String f : addressFieldList) {
					System.debug('mlh line 15');
                    if(String.valueOf(c.get(f)) != String.valueOf(Trigger.oldMap.get(c.Id).get(f))) {
						System.debug('mlh line 17');
                        contactIdSet.add(c.Id);
                        break;
                    }
                }
            }
        }
    }
    if(!contactIdSet.isEmpty()) {
		System.debug('mlh line 26');
		AddressLookupUtil.updateFields(contactIdSet, 'Contact');
    }
}
