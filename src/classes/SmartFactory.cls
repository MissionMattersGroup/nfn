/*
   Copyright 2011 Mavens Consulting, Inc.

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/

public with sharing class SmartFactory {
	public static Boolean fillAllFields = false;
	public static Profile userProfile = [Select Id from Profile where Name = 'System Administrator'];
	private static final Map<String, Map<String, Schema.SObjectField>> fieldMapCache = new Map<String, Map<String, Schema.SObjectField>>();
	private static final Map<String, Schema.SObjectType> globalDescribe = Schema.getglobalDescribe();
	public static String defaultCountry = 'United States';
	public static String defaultCountryCode = 'US';
	public static String defaultState = 'Pennsylvania';
	public static String defaultStateCode = 'PA';
	private static final Map<String, String> defaultPicklistValue = new Map<String, String>();
	public static Map<String, Set<String>> excludedFields = new Map<String, Set<String>>{
		'All' => new Set<String>{'OwnerId', 'LastModifiedById', 'CreatedById', 'LastModifiedDate', 'CreatedDate'},
		'Account' => new Set<String>{'FirstName', 'LastName'},
		'User' => new Set<String>{'IsActive','DelegatedApproverId','CallCenterId','ContactId','DelegatedApproverId','ManagerId','UserRoleId','FederationIdentifier', 'causeview__Volunteer_Opportunity__c'}
	};
	public static Map<String, Set<String>> includedFields = new Map<String, Set<String>>();

	public static SObject createSObject(String objectType) {
		return createSObject(objectType, false);
	}

	public static List<SObject> createSObjectList(String objectType, Boolean cascade, Integer numberOfObjects) {
		List<SObject> sos = new List<SObject>();
		for(Integer i=0; i<numberOfObjects; i++)
			sos.add(createSObject(objectType, cascade, i));
		return sos;
	}

	public static SObject createSObject(String objectType, Boolean cascade, Integer counter) {
		Schema.sObjectType token = globalDescribe.get(objectType);
		if (token == null) {
			throw new UnsupportedObjectTypeException('Unsupported ObjectType ' + objectType);
		}
		SObject obj = token.newSObject();
		for (Schema.SObjectField field : fieldMapFor(objectType).values()) {
			SetFieldValue(obj, field, cascade, counter);
		}
		return obj;
	}

	public static SObject createSObject(String objectType, Boolean cascade) {
		return createSObject(objectType, cascade, 1);
	}

	public static Map<String, Schema.SObjectField> fieldMapFor(String objectType) {
		Map<String, Schema.SObjectField> fieldMap = null;
		String normalizedObjectType = objectType.toLowerCase();
		if (fieldMapCache.containsKey(normalizedObjectType)) {
			fieldMap = fieldMapCache.get(normalizedObjectType);
		} else {
			fieldMap = globalDescribe.get(objectType).getDescribe().fields.getMap();
			fieldMapCache.put(normalizedObjectType, fieldMap);
		}
		return fieldMap;
	}

	static String getdefaultPicklistValue(SObject obj, Schema.DescribeFieldResult fieldDescribe) {
		String key = obj.getSObjectType() + '.' + fieldDescribe.getName();
		if (!defaultPicklistValue.containsKey(key)) {
			List<Schema.PicklistEntry> entries = fieldDescribe.getPicklistValues();
			String value = entries.size() > 0 ? entries[0].getValue() : null;
			defaultPicklistValue.put(key, value);
		}
		return defaultPicklistValue.get(key);
	}

	static Boolean isExcludedField(Schema.DescribeFieldResult fieldDescribe) {
		return excludedFields.get('All').contains(fieldDescribe.getName());
	}

	static Boolean isExcludedField(SObject obj, Schema.DescribeFieldResult fieldDescribe) {
		Set<String> fields = excludedFields.get(obj.getSObjectType().getDescribe().getName());
		return fields == null ? false : fields.contains(fieldDescribe.getName());
	}

	static Boolean isIncludedField(SObject obj, Schema.DescribeFieldResult fieldDescribe) {
		Set<String> fields = includedFields.get(obj.getSObjectType().getDescribe().getName());
		return fields == null ? false : fields.contains(fieldDescribe.getName());
	}

	static Boolean isPersonAccountField(Schema.DescribeFieldResult fieldDescribe) {
        Boolean isPersonAccountEnabled = fieldMapFor('Account').get('IsPersonAccount') != null;
        Set<String> skipPersonAccountFields = new Set<String>{'Salutation'};
        Boolean customPerson = fieldDescribe.isCustom() && fieldDescribe.getName().endsWith('pc');
        Boolean standardPerson = !fieldDescribe.isCustom() && fieldDescribe.getName().startsWith('Person');
        return customPerson || standardPerson || (isPersonAccountEnabled && skipPersonAccountFields.contains(fieldDescribe.getName()));
	}

	static void SetFieldValue(SObject obj, Schema.SObjectField field, Boolean cascade, Integer counter) {
		Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
		if (fieldDescribe.isCreateable() && (isIncludedField(obj, fieldDescribe) || (((!fieldDescribe.isNillable() || fillAllFields) || (fieldDescribe.getType() == Schema.DisplayType.Reference && cascade)) && !isExcludedField(fieldDescribe) && !isExcludedField(obj, fieldDescribe) && !isPersonAccountField(fieldDescribe)))) {
			if (fieldDescribe.getName().endsWith('Country')) {
				obj.put(field, defaultCountry);
			} else if (fieldDescribe.getName().endsWith('State')) {
				obj.put(field, defaultState);
			} else if (fieldDescribe.getName().endsWith('CountryCode')) {
				obj.put(field, defaultCountryCode);
			} else if (fieldDescribe.getName().endsWith('StateCode')) {
				obj.put(field, defaultStateCode);
			} else if (fieldDescribe.getType() == Schema.DisplayType.base64) {
				obj.put(field, blob.valueOf(counter.format()));
			} else if (fieldDescribe.getType() == Schema.DisplayType.Boolean) {
				obj.put(field, false);
			} else if (fieldDescribe.getType() == Schema.DisplayType.Combobox) {
				obj.put(field, counter.format());
			} else if (fieldDescribe.getType() == Schema.DisplayType.Currency) {
				obj.put(field, counter);
			} else if (fieldDescribe.getType() == Schema.DisplayType.Date) {
				obj.put(field, Date.today());
			} else if (fieldDescribe.getType() == Schema.DisplayType.DateTime) {
				obj.put(field, DateTime.now());
			} else if (fieldDescribe.getType() == Schema.DisplayType.Double) {
				obj.put(field, counter);
			} else if (fieldDescribe.getType() == Schema.DisplayType.Email) {
				obj.put(field, 'testSF' + counter.format() + '@test.com');
			} else if (fieldDescribe.getType() == Schema.DisplayType.EncryptedString) {
				obj.put(field, 's');
			} else if (fieldDescribe.getType() == Schema.DisplayType.Id) {
			} else if (fieldDescribe.getType() == Schema.DisplayType.Integer) {
				obj.put(field, counter);
			} else if (fieldDescribe.getType() == Schema.DisplayType.MultiPicklist) {
				obj.put(field, getdefaultPicklistValue(obj, fieldDescribe));
			} else if (fieldDescribe.getType() == Schema.DisplayType.Percent) {
				obj.put(field, counter);
			} else if (fieldDescribe.getType() == Schema.DisplayType.Phone) {
				obj.put(field, '123-456-7890');
			} else if (fieldDescribe.getType() == Schema.DisplayType.Picklist) {
				obj.put(field, getdefaultPicklistValue(obj, fieldDescribe));
			} else if (fieldDescribe.getName() == 'CommunityNickname' && fieldDescribe.getType() == Schema.DisplayType.String) {
				obj.put(field, 'test'+ string.valueof(math.roundtolong(math.random()*1000000)) );
			} else if (fieldDescribe.getName() == 'UserName' && fieldDescribe.getType() == Schema.DisplayType.String) {
				obj.put(field, 'test'+ string.valueof(Userinfo.getOrganizationId())+ string.valueof(math.roundtolong(math.random()*1000000))+ string.valueof(Datetime.now()).replace('-','').replace(':','').replace(' ','')+'@test.com'); // was a@a.com
			} else if (fieldDescribe.getType() == Schema.DisplayType.String) {
				obj.put(field, 'SmFy' + getRandomNumberString() + counter.format());
			} else if (fieldDescribe.getType() == Schema.DisplayType.Reference) {
				String referenceObjectType = fieldDescribe.getReferenceTo()[0].getDescribe().getName();
				if (referenceObjectType == 'RecordType') {
					SetRecordType(obj);
                } else if (referenceObjectType == 'Profile') {
					obj.put(field,userProfile.Id);
				} else if (cascade && referenceObjectType != obj.getSObjectType().getDescribe().getName() && referenceObjectType !='BusinessHours') {
                    SObject reference = createSObject(referenceObjectType);
					try {
						insert reference;
					} catch(DmlException e) {
						System.debug('Exception caught: ' + e.getMessage());
					}
					obj.put(field, reference.Id);
				}
			} else if (fieldDescribe.getType() == Schema.DisplayType.TextArea) {
				obj.put(field, counter.format());
			} else if (fieldDescribe.getType() == Schema.DisplayType.Time) {
				obj.put(field, Time.newInstance(0, 0, 0, 0));
			} else if (fieldDescribe.getType() == Schema.DisplayType.URL) {
				obj.put(field, 'http://test' + counter + '.com');
			} else {
				System.debug('Unhandled field type ' + fieldDescribe.getType());
			}
		}
	}

	private static String getRandomNumberString() {
		return String.valueOf(Math.round(Math.random()*1000));
    }

	static void SetRecordType(SObject obj) {
		List<Schema.RecordTypeInfo> recordTypes = obj.getSObjectType().getDescribe().getRecordTypeInfos();
		if (recordTypes.size() > 1) { // all objects have default Master type
			for (Schema.RecordTypeInfo recordType : recordTypes) {
				if (recordType.isAvailable() && recordType.isDefaultRecordTypeMapping()) {
					obj.put('RecordTypeId', recordType.getRecordTypeId());
				}
			}
		}
	}
}