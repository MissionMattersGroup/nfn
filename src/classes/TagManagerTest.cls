@isTest
public with sharing class TagManager_Test {

	public class TempTag {
		public Tag_Value__c tagValue { get; set; }
		public Boolean isChecked { get; set; }
		public Boolean isNew { get; set; }
		public TempTag(Tag_Value__c tv) {
			tagValue = tv;
			isChecked = false;
			isNew = true;
		}
	}

	public class TestFactory {

		public Contact testContact = (Contact)SmartFactory.createSObject('Contact');
		public Account testAccount = (Account)SmartFactory.createSObject('Account');
		public List<Tag_Value__c> tagValueList { get; set; }

		public TestFactory(User tu) {
			tagValueList = new List<Tag_Value__c>(populateTagValueList());
		}

		public Contact getTestContact() {
			return testContact;
		}

		public Contact getInsertedTestContact() {
			insert testContact;
			return testContact;
		}

		public Account getInsertedTestAccount() {
			insert testAccount;
			return testAccount;
		}

		private List<Tag_Value__c> populateTagValueList() {
			SmartFactory.fillAllFields = true;
			tagValueList = (List<Tag_Value__c>)SmartFactory.createSObjectList('Tag_Value__c', false, 10);
			SmartFactory.fillAllFields = false;
			insert tagValueList;
			return tagValueList;
		}
	}

	@isTest
	private static void testSaveWithContact() {
		Test.startTest();
		User testUser = [SELECT Id FROM User WHERE IsActive = true AND CompanyName != '' LIMIT 1][0];
		System.runAs(testUser) {
			TestFactory factory = new TestFactory(testUser);
			factory.getInsertedTestContact();
			PageReference testPr = Page.TagManager;
			Contact testContact = (Contact)SmartFactory.createSObject('Contact');
			insert testContact;
			testPr.getParameters().put('CF00N7A000000ZtYI_lkid', testContact.Id);
			Test.setCurrentPage(testPr);
			Tag_Value__c testTagValue = (Tag_Value__c)SmartFactory.createSObject('Tag_Value__c', true);
			insert testTagValue;
			Tag__c testTag = (Tag__c)SmartFactory.createSObject('Tag__c', true);
			testTag.Contact__c = testContact.Id;
			insert testTag;
			TagManagerController testController = new TagManagerController(new ApexPages.StandardController(testTag));
			TagManagerController.TempTag tt = new TagManagerController.TempTag(testTagValue);
			tt.isChecked = true;
			tt.isNew = true;
			testController.masterTagMap.put(testTagValue.Name, tt);
			testController.save();
			testController.updateTagMaps();
			tt = testController.masterTagMap.get(testTagValue.Name);
			tt.isChecked = false;
			tt.isNew = false;
			testController.masterTagMap.put(testTagValue.Name, tt);
			testController.updateTagMaps();
			testController.existingTagMap.put(testTag.Name, testTag);
			testController.save();
			testController.filterString = 'ab';
			testController.updateRenderedTagMap();
			testController.clearFilter();
			testController.filterString = 'abc';
			testController.updateRenderedTagMap();
			testController.clearFilter();
		}
		Test.stopTest();
	}

	@isTest
	private static void testSaveWithAccount() {
		Test.startTest();
		User testUser = [SELECT Id FROM User WHERE IsActive = true AND CompanyName != '' LIMIT 1][0];
		System.runAs(testUser) {
			TestFactory factory = new TestFactory(testUser);
			factory.getInsertedTestContact();
			PageReference testPr = Page.TagManager;
			Account testAccount = (Account)SmartFactory.createSObject('Account');
			insert testAccount;
			testPr.getParameters().put('CF00N7A000000ZtYI_lkid', testAccount.Id);
			Test.setCurrentPage(testPr);
			Tag_Value__c testTagValue = (Tag_Value__c)SmartFactory.createSObject('Tag_Value__c', true);
			insert testTagValue;
			Tag__c testTag = (Tag__c)SmartFactory.createSObject('Tag__c', true);
			testTag.Account__c = testAccount.Id;
			// testTag.Tag_Name__c = 'testSaveWithContact';
			insert testTag;
			TagManagerController testController = new TagManagerController(new ApexPages.StandardController(testTag));
			TagManagerController.TempTag tt = new TagManagerController.TempTag(testTagValue);
			tt.isChecked = true;
			tt.isNew = true;
			testController.masterTagMap.put(testTagValue.Name, tt);
			testController.save();
		}
		Test.stopTest();
	}
}
