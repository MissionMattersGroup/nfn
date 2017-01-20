@isTest
private class SmartFactoryTest {
	static {
		SmartFactory.FillAllFields = false; // increase test coverage without creating custom objects
	}

	static testMethod void createSObjectList() {
		Test.startTest();
		List<Account> testAccountList = (List<Account>)SmartFactory.createSObjectList('Account', false, 5);
		insert testAccountList;
		for(Account testAccount : testAccountList) {
			System.assertNotEquals(null, testAccount.Id);
		}
		Test.stopTest();
	}

	static testMethod void createsSingleObjectWithSingleRequiredStringField() {
		Test.startTest();
		Account account = (Account)SmartFactory.createSObject('Account');
		insert account;
		System.assert(account.Id != null);
		System.assert(account.Name != null);
		Test.stopTest();
	}

	static testMethod void createsObjectWithCascadeSetsLookupField() {
		Test.startTest();
		Contact contact = (Contact)SmartFactory.createSObject('Contact', true);
		insert contact;
		System.assert(contact.Id != null);
		System.assert(contact.AccountId != null);
		Test.stopTest();
	}

	static testMethod void createsObjectWithoutCascadeDoesNotSetLookupField() {
		Test.startTest();
		Contact contact = (Contact)SmartFactory.createSObject('Contact', false);
		insert contact;
		System.assert(contact.AccountId == null);
		Test.stopTest();
	}

	static testMethod void createObjectWithUnsupportedTypeThrowsException() {
		Test.startTest();
		try {
			SmartFactory.createSObject('Unsupported');
			System.assert(false);
		} catch (UnsupportedObjectTypeException ex) {
			System.assert(true);
		}
		Test.stopTest();
	}
}