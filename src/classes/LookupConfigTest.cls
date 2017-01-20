@isTest(SeeAllData=true)
public class LookupConfigTest {

	@isTest
	static void testSave() {
		Test.startTest();
		PageReference testPr = Page.LookupConfig;
		testPr.getParameters().put('returl', 'return_to_url');
		Test.setCurrentPage(testPr);
		LookupConfigController testController = new LookupConfigController(new ApexPages.standardController(new Address_Lookup_Configuration__c()));
		testController.addressLookup.Object_Name__c = 'Contact';
		testController.populateFieldLists();
		System.assertEquals('return_to_url', testController.cancel().getUrl());
		Test.stopTest();
	}
}