trigger ReferralTrigger on Referral__c (after insert, after update) {

	List<Id> idSet = new List<Id>();
    List<String> addressFieldList = new List<String>();

    if(Trigger.isAfter) {
        if(Trigger.isInsert) {
			idSet.addAll(Trigger.newMap.keySet());
		} else if(Trigger.isUpdate) {
		    for(Referral__c r : (List<Referral__c>)Trigger.new) {
                for(String f : addressFieldList) {
                    if(String.valueOf(r.get(f)) != String.valueOf(Trigger.oldMap.get(r.Id).get(f))) {
                        idSet.add(r.Id);
                        break;
                    }
                }
            }
        }
    }
    if(!idSet.isEmpty()) {
		AddressLookupUtil.updateFields(idSet, 'Referral__c');
    }
}