package rt.plugin.service

import java.util.HashMap
import java.util.List

enum WebMethod {
	GET, POST, PUT, DELETE,
	//HEAD, OPTIONS, PATCH,
	//CONNECT, TRACE,
	ALL
}

class RouteConfig {
	public val boolean isGeneric //does it ends with a generic route
	public val boolean processBody
	
	public val WebMethod wMethod
	public val String srvAddress
	public val String srvMethod
	public val List<String> paramMaps
	public val List<RoutePath> routePaths
	
	package new(boolean processBody, WebMethod wMethod, String srvAddress, String srvMethod, List<String> paramMaps, List<RoutePath> routePaths) {
		this.processBody = processBody
		this.wMethod = wMethod
		this.srvAddress = srvAddress
		this.srvMethod = srvMethod
		this.paramMaps = paramMaps
		this.routePaths = routePaths
		
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
	
	def String getRequestPath()
		'''/«wMethod» «routePaths»'''
	
	override toString()
		'''/«wMethod» «routePaths» -> «srvAddress».«srvMethod» «paramMaps»'''
}

class RoutePath {
	public val boolean isParameter
	public val String name
	
	package new(String name) {
		this.isParameter = name.startsWith(':')
		this.name = if (isParameter) name.substring(1) else name
	}
	
	override toString() '''«IF isParameter»:«ENDIF»«name»'''
}