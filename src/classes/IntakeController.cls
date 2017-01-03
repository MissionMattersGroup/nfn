global class IntakeController {

    global Map<Integer, TargetObject> targetObjectMap { get; set; }
    global Map<Integer, Map<String, Object>> fieldValueMapByOrderKeyMap { get; set; }
    global Map<Integer, String> missingSourceFieldByDisplayOrderMap { get; set; }
	global Map<String, String> missingSourceFieldMap { get; set; }
	global List<Integer> missingFieldDisplayOrderList { get; set; }
	global Referral__c referral { get; set; }
	private String retUrl { get; set; }
    global Map<Integer, Boolean> pageDisplayMap { get; set; }
    global Contact client { get; set; }
	global Account household { get; set; }
	global Case__c nfnCase { get; set; }
    global Boolean hasError { get; set; }
	global Boolean hasMissingSourceData { get; set; }
    global String orgName { get; set; }

    class TargetObject {
		public String sobjectType { get; set; }
        public SObject so { get; set; }
        public String soName { get; set; }
        public Schema.SObjectType soType { get; set; }
        public Map<String, Object> valueByFieldMap { get; set; }
        public String soRtName { get; set; }

        public TargetObject(String sn, Schema.SObjectType st, Map<String, Object> vfMap) {
            soName = sn;
            soType = st;
            valueByFieldMap = vfMap;
            sobjectType = st.getDescribe().getLabel();
            soRtName = String.valueOf(vfMap.get('RecordTypeId'));
        }

        public SObject assignValues() {
			so = Database.query('SELECT Id FROM ' + soName + ' LIMIT 1')[0].getSObjectType().newSObject();
            for(String field : valueByFieldMap.keySet()) {
				Object value = field == 'RecordTypeId' ? soType.getDescribe().getRecordTypeInfosByName().get(String.valueOf(valueByFieldMap.get(field))).getRecordTypeId() : valueByFieldMap.get(field);
                if(value != null && field != null) so.put(field, value);
            }
            return so;
        }
    }

    public IntakeController() {
        orgName = [SELECT Name FROM Organization LIMIT 1].Name;
		hasMissingSourceData = false;
        hasError = false;
		missingSourceFieldByDisplayOrderMap = new Map<Integer, String>();
		missingSourceFieldMap = new Map<String, String>();
		pageDisplayMap = new Map<Integer, Boolean>();
		for(Integer i=0; i<5; i++) pageDisplayMap.put(i, false);
        targetObjectMap = new Map<Integer, TargetObject>();
        fieldValueMapByOrderKeyMap = new Map<Integer, Map<String, Object>>();
		if(ApexPages.currentPage().getParameters().containsKey('ContactId')) {
			client = [SELECT Id, Name, FirstName, LastName, AccountId FROM Contact WHERE Id = :ApexPages.currentPage().getParameters().get('ContactId')];
			retUrl = '/' + client.Id;
			referral = Database.query(QueryUtility.getSelectStarQuery('Referral__c') + ' WHERE Client__c = \'' + client.Id + '\'');
			updatePageDisplayMap(2);
        } else {
            referral = Database.query(QueryUtility.getSelectStarQuery('Referral__c') + ' WHERE Id = \'' + ApexPages.currentPage().getParameters().get('id') + '\'');
            retUrl = '/' + referral.Id;
            if(String.isNotBlank(String.valueOf(referral.get('Client__c')))) {
                client = [SELECT Id, FirstName, LastName, Name, AccountId FROM Contact WHERE Id = :String.valueOf(referral.get('Client__c'))];
                retUrl = '/' + client.Id;
            }
            evaluateConversion();
        }
    }

	global void updateReferral() {
		update Referral;
		for(Integer displayOrder : missingSourceFieldByDisplayOrderMap.keySet()) {
			if(String.isNotBlank(String.valueOf(referral.get(missingSourceFieldByDisplayOrderMap.get(displayOrder))))) {
				missingSourceFieldMap.remove(missingSourceFieldByDisplayOrderMap.get(displayOrder));
				missingSourceFieldByDisplayOrderMap.remove(displayOrder);
			}
		}
		if(missingSourceFieldByDisplayOrderMap.isEmpty()) {
			hasMissingSourceData = false;
			evaluateConversion();
			updatePageDisplayMap(1);
		}
	}

    global void processReferral() {
        List<SObject> newSObjectList = new List<SObject>();
        for(Integer orderKey : targetObjectMap.keySet()) newSObjectList.add(targetObjectMap.get(orderKey).assignValues());
        insert newSObjectList;
        List<Contact> contactList = new List<Contact>();
        Id clientId;
        for(SObject so : newSObjectList) {
            if(String.valueOf(so.Id).startsWith('003')) {
                if(Schema.SObjectType.Contact.getRecordTypeInfosById().get(String.valueOf(so.get('RecordTypeId'))).getName() == 'Client') {
                    contactList.add((Contact)so);
                    client = (Contact)so;
					retUrl = '/' + client.Id;
                }
            } else if(String.valueOf(so.Id).startsWith('001')) {
                household = (Account)so;
            }
        }
    }

    global PageReference save() {
        hasError = false;
        return null;
    }

    global PageReference cancel() {
        return new PageReference(retUrl);
    }

	private void evaluateConversion() {
		Map<Integer, String> soNameMap = new Map<Integer, String>();
        String ocQuery = 'SELECT Required__c, Display_Order__c, Source_Object_API_Name__c, Target_Object_API_Name__c, Source_Field__c, Source_Field_API_Name__c, Target_Field_API_Name__c, Target_Value__c, Order__c FROM Object_Conversion__c WHERE Recordtype.Name = \'referral Processing\' ORDER BY Order__c';
        for(Object_Conversion__c oc : (List<Object_Conversion__c>)Database.query(ocQuery)) {
            Integer orderKey = Integer.valueOf(oc.Order__c);
            Map<String, Object> valueByFieldMap = fieldValueMapByOrderKeyMap.containsKey(orderKey) ? fieldValueMapByOrderKeyMap.get(orderKey) : new Map<String, Object>();
            Object value;
			Boolean tmpHasMissing = false;
			if(String.isNotBlank(oc.Target_Value__c)) {
				value = oc.get('Target_Value__c');
			} else if(String.isNotBlank(oc.Source_Field_API_Name__c) && String.isNotBlank(String.valueOf(referral.get(oc.Source_Field_API_Name__c)))) {
				value = referral.get(oc.Source_Field_API_Name__c);
			} else if(oc.Required__c) {
				missingSourceFieldByDisplayOrderMap.put(Integer.valueOf(oc.Display_Order__c), oc.Source_Field_API_Name__c);
				missingSourceFieldMap.put(oc.Source_Field_API_Name__c, oc.Source_Field__c);
				hasMissingSourceData = true;
				tmpHasMissing = true;
			}
			if(!tmpHasMissing) {
                valueByFieldMap.put(oc.Target_Field_API_Name__c, value);
                fieldValueMapByOrderKeyMap.put(orderKey, valueByFieldMap);
                if(!soNameMap.containsKey(orderKey)) soNameMap.put(orderKey, oc.Target_Object_API_Name__c);
			}
        }
		if(hasMissingSourceData) {
			missingFieldDisplayOrderList = new List<Integer>(missingSourceFieldByDisplayOrderMap.keySet());
			missingFieldDisplayOrderList.sort();
			updatePageDisplayMap(0);
		} else {
            Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
			for(Integer orderKey : fieldValueMapByOrderKeyMap.keySet()) {
				targetObjectMap.put(orderKey, new TargetObject(soNameMap.get(orderKey), gd.get(soNameMap.get(orderKey)), fieldValueMapByOrderKeyMap.get(orderKey)));
			}
			updatePageDisplayMap((String.isBlank(String.valueOf(referral.get('Client__c'))) ? 1 : 2));
        }
	}

	private void updatePageDisplayMap(Integer page) { for(Integer p : pageDisplayMap.keySet()) pageDisplayMap.put(p, page == p); }
}