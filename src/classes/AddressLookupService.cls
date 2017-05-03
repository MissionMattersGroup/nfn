public class AddressLookupService {

	static String countyLookupUrl = 'http://data.fcc.gov/api/block/find?format=json&showall=true&latitude={!latitude}&longitude={!longitude}';
	public static Map<String, String> coordinatesMap {get; set;}
	public static Map<String, String> paramMap { get; set; }

	public static String getCounty(Map<String, String> pMap) {
		paramMap = pMap;
		Map<String, String> coordinateMap = getCoordinatesMap();
		return getCountyByCoordinates(coordinateMap.get('latitude'), coordinateMap.get('longitude'));
	}

	public static Map<String, String> getCoordinatesMap() {
		coordinatesMap = new Map<String, String>();
		HttpRequest req = new HttpRequest();
		req.setMethod('GET');
		req.setEndpoint(getCoordinateLookupUrl());
		Http http = new Http();
		HttpResponse res;
		try {
			res = http.send(req);
			Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
			Map<String, Object> r = (Map<String, Object>)m.get('result');
			List<Object> addressMatchesList = (List<Object>)r.get('addressMatches');
			Map<String, Object> a = (Map<String, Object>)addressMatchesList[0];
			Map<String, Object> c = (Map<String, Object>)a.get('coordinates');
			coordinatesMap.put('longitude', String.valueOf(c.get('x')));
			coordinatesMap.put('latitude', String.valueOf(c.get('y')));
		} catch(Exception e) {
			System.debug('\n\n\n\n\n\n\nException: ' + e.getMessage() + '\n\n' + JSON.deserializeUntyped(res.getBody()) + '\n\n\n\n\n');
		}
		return coordinatesMap;
	}

	public static String getCountyByCoordinates() {
		if(coordinatesMap.isEmpty()) getCoordinatesMap();
		return getCountyByCoordinates(coordinatesMap.get('latitude'), coordinatesMap.get('longitude'));
	}

	public static String getCountyByCoordinates(Double latitude, Double longitude) {
		return getCountyByCoordinates(String.valueOf(latitude), String.valueOf(longitude));
	}

	public static String getCountyByCoordinates(String latitude, String longitude) {
		countyLookupUrl = countyLookupUrl.replace('{!latitude}', latitude);
		countyLookupUrl = countyLookupUrl.replace('{!longitude}', longitude);
		HttpRequest req = new HttpRequest();
		req.setMethod('GET');
		req.setEndpoint(countyLookupUrl);
		Http http = new Http();
		HTTPResponse res = http.send(req);
		Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
		Map<String, Object> r = (Map<String, Object>)m.get('County');
		return String.valueOf(r.get('name'));
	}

	private static String getCoordinateLookupUrl() {
		String coordinateLookupUrl = 'https://geocoding.geo.census.gov/geocoder/locations/address?street={!street}&city={!city}&state={!state}&zip={!zip}&format=json&benchmark=9';
		for(String key : paramMap.keySet()) {
			coordinateLookupUrl = coordinateLookupUrl.replace('{!'+key+'}', EncodingUtil.urlEncode(paramMap.get(key), 'UTF-8'));
		}
		return coordinateLookupUrl;
	}
}