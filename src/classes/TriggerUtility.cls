public class TriggerUtility {

	public static Boolean hasValueChanged(SObject n, SObject o, String f) {
		Boolean hasValueChanged = false;
		Object nVal = n.get(f);
		Object oVal = o.get(f);
		if(nVal == null) {
			if(oVal != null) {
				hasValueChanged = true;
			}
		} else if(oVal == null) {
			if(nVal != null) {
				hasValueChanged = true;
			}
		} else if(nVal != oVal) {
			hasValueChanged = true;
		}
		return hasValueChanged;
	}

	public static Boolean hasValueChanged(SObject n, SObject o, List<String> fList) {
		Boolean hasValueChanged = false;
		for(String f : fList) {
			if(hasValueChanged(n, o, f)) {
				hasValueChanged = true;
				break;
			}
		}
		return hasValueChanged;
	}

	public static Set<Id> getChangedIdSet(List<SObject> nList, List<SObject> oList, String f) {
		Set<Id> recordChangedIdSet = new Set<Id>();
		if(nList.size() != oList.size()) {
			throw new ApplicationException('The numbers of records in the provided lists do not match.');
		}
		Map<Id, SObject> oMap = new Map<Id, SObject>();
		for(SObject n : nList) {
			if(!oMap.containsKey(n.Id)) {
				throw new ApplicationException('A record found in one list was not found in the other.');
			}
			SObject o = oMap.get(n.Id);
			if(hasValueChanged(n, o, f)) {
				recordChangedIdSet.add(n.Id);
			}
		}
		return recordChangedIdSet;
	}

	public class ApplicationException extends Exception {}
}
