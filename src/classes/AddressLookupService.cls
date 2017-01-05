public with sharing class AddressLookupService {

	public String coordinateLookupUrl = 'https://geocoding.geo.census.gov/geocoder/locations/address?street={!street}&city={!city}&state={!state}&zip={!zip}&format=json&benchmark=9';
	public static String countyLookupUrl = 'http://data.fcc.gov/api/block/find?format=json&showall=true&latitude={!latitude}&longitude={!longitude}';
	public Map<String, String> coordinatesMap;

	public AddressLookupService(Map<String, String> paramMap) {
		coordinatesMap = new Map<String, String>();
		for(String key : paramMap.keySet()) coordinateLookupUrl = coordinateLookupUrl.replace('{!'+key+'}', paramMap.get(key));
	}

	public Map<String, String> getCoordinatesMap() {
		HttpRequest req = new HttpRequest();
		req.setMethod('GET');
		req.setEndpoint(coordinateLookupUrl);
		Http http = new Http();
		HTTPResponse res = http.send(req);
		Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
		Map<String, Object> r = (Map<String, Object>)m.get('result');
		List<Object> addressMatchesList = (List<Object>)r.get('addressMatches');
		Map<String, Object> a = (Map<String, Object>)addressMatchesList[0];
		Map<String, Object> c = (Map<String, Object>)a.get('coordinates');
		coordinatesMap.put('longitude', String.valueOf(c.get('x')));
		coordinatesMap.put('latitude', String.valueOf(c.get('y')));
		return coordinatesMap;
	}

	public String getCountyByCoordinates() {
		if(coordinatesMap.isEmpty()) getCoordinatesMap();
		return getCountyByCoordinates(coordinatesMap.get('latitude'), coordinatesMap.get('longitude'));
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
}
