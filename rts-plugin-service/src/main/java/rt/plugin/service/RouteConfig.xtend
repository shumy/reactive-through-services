package rt.plugin.service

import rt.pipeline.IMessageBus.Message
import java.util.Map
import java.util.List
import java.util.HashMap

enum WebMethod {
	GET, POST, PUT, DELETE,
	HEAD, OPTIONS, PATCH,
	CONNECT, TRACE,
	ALL
}

class RouteConfig {
	public val boolean isGeneric //does it ends with a generic route
	
	public val boolean isDirect //are the requests directly processes with no translation?
	public val WebMethod wMethod
	public val String srvAddress
	public val String srvMethod
	public val List<String> paramMaps
	public val List<RoutePath> routePaths
	
	val RouteProcessor processor
	
	new(boolean isDirect, WebMethod wMethod, String srvAddress, String srvMethod, List<String> paramMaps, List<RoutePath> routePaths, RouteProcessor processor) {
		this.isDirect = isDirect
		this.wMethod = wMethod
		this.srvAddress = srvAddress
		this.srvMethod = srvMethod
		this.paramMaps = paramMaps
		this.routePaths = routePaths
		
		this.processor = processor
		
		val rPath = routePaths.last
		this.isGeneric = if (rPath != null) rPath.name == '*' else false
	}
	
	def getParameters(List<String> routeSplits) {
		val params = new HashMap<String, String>
		
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
	
	def processRequest(Map<String, Object> queryParams) {
		return processor.request(this, queryParams)
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
	def Message request(RouteConfig config, Map<String, Object> queryParams)
	def String response(Message msg)
}