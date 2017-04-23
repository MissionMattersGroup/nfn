public class TimeEntryTriggerHandler {

	public void onAfterInsert(List<Time_Entry__c> newList) {
		Set<Id> timeSheetIdSet = new Set<Id>();
		for(Time_Entry__c t : newList) {
			timeSheetIdSet.add(t.Time_Sheet__c);
		}
		updateRelatedTimeEntries(timeSheetIdSet);
	}

	public void onAfterUpdate(List<Time_Entry__c> newList, Map<Id, Time_Entry__c> oldMap) {
		Set<Id> timeSheetIdSet = new Set<Id>();
		for(Time_Entry__c te : newList) {
			Time_Entry__c oldTe = oldMap.get(te.Id);
			if(te.Time_Entry_Start_Date_Time__c != oldTe.Time_Entry_Start_Date_Time__c ||
			   	   te.Time_Entry_End_Date_Time__c != oldTe.Time_Entry_End_Date_Time__c) {
			   timeSheetIdSet.add(te.Time_Sheet__c);
		   }
		}
		if(!timeSheetIdSet.isEmpty()) {
			updateRelatedTimeEntries(timeSheetIdSet);
		}
	}

	public void onAfterDelete(List<Time_Entry__c> oldList) {
		Set<Id> timeSheetIdSet = new Set<Id>();
		for(Time_Entry__c te : oldList) {
			if(String.isNotBlank(te.Time_Sheet__c)) {
				timeSheetIdSet.add(te.Time_Sheet__c);
			}
		}
		if(!timeSheetIdSet.isEmpty()) {
			updateRelatedTimeEntries(timeSheetIdSet);
		}
	}

	private void updateRelatedTimeEntries(Set<Id> timeSheetIdSet) {
		Map<Id, TimeSheetStructure> tssMapByTimeSheetIdMap = new Map<Id, TimeSheetStructure>();
		List<Time_Sheet__c> timeSheetList = [SELECT Id, Total_Hours__c,
													Week_1_Start_Date__c, Week_1_End_Date__c, Pay_Period_Week_1_Total__c,
													Week_2_Start_Date__c, Week_2_End_Date__c, Pay_Period_Week_2_Total__c,
													Week_3_Start_Date__c, Week_3_End_Date__c, Pay_Period_Week_3_Total__c
		   									   FROM Time_Sheet__c
		  							   		  WHERE Id IN :timeSheetIdSet];
		List<Time_Entry__c> timeEntryList = [SELECT Id, Time_Entry_End_Date_Time__c,
												   	Time_Entry_Start_Date_Time__c, Time_Sheet__c,
													OwnerId
										   	   FROM Time_Entry__c
											  WHERE Time_Sheet__c IN :timeSheetIdSet
										   ORDER BY Time_Sheet__c, Time_Entry_Start_Date_Time__c];
		Long startTime = 0;
		Long endTime = 0;
		for(Time_Sheet__c ts : timeSheetList) {
			ts.Pay_Period_Week_1_Total__c = 0;
			ts.Pay_Period_Week_2_Total__c = 0;
			ts.Pay_Period_Week_3_Total__c = 0;
			tssMapByTimeSheetIdMap.put(ts.Id, new TimeSheetStructure(ts));
		}
		for(Time_Entry__c te : timeEntryList) {
			TimeSheetStructure tss = tssMapByTimeSheetIdMap.get(te.Time_Sheet__c);
			// get the field for the pay week using the time entry's start date/time
			String weekField = tss.getWeekFieldByEntryDateTime(te.Time_Entry_Start_Date_Time__c);
			Long teStartTime = te.Time_Entry_Start_Date_Time__c.getTime();
			Long teEndTime = te.Time_Entry_End_Date_Time__c.getTime();
			Double currentDuration = Double.valueOf(tss.ts.get(weekField));
			if(teStartTime >= startTime && teStartTime >= endTime) { // new discreet block of time found
				startTime = teStartTime;
				endTime = teEndTime;
				Long blockDuration = endTime - startTime;
				currentDuration += (blockDuration / 60000);
			} else if(teStartTime < endTime && teEndTime > endTime) { // overlap with spillover
				Long spillOverDuration = teEndTime - endTime;
				endTime = teEndTime;
				currentDuration += (spillOverDuration / 60000);
			}
			tss.ts.put(weekField, Integer.valueOf(currentDuration));
		}
		List<Time_Sheet__c> updatedTimeSheetList = new List<Time_Sheet__c>();
		for(TimeSheetStructure tss : tssMapByTimeSheetIdMap.values()) {
			updatedTimeSheetList.add(tss.ts);
		}
		update updatedTimeSheetList;
	}

	class TimeSheetStructure {
		public Time_Sheet__c ts { get; set; }

		TimeSheetStructure(Time_Sheet__c ts) {
			this.ts = ts;
		}

		public String getWeekFieldByEntryDateTime(Datetime dt) {
			if(dt >= ts.Week_1_Start_Date__c && dt <= ts.Week_1_End_Date__c) {
				return 'Pay_Period_Week_1_Total__c';
			} else if(dt >= ts.Week_2_Start_Date__c && dt <= ts.Week_2_End_Date__c) {
				return 'Pay_Period_Week_2_Total__c';
			} else if(dt >= ts.Week_3_Start_Date__c && dt <= ts.Week_3_End_Date__c) {
				return 'Pay_Period_Week_3_Total__c';
			}
			return null;
		}
	}
}
