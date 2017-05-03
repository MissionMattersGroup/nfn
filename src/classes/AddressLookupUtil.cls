public class AddressLookupUtil {

	static Map<String, Map<String, String>> fieldParamMap { get; set; }

	@future(CallOut=true)
	public static void updateFields(List<String> idList, String soType) {
		String rtName = soType.contains('__c') ? soType.replace('__c', '') : soType;
		populateFieldParamMap([SELECT Object_Name__c, County_Field__c, Address_Field__c, Street_Address_Field__c, City_Field__c, State_Field__c, Postal_Code_Field__c FROM Address_Lookup_Configuration__c WHERE RecordTypeId IN (SELECT Id FROM RecordType WHERE SObjectType = 'Address_Lookup_Configuration__c' AND Name = :rtName)]);
		List<String> queryFieldList = new List<String>();
		for(Map<String, String> m : fieldParamMap.values()) {
			queryFieldList.addAll(m.values());
		}
		String qry = 'SELECT Id, ' + String.join(queryFieldList, ', ') + ' FROM ' + soType + ' WHERE Id IN (\'' + String.join(idList, '\', \'') + '\')';
		List<SObject> soList = Database.query(qry);
		for(SObject so : soList) {
			for(String countyField : fieldParamMap.keySet()) {
				Map<String, String> paramMap = fieldParamMap.get(countyField);
				for(String paramKey : paramMap.keySet()) {
					paramMap.put(paramKey, String.valueOf(so.get(paramMap.get(paramKey))));
				}
				so.put(countyField, AddressLookupService.getCounty(fieldParamMap.get(countyField)));
			}
		}
		update soList;
	}

	static void populateFieldParamMap(List<Address_Lookup_Configuration__c> alcList) {
		fieldParamMap = new Map<String, Map<String, String>>();
		List<String> alcFieldList = new List<String>{'City_Field__c', 'Postal_Code_Field__c', 'State_Field__c', 'Street_Address_Field__c'};
		List<String> urlParamList = new List<String>{'city', 'zip', 'state', 'street'};
		for(Address_Lookup_Configuration__c alc : alcList) {
			if(alc.Object_Name__c.equalsIgnoreCase('Address_History__c')) continue;
			Map<String, String> paramMap = new Map<String, String>();
			for(Integer i=0; i<alcFieldList.size(); i++) {
				paramMap.put(urlParamList[i], String.valueOf(alc.get(alcFieldList[i])));
			}
			fieldParamMap.put(alc.County_Field__c, paramMap);
		}
	}
}