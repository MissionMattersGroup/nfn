public class ObjectConversionController {

	public Object_Conversion__c oc { get; set; }
	public List<SelectOption> rtSelectOptionList { get; set; }
	public List<SelectOption> sourceObjectList { get; set; }
	public List<SelectOption> targetObjectList { get; set; }
	public List<SelectOption> sourceFieldList { get; set; }
	public List<SelectOption> targetFieldList { get; set; }
	public Map<String, String> requiredFieldMap  { get; set; }
	public Map<String, String> defaultTargetValueMap { get; set; }
	public Map<String, Boolean> renderProvidedValueByFieldMap { get; set; }
	public Map<String, Schema.SObjectType> sObjectByLabelMap { get; set; }
	public Map<String, Map<String, SObjectField>> fieldMapByObjectNameMap { get; set; }
	public Id ocRecordTypeId { get; set; }

	public ObjectConversionController(ApexPages.StandardController std) {
		populateSObjectByLabelMap();
		sourceFieldList = new List<SelectOption>{new SelectOption('0', '--Select--')};
		sourceFieldList.add(new SelectOption('Set Default Value', 'Set Default Value'));
		populateObjectLists();
		List<RecordType> rtList = [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Object_Conversion__c' AND IsActive = true ORDER BY Name];
		rtSelectOptionList = new List<SelectOption>();
		rtSelectOptionList.add(new SelectOption('0', '--Select--'));
		for(RecordType rt : rtList) {
			rtSelectOptionList.add(new SelectOption(rt.Id, rt.Name));
		}
		if(rtList.size() == 1) {
			rtSelectOptionList = new List<SelectOption>{new SelectOption(rtList[0].Id, rtList[0].Name)};
			ocRecordTypeId = rtList[0].Id;
		}
		oc = new Object_Conversion__c();
		oc.RecordTypeId = String.isNotBlank(ocRecordTypeId) ? ocRecordTypeId : oc.RecordTypeId;
		requiredFieldMap = defaultTargetValueMap = new Map<String, String>();
	}

	private void populateObjectLists() {
		sourceObjectList = new List<SelectOption>{new SelectOption('0', '--Select--'), new SelectOption('N/A', 'Provide Default Value')};
		targetObjectList = new List<SelectOption>{new SelectOption('0', '--Select--')};
		Map<String, Schema.SObjectType> objectMap = Schema.getGlobalDescribe();
		Map<String, String> objectNameByLabelMap = new Map<String, String>();
		for(String f : objectMap.keySet()) {
			objectNameByLabelMap.put(objectMap.get(f).getDescribe().getLabel(), f);
		}
		List<String> sortedLabelList = new List<String>(objectNameByLabelMap.keySet());
		sortedLabelList.sort();
		for(String label : sortedLabelList) {
			sourceObjectList.add(new SelectOption(label, label));
			targetObjectList.add(new SelectOption(label, label));
		}
	}

	public void populateTargetFieldList() {
		fieldMapByObjectNameMap = new Map<String, Map<String, SObjectField>>();
		if(String.isNotBlank(oc.Target_Object__c) && oc.Target_Object__c != '0') {
			fieldMapByObjectNameMap.put(oc.Target_Object__c, sObjectByLabelMap.get(oc.Target_Object__c).getDescribe().fields.getMap());
			targetFieldList = new List<SelectOption>{new SelectOption('0', '--Select--')};
			targetFieldList.addAll(sortFieldList(fieldMapByObjectNameMap.get(oc.Target_Object__c)));
			renderProvidedValueByFieldMap = new Map<String, Boolean>();
			requiredFieldMap = new Map<String, String>();
			for(String fieldApiName : fieldMapByObjectNameMap.get(oc.Target_Object__c).keySet()) {
				defaultTargetValueMap.put(fieldApiName, '0');
				renderProvidedValueByFieldMap.put(fieldApiName, false);
				Schema.DescribeFieldResult dfr = fieldMapByObjectNameMap.get(oc.Target_Object__c).get(fieldApiName).getDescribe();
				if(!dfr.isDefaultedOnCreate()) requiredFieldMap.put(fieldApiName, dfr.getLabel());
			}
		}
	}

	public void populateSourceFieldList() {
		sourceFieldList = new List<SelectOption>{new SelectOption('0', '--Select--')};
		if(String.isNotBlank(oc.Source_Object__c) && oc.Source_Object__c != '0' && oc.Source_Object__c != 'N/A') {
			sourceFieldList.addAll(sortFieldList(sObjectByLabelMap.get(oc.Source_Object__c).getDescribe().fields.getMap()));
		} else if(oc.Source_Object__c == 'N/A') {
			if(oc.Target_Field__c == 'Record Type Name') {
				for(RecordType rt : [SELECT Id, Name FROM RecordType WHERE IsActive = TRUE AND SObjectType = :sObjectByLabelMap.get(oc.Target_Object__c).getDescribe().getName() ORDER BY Name]) {
					sourceFieldList.add(new SelectOption(rt.Name, rt.Name));
				}
			}
			oc.Source_Field__c = oc.Source_Object__c;
		}
	}

	public void populateAPIFields() {
		oc.Target_Object_API_Name__c = sObjectByLabelMap.get(oc.Target_Object__c).getDescribe().getName();
		for(Schema.SObjectField field : sObjectByLabelMap.get(oc.Target_Object__c).getDescribe().fields.getMap().values()) {
			if(field.getDescribe().getLabel() == oc.Target_Field__c) {
				oc.Target_Field_API_Name__c = field.getDescribe().getName();
				break;
			}
		}
		if(String.isNotBlank(oc.Source_Object__c) && oc.Source_Object__c != 'N/A') {
			oc.Source_Object_API_Name__c = sObjectByLabelMap.get(oc.Source_Object__c).getDescribe().getName();
			for(Schema.SObjectField field : sObjectByLabelMap.get(oc.Source_Object__c).getDescribe().fields.getMap().values()) {
				if(field.getDescribe().getLabel() == oc.Source_Field__c) {
					oc.Source_Field_API_Name__c = field.getDescribe().getName();
					break;
				}
			}
		}
	}

	public PageReference cancel() {
		return new PageReference(EncodingUtil.urlDecode(ApexPages.CurrentPage().getParameters().get('retUrl'), 'UTF-8'));
	}

	public PageReference saveAndNew() {
		populateAPIFields();
		insert oc;
		oc = new Object_Conversion__c();
		return new PageReference('/apex/ObjectConversion?retUrl=' + ApexPages.CurrentPage().getParameters().get('retUrl'));
	}

	public PageReference save() {
		populateAPIFields();
		insert oc;
		return new PageReference(ApexPages.CurrentPage().getParameters().get('retUrl'));
	}

	private List<SelectOption> sortFieldList(Map<String, SObjectField> fieldMap) {
		List<SelectOption> sortedList = new List<SelectOption>();
		Map<String, String> fieldNameByLabelMap = new Map<String, String>();
		for(String fieldApiName : fieldMap.keySet()) {
			fieldNameByLabelMap.put(fieldMap.get(fieldApiName).getDescribe().getLabel(), fieldApiName);
		}
		List<String> sortedLabelList = new List<String>(fieldNameByLabelMap.keySet());
		sortedLabelList.sort();
		for(String fieldLabel : sortedLabelList) {
			fieldLabel = fieldLabel.equalsIgnoreCase('Record Type ID') ? 'Record Type Name' : fieldLabel;
			sortedList.add(new SelectOption(fieldLabel, fieldLabel));
		}
		return sortedList;
	}

	private void populateSObjectByLabelMap() {
		sObjectByLabelMap = new Map<String, Schema.SObjectType>();
		for(Schema.SObjectType sot : Schema.getGlobalDescribe().values()) {
			sObjectByLabelMap.put(sot.getDescribe().getLabel(), sot);
		}
	}

	public void toggle() {
		if(String.isNotBlank(oc.Target_Field__c) && String.isBlank(oc.Target_Field_API_Name__c)) {
			for(Schema.SObjectField dfr : sObjectByLabelMap.get(oc.Target_Object__c).getDescribe().fields.getMap().values()) {
				if(dfr.getDescribe().getLabel() == oc.Target_Field__c) {
					oc.Target_Field_API_Name__c = dfr.getDescribe().getName();
					break;
				}
			}
		}
		if(String.isNotBlank(oc.Source_Field__c) && String.isBlank(oc.Source_Field_API_Name__c) && oc.Source_Field__c != 'N/A') {
			for(Schema.SObjectField dfr : sObjectByLabelMap.get(oc.Source_Object__c).getDescribe().fields.getMap().values()) {
				if(dfr.getDescribe().getLabel() == oc.Source_Field__c) {
					oc.Source_Field_API_Name__c = dfr.getDescribe().getName();
					break;
				}
			}
		}
	}
}