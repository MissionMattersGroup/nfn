public class LookupConfigController {

	public String objectName { get; set; }
	public String streetField { get; set; }
	public String cityField { get; set; }
	public String stateField { get; set; }
	public String zipField { get; set; }
	public String countyField { get; set; }
	public Address_Lookup_Configuration__c addressLookup { get; set; }
	public List<SelectOption> objectList { get; set; }
	Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
	public List<SelectOption> countyFieldList { get; set; }
	public List<SelectOption> streetfieldList { get; set; }
	public List<SelectOption> postalFieldList { get; set; }
	public List<SelectOption> cityFieldList { get; set; }
	public List<SelectOption> stateFieldList { get; set; }
	public String orgName { get; set; }
	public Set<String> configurableObjectNameSet { get; set; }

	public LookupConfigController(ApexPages.StandardController std) {
		configurableObjectNameSet = new Set<String>(Address_Configurable_Objects__c.getAll().keySet());
		populateObjectList();
		objectName = '';
		orgName = [SELECT Name FROM Organization LIMIT 1].Name;
		addressLookup = new Address_Lookup_Configuration__c();
	}

	public PageReference save() {
		try {
			insert addressLookup;
			return new PageReference('/' + addressLookup.Id);
		} catch(DmlException e) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
		}
		return null;
	}

	public PageReference cancel() {
		return new PageReference(ApexPages.currentPage().getParameters().get('retUrl'));
	}

	public void populateObjectList () {
		objectList = new List<SelectOption>{new SelectOption('', '')};
		List<String> objectNameList = new List<String>(gd.keySet());
		objectNameList.sort();
		for(String objectApiName : objectNameList) {
			if(configurableObjectNameSet.contains(gd.get(objectApiName).getDescribe().getLabel())) {
				SelectOption so = new SelectOption(objectApiName, gd.get(objectApiName).getDescribe().getLabel());
				objectList.add(so);
			}
		}
	}

	public PageReference populateFieldLists() {
		if(String.isNotBlank(addressLookup.Object_Name__c)) {
			Map<String, Schema.SObjectField> fieldMap = gd.get(addressLookup.Object_Name__c).getDescribe().fields.getMap();
			stateFieldList = createFieldList('State', fieldMap);
			cityFieldList = createFieldList('City', fieldMap);
			postalFieldList = createFieldList('Postal', fieldMap);
			postalFieldList.addAll(createFieldList('Zip', fieldMap));
			streetfieldList = createFieldList('Street', fieldMap);
			countyFieldList = createFieldList('County', fieldMap);
		}
		return null;
	}

	public List<SelectOption> createFieldList(String key, Map<String, Schema.SObjectField> fieldMap) {
		List<SelectOption> fieldList = new List<SelectOption>{new SelectOption('', '')};
		Map<String, String> probableFieldMap = new Map<String, String>();
		Map<String, String> unlikelyFieldMap = new Map<String, String>();
		for(String fieldApiName : fieldMap.keySet()) {
			if(fieldApiName.containsIgnoreCase(key) || fieldMap.get(fieldApiName).getDescribe().getLabel().containsIgnoreCase(key)) {
				probableFieldMap.put(fieldMap.get(fieldApiName).getDescribe().getLabel(), fieldApiName);
			} else {
				unlikelyFieldMap.put(fieldMap.get(fieldApiName).getDescribe().getLabel(), fieldApiName);
			}
		}
		List<String> sortedList = new List<String>(probableFieldMap.keySet());
		sortedList.sort();
		for(String s : sortedList) {
			fieldList.add(new SelectOption(probableFieldMap.get(s), s));
		}
		sortedList = new List<String>(unlikelyFieldMap.keySet());
		sortedList.sort();
		for(String s : sortedList) {
			fieldList.add(new SelectOption(unlikelyFieldMap.get(s), s));
		}
		return fieldList;
	}

	public PageReference rerender() { return null; }
}