global class RelatrController {

	public String primaryLookup { get; set; }
	public String secondaryLookup { get; set; }
	public List<SelectOption> primaryLookupList { get; set; }
	public List<SelectOption> secondaryLookupList { get; set; }
	public Relationship__c r { get; set; }
	public List<SelectOption> typeList { get; set; }
	public List<SelectOption> statusList { get; set; }
	public String typeField { get; set; }
	public Id primaryId { get; set; }
	public Id secondaryId { get; set; }
	public String primaryGender { get; set; }
	public Boolean readonly { get; set; }
	public Boolean editable { get; set; }
	public SObject primarySo { get; set; }
	public SObject secondarySo { get; set; }

	public RelatrController(ApexPages.StandardController std) {
		populateLookupLists();
		editable = false;
		if(String.isNotBlank(std.getId())) {
			readonly = true;
			r = (Relationship__c)QueryUtility.selectStar('Relationship__c', new Set<Id>{std.getId()})[0];
			for(Schema.SObjectField field : Schema.getGlobalDescribe().get('Relationship__c').getDescribe().fields.getMap().values()) {
				String fieldLabel = field.getDescribe().getLabel();
				String fieldName = field.getDescribe().getName();
				if(fieldLabel.endsWith(' Related')) {
					String relatedFieldName = fieldName;
					fieldName = relatedFieldName.replace('_Related__c', '__c');
					if(String.isNotBlank(String.valueOf(r.get(fieldName)))) {
						primaryId = (Id)r.get(fieldName);
						primaryLookup = fieldName;
					}
					if(String.isNotBlank(String.valueOf(r.get(relatedFieldName)))) {
						secondaryId = (Id)r.get(relatedFieldName);
						secondaryLookup = relatedFieldName;
					}
					if(String.isNotBlank(primaryLookup) & String.isNotBlank(secondaryLookup)) break;
				}
			}
			setSecondarySo();
			populateTypeList();
		} else {
			readonly = false;
			Map<String, String> paramMap = ApexPages.currentPage().getParameters();
			for(String k : paramMap.keySet()) {
				if(k.endsWith('_lkid')) {
					r = buildRelationshipFromUrl(paramMap.get(k));
					populateTypeList();
					break;
				}
			}
			if(String.isBlank(primaryLookup)) {
				r = new Relationship__c();
			}
		}
	}

	private Relationship__c buildRelationshipFromUrl(Id pId) {
		primaryId = pId;
		String objectName = pId.getSObjectType().getDescribe().getName();
		primaryLookup = objectName.endsWith('__c') ? objectName : objectName + '__c';
		r = new Relationship__c();
		r.put(primaryLookup, pId);
		return r;
	}

	private void populateLookupLists() {
		primaryLookupList = new List<SelectOption>{new SelectOption('', '--None--')};
		secondaryLookupList= new List<SelectOption>{new SelectOption('', '--None--')};
		for(Schema.SObjectField field : Schema.getGlobalDescribe().get('Relationship__c').getDescribe().fields.getMap().values()) {
			if(field.getDescribe().getLabel().endsWith(' Related')) {
				secondaryLookupList.add(new SelectOption(field.getDescribe().getName(), field.getDescribe().getLabel().replace(' Related', '')));
				primaryLookupList.add(new SelectOption(field.getDescribe().getName().replace('_Related__c', '__c'), field.getDescribe().getLabel().replace(' Related', '')));
			}
		}
	}

	public PageReference populateTypeList() {
		typeList = new List<SelectOption>();
		primaryId = String.isBlank(String.valueOf(primaryId)) ? (Id)String.valueOf(r.get(primaryLookup)) : primaryId;
		Boolean objHasGenderField = false;
		String q = 'SELECT Id, Name';
		if(primaryId.getSObjectType().getDescribe().fields.getMap().containsKey('Gender__c')) {
			q += ', Gender__c';
			objHasGenderField = true;
		}
		q += ' FROM ' + primaryId.getSObjectType().getDescribe().getName() + ' WHERE Id = \'' + primaryId + '\'';
		primarySo = Database.query(q);
		typeField = (objHasGenderField && String.isNotBlank(String.valueOf(primarySo.get('Gender__c')))) ? String.valueOf(primarySo.get('Gender__c')) + '_Reciprocal__c' : 'Neutral_Reciprocal__c';
		for(Schema.PicklistEntry ple : Schema.getGlobalDescribe().get('Relationship_Settings__c').getDescribe().fields.getMap().get(typeField).getDescribe().getPicklistValues()) {
			typeList.add(new SelectOption(ple.getValue(), ple.getValue()));
		}
		return null;
	}

	public PageReference rerender() { return null; }

	public PageReference setSecondarySo() {
		secondaryId = (Id)r.get(secondaryLookup);
		String q = 'SELECT Id, Name FROM ' + secondaryId.getSObjectType().getDescribe().getName() + ' WHERE Id = \'' + secondaryId + '\'';
		secondarySo = Database.query(q);
		return null;
	}

	public PageReference save() {
		String primaryName = String.valueOf(primarySo.get('Name'));
		String secondaryName = String.valueOf(secondarySo.get('Name'));
		r.Explanation__c = String.valueOf(primarySo.get('Name')) + ' is the ' + r.Type__c + ' of ' + String.valueOf(secondarySo.get('Name'));
		if(readonly) {
			update r;
		} else {
			insert r;
		}
		return new PageReference('/' + r.Id);
	}

	public PageReference cancel() {
		return new PageReference((ApexPages.currentPage().getParameters().containsKey('returl') ? ApexPages.currentPage().getParameters().get('returl') : '/'));
	}

	public PageReference edit() {
		editable = true;
		return null;
	}
}