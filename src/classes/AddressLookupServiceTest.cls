@isTest
public class AddressLookupServiceTest {

	@isTest
	static void testGetCoordinatesMap() {
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new CensusServiceMock());
		Map<String, String> paramMap = new Map<String, String>();
		paramMap.put('street', '3762 Falcon View Drive');
		paramMap.put('city', 'Arnold');
		paramMap.put('state', 'MO');
		paramMap.put('zip', '63010');
		AddressLookupService svc = new AddressLookupService(paramMap);
		Map<String, String> coordinatesMap = svc.getCoordinatesMap();
		System.assert(String.isNotBlank(coordinatesMap.get('latitude')));
		System.assert(String.isNotBlank(coordinatesMap.get('longitude')));
		Test.stopTest();
	}

	@isTest
	static void testGetCountyByCoordinates() {
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new FccServiceMock());
		Map<String, String> paramMap = new Map<String, String>();
		AddressLookupService svc = new AddressLookupService(paramMap);
		svc.coordinatesMap.put('latitude', '-90.426674');
		svc.coordinatesMap.put('longitude', '38.448368');
		String county = svc.getCountyByCoordinates();
		System.assertEquals('Jefferson', county);
		Test.stopTest();
	}

	class CensusServiceMock implements HttpCalloutMock {
		public HttpResponse respond(HttpRequest req) {
			HttpResponse res = new HttpResponse();
	        res.setHeader('Content-Type', 'application/json');
	        res.setBody('{"result":{"input":{"address":{"state":"MO","street":"3762 Falcon View Drive","zip":"63010","city":"Arnold"},"benchmark":{"id":"9","isDefault":false,"benchmarkName":"Public_AR_Census2010","benchmarkDescription":"Public Address Ranges - Census 2010 Benchmark"}},"addressMatches":[{"matchedAddress":"3762 Falcon View Dr, ARNOLD, MO, 63010","coordinates":{"x":-90.426674,"y":38.448368},"tigerLine":{"side":"R","tigerLineId":"62796419"},"addressComponents":{"state":"MO","zip":"63010","city":"ARNOLD","fromAddress":"3788","toAddress":"3762","preQualifier":"","preDirection":"","preType":"","streetName":"Falcon View","suffixType":"Dr","suffixDirection":"","suffixQualifier":""}}]}}');
	        res.setStatusCode(200);
	        return res;
		}
	}

	class FccServiceMock implements HttpCalloutMock {
		public HttpResponse respond(HttpRequest req) {
			HttpResponse res = new HttpResponse();
	        res.setHeader('Content-Type', 'application/json');
	        res.setBody('{"Block":{"FIPS":"290997001192000"},"County":{"FIPS":"29099","name":"Jefferson"},"State":{"FIPS":"29","code":"MO","name":"Missouri"},"status":"OK","executionTime":"192"}');
	        res.setStatusCode(200);
	        return res;
		}
	}
}
