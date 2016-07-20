package rt.vertx.server

import java.util.HashMap

class URIParserHelper {
	static def getRoute(String uri) {
		val route = uri.split('\\?').get(0)
		
		if (route.startsWith('/'))
			return route
		else
			return '/' + route
	}
	
	static def getQueryParams(String query) {
		val params = new HashMap<String, String>
		
		val paramsString = query?.split('&')
		paramsString?.forEach[
			val keyValue = split('=')
			params.put(keyValue.get(0), keyValue.get(1))
		]
		
		return params
	}
}