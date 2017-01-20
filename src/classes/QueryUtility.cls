public class QueryUtility {

	public static String getSelectStarQuery(String sobjectName) {
		String query = 'SELECT ';
		List<String> fieldList = new List<String>();
		for(String field : Schema.getGlobalDescribe().get(sobjectName).getDescribe().fields.getMap().keySet()) {
			fieldList.add(field.toLowerCase());
		}
		query += String.join(fieldList, ', ') + ' FROM ' + sobjectName;
		return query;
	}

	public static List<SObject> selectStar(String sobjectName, Map<String, Set<String>> whereClauseMap) {
		String query = getSelectStarQuery(sobjectName);

		query += ' WHERE ' + String.join(getWhereClauseList(whereClauseMap), ' AND ');
		return Database.query(query);
	}

	public static List<SObject> selectStar(String sobjectName, Set<Id> idSet) {
		Set<String> vStringSet = new Set<String>();
		for(Id vId : idSet) vStringSet.add(String.valueOf(vId));
		return selectStar(sobjectName, new Map<String, Set<String>>{'Id'=>vStringSet});
	}

	public static List<String> getWhereClauseList(Map<String, Set<String>> whereClauseMap) {
		List<String> whereClauseList = new List<String>();
		for(String field : whereClauseMap.keySet()) {
			whereClauseList.add(' ' + field + ' IN (\'' + String.join(new List<String>(whereClauseMap.get(field)), '\', \'') + '\')');
		}
		return whereClauseList;
	}
}