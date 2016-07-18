package rt.plugin.service

import rt.pipeline.IMessageBus.Message
import java.util.Map
import java.util.List
import java.util.HashMap
import java.util.ArrayList

enum WebMethod {
	GET, POST, PUT, DELETE,
	HEAD, OPTIONS, PATCH,
	CONNECT, TRACE,
	ALL
}

class ServiceRoute {
	public val WebMethod wMethod
	public val String srvAddress
	public val String srvMethod
	public val List<String> paramMaps
	public val List<RoutePath> routePaths
	
	val RouteProcessor processor
	
	new(WebMethod wMethod, String srvAddress, String srvMethod, List<String> paramMaps, List<RoutePath> routePaths, RouteProcessor processor) {
		this.wMethod = wMethod
		this.srvAddress = srvAddress
		this.srvMethod = srvMethod
		this.paramMaps = paramMaps
		this.routePaths = routePaths
		
		this.processor = processor
	}
	
	static def getRouteSplits(String uriPattern) {
		val splits = new ArrayList<String>(uriPattern.split('/'))
		if (uriPattern.startsWith('/') && splits.size > 0)
			splits.remove(0)
		
		return splits
	}
	
	static def routePathsToRoute(List<RoutePath> routePaths) {
		val pathSplits = routePaths.map[ if (isParameter) '*' else it ]
		return '''/«FOR item: pathSplits SEPARATOR '/'»«item»«ENDFOR»'''
	}
	
	def isValid(WebMethod webMethod, List<String> routeSplits) {
		//println('''IN: «webMethod» «routeSplits»''')
		//println('''CONFIG: «wMethod» «routePaths»''')
		
		if (wMethod != webMethod && wMethod != WebMethod.ALL )
			return false
		
		val iter = routeSplits.iterator
		for (rPath: routePaths) {
			if(iter.hasNext) {
				val next = iter.next
				if (!rPath.isParameter && rPath.name != '*' && rPath.name != next) return false
			} else {
				if (rPath.name != '*') return false
			}
		}
		
		return true
	}
	
	def getParameters(List<String> routeSplits) {
		val params = new HashMap<String, Object>
		
		val iter = routeSplits.iterator
		for (rPath: routePaths) {
			if (iter.hasNext) {
				val next = iter.next
				if (rPath.isParameter)
					params.put(rPath.name, next)
			}
		}
		
		return params
	}
	
	def processRequest(ServiceRoute srvRoute, Map<String, Object> queryParams) {
		return processor.request(srvRoute, queryParams)
	}
	
	def processResponse(Message msg) {
		return processor.response(msg)
	}
	
	override toString() '''/«wMethod» «routePaths» -> «srvAddress».«srvMethod» «paramMaps»'''
}

class RoutePath {
	public val boolean isParameter
	public val String name
	
	new(String name) {
		this.isParameter = name.startsWith(':')
		this.name = if (isParameter) name.substring(1) else name
	}
	
	override toString() '''«IF isParameter»:«ENDIF»«name»'''
}

interface RouteProcessor {
	def Message request(ServiceRoute srvRoute, Map<String, Object> queryParams)
	def String response(Message msg)
}