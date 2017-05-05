global class IntakeController {

    global Map<Integer, TargetObject> targetObjectMap { get; set; }
    global Map<Integer, Map<String, Object>> fieldValueMapByOrderKeyMap { get; set; }
    global Map<Integer, String> missingSourceFieldByDisplayOrderMap { get; set; }
	global Map<String, String> missingSourceFieldMap { get; set; }
	global List<Integer> missingFieldDisplayOrderList { get; set; }
	global Referral__c referral { get; set; }
	global String retUrl { get; set; }
    global Map<Integer, Boolean> pageDisplayMap { get; set; }
    global Contact caregiver { get; set; }
	global Case__c nfnCase { get; set; }
    global Boolean hasError { get; set; }
	global Boolean hasMissingSourceData { get; set; }
    global String orgName { get; set; }
    global String returnTo { get; set; }
    global String baseurl { get { return Url.getSalesforceBaseUrl().toExternalForm(); } }

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
		retUrl = '';
		if(ApexPages.currentPage().getParameters().containsKey('ContactId')) {
			caregiver = [SELECT Id, Name, FirstName, LastName, AccountId FROM Contact WHERE Id = :ApexPages.currentPage().getParameters().get('ContactId')];
			retUrl = '/' + caregiver.Id;
			referral = Database.query(QueryUtility.getSelectStarQuery('Referral__c') + ' WHERE Caregiver__c = \'' + caregiver.Id + '\'');
			updatePageDisplayMap(2);
        } else {
            referral = Database.query(QueryUtility.getSelectStarQuery('Referral__c') + ' WHERE Id = \'' + ApexPages.currentPage().getParameters().get('id') + '\'');
            retUrl = '/' + referral.Id;
            if(String.isNotBlank(String.valueOf(referral.get('Caregiver__c')))) {
                caregiver = [SELECT Id, FirstName, LastName, Name, AccountId FROM Contact WHERE Id = :String.valueOf(referral.get('Caregiver__c'))];
                retUrl = '/' + caregiver.Id;
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

    global PageReference processReferral() {
        List<SObject> newSObjectList = new List<SObject>();
		Address_History__c ah = new Address_History__c();
        for(Integer orderKey : targetObjectMap.keySet()) {
			TargetObject to = targetObjectMap.get(orderKey);
			if(!to.sObjectType.equalsIgnoreCase('Address History')) {
				newSObjectList.add(to.assignValues());
			} else {
				ah = (Address_History__c)to.assignValues();
			}
		}
        insert newSObjectList;
		Account household;
        for(SObject so : newSObjectList) {
            if(so instanceof Contact) {
                caregiver = (Contact)so;
				retUrl = '/' + caregiver.Id;
                referral.Caregiver__c = caregiver.Id;
				caregiver.Referral__c = referral.Id;
				ah.Caregiver__c = caregiver.Id;
				ah.Current_Address__c = true;
            } else if (so instanceof Case__c) {
                nfnCase = (Case__c)so;
                referral.Case__c = nfnCase.Id;
				nfnCase.Referral__c = referral.Id;
            } else if(so instanceof Account) {
				household = (Account)so;
			}
        }
		insert ah;
		List<Tag__c> newReferralReasonList = new List<Tag__c>();
		for(Tag__c t : [SELECT Tag_Name__c, Contact__c FROM Tag__c WHERE Referral__c = :referral.Id]) {
			Tag__c contactTag = new Tag__c(Tag_Name__c = t.Tag_Name__c, Contact__c = caregiver.Id);
			newReferralReasonList.add(contactTag);
		}
		insert newReferralReasonList;
		List<SObject> sObjectUpdateList = new List<SObject>();
		nfnCase.Caregiver__c = caregiver.Id;
		caregiver.AccountId = household.Id;
		sObjectUpdateList.add((SObject)caregiver);
		sObjectUpdateList.add((SObject)referral);
		sObjectUpdateList.add((SObject)nfnCase);
		update sObjectUpdateList;
        pageDisplayMap.put(1, false);
        pageDisplayMap.put(2, true);
        return null;
    }

    @RemoteAction
    global static PageReference goto(String returnTo) {
        return new PageReference('/' + returnTo);
    }

    global PageReference cancel() {
        return new PageReference(retUrl);
    }

	private void evaluateConversion() {
		Map<Integer, String> soNameMap = new Map<Integer, String>();
        String ocQuery = 'SELECT Required__c, Display_Order__c, Source_Object_API_Name__c, Target_Object_API_Name__c, Source_Field__c, Source_Field_API_Name__c, Target_Field_API_Name__c, Target_Value__c, Order__c FROM Object_Conversion__c WHERE Recordtype.Name = \'Intake Process\' ORDER BY Order__c';
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
			updatePageDisplayMap((String.isBlank(String.valueOf(referral.get('Caregiver__c'))) ? 1 : 2));
        }
	}

	private void updatePageDisplayMap(Integer page) { for(Integer p : pageDisplayMap.keySet()) pageDisplayMap.put(p, page == p); }
}
