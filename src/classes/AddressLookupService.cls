public class AddressLookupService {

	static String countyLookupUrl = 'http://data.fcc.gov/api/block/find?format=json&showall=true&latitude={!latitude}&longitude={!longitude}';
	public static Map<String, String> coordinatesMap {get; set;}
	public static Map<String, String> paramMap { get; set; }

	public static String getCounty(Map<String, String> pMap) {
		System.debug('mlh line als 8');
		paramMap = pMap;
		Map<String, String> coordinateMap = getCoordinatesMap();
		System.debug('mlh line als 11');
		return getCountyByCoordinates(coordinateMap.get('latitude'), coordinateMap.get('longitude'));
	}

	public static Map<String, String> getCoordinatesMap() {
		System.debug('mlh line 16');
		coordinatesMap = new Map<String, String>();
		HttpRequest req = new HttpRequest();
		req.setMethod('GET');
		req.setEndpoint(getCoordinateLookupUrl());
		Http http = new Http();
		HttpResponse res;
		try {
			System.debug('mlh line 23');
			res = http.send(req);
			System.debug('mlh line 25');
			Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
			System.debug('mlh line 27');
			Map<String, Object> r = (Map<String, Object>)m.get('result');
			System.debug('mlh line 29');
			List<Object> addressMatchesList = (List<Object>)r.get('addressMatches');
			System.debug('mlh line 31');
			Map<String, Object> a = (Map<String, Object>)addressMatchesList[0];
			System.debug('mlh line 33 a = ' + JSON.SerializePretty(a));
			Map<String, Object> c = (Map<String, Object>)a.get('coordinates');
			System.debug('mlh line 35 c = ' + JSON.SerializePretty(c));
			coordinatesMap.put('longitude', String.valueOf(c.get('x')));
			System.debug('mlh line 37');
			coordinatesMap.put('latitude', String.valueOf(c.get('y')));
			System.debug('mlh line 39');
		} catch(Exception e) {
			System.debug('\n\n\n\n\n\n\nException: ' + e.getMessage() + '\n\n' + JSON.deserializeUntyped(res.getBody()) + '\n\n\n\n\n');
		}
		System.debug('mlh line 43');
		return coordinatesMap;
	}

	public static String getCountyByCoordinates() {
		System.debug('mlh line als 31');
		if(coordinatesMap.isEmpty()) getCoordinatesMap();
		return getCountyByCoordinates(coordinatesMap.get('latitude'), coordinatesMap.get('longitude'));
	}

	public static String getCountyByCoordinates(Double latitude, Double longitude) {
		System.debug('mlh line als 37');
		return getCountyByCoordinates(String.valueOf(latitude), String.valueOf(longitude));
	}

	public static String getCountyByCoordinates(String latitude, String longitude) {
		System.debug('mlh line als 42');
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
		System.debug('mlh line 73');
		String coordinateLookupUrl = 'https://geocoding.geo.census.gov/geocoder/locations/address?street={!street}&city={!city}&state={!state}&zip={!zip}&format=json&benchmark=9';
		for(String key : paramMap.keySet()) {
			System.debug('mlh line 76. key =' + key);
			System.debug('mlh line 77. paramMap.get(key) =' + paramMap.get(key));
			coordinateLookupUrl = coordinateLookupUrl.replace('{!'+key+'}', EncodingUtil.urlEncode(paramMap.get(key), 'UTF-8'));
		}
		System.debug('mlh line 77 coordinateLookupUrl = ' + coordinateLookupUrl);
		return coordinateLookupUrl;
	}
}
