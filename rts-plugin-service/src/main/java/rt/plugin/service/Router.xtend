package rt.plugin.service

import org.slf4j.LoggerFactory
import java.util.HashMap
import java.util.List
import java.util.ArrayList
import org.eclipse.xtend.lib.annotations.Accessors
import java.util.LinkedList

abstract class Router {
	static val logger = LoggerFactory.getLogger('ROUTER')
	
	@Accessors val restRoutes = new LinkedList<RouteConfig>
	
	val root = new Route
	
	protected val String baseRoute
	
	new(String baseRoute) {
		this.baseRoute = baseRoute
	}
	
	def route(WebMethod webMethod, String uriPattern, Pair<String, String> srvPair) {
		return route(webMethod, uriPattern, srvPair.key, srvPair.value)
	}
	
	def route(WebMethod webMethod, String uriPattern, String srvAddress, String srvMethod) {
		val route = baseRoute + uriPattern
		val routePaths = route.routeSplits.routePaths
		return route(webMethod, routePaths, srvAddress, srvMethod, routePaths.defaultParamMaps)
	}
	
	def route(WebMethod webMethod, String uriPattern, String srvAddress, String srvMethod, List<String> paramMaps) {
		val route = baseRoute + uriPattern
		val routePaths = route.routeSplits.routePaths
		return route(webMethod, routePaths, srvAddress, srvMethod, paramMaps)
	}
	
	
	def void get(String uriPattern, Pair<String, String> srvPair) {
		get(uriPattern, srvPair.key, srvPair.value)
	}
	
	def void get(String uriPattern, String srvAddress, String srvMethod) {
		val route = baseRoute + uriPattern
		val routePaths = route.routeSplits.routePaths
		restRoute(WebMethod.GET, routePaths, srvAddress, srvMethod, routePaths.defaultParamMaps)
	}
	
	def void get(String uriPattern, String srvAddress, String srvMethod, List<String> paramMaps) {
		val route = baseRoute + uriPattern
		restRoute(WebMethod.GET, route, srvAddress, srvMethod, paramMaps)
	}
	
	
	def void delete(String uriPattern, Pair<String, String> srvPair) {
		delete(uriPattern, srvPair.key, srvPair.value)
	}
	
	def void delete(String uriPattern, String srvAddress, String srvMethod) {
		val route = baseRoute + uriPattern
		val routePaths = route.routeSplits.routePaths
		restRoute(WebMethod.DELETE, routePaths, srvAddress, srvMethod, routePaths.defaultParamMaps)
	}
	
	def void delete(String uriPattern, String srvAddress, String srvMethod, List<String> paramMaps) {
		val route = baseRoute + uriPattern
		restRoute(WebMethod.DELETE, route, srvAddress, srvMethod, paramMaps)
	}
	
	
	def void post(String uriPattern, Pair<String, String> srvPair) {
		post(uriPattern, srvPair.key, srvPair.value)
	}	
	
	def void post(String uriPattern, String srvAddress, String srvMethod) {
		val route = baseRoute + uriPattern
		val routePaths = route.routeSplits.routePaths
		restRoute(WebMethod.POST, routePaths, srvAddress, srvMethod, routePaths.defaultParamMapsWithBody)
	}
	
	def void post(String uriPattern, String srvAddress, String srvMethod, List<String> paramMaps) {
		val route = baseRoute + uriPattern
		restRoute(WebMethod.POST, route, srvAddress, srvMethod, paramMaps)
	}
	
	
	def void put(String uriPattern, Pair<String, String> srvPair) {
		put(uriPattern, srvPair.key, srvPair.value)
	}
	
	def void put(String uriPattern, String srvAddress, String srvMethod) {
		val route = baseRoute + uriPattern
		val routePaths = route.routeSplits.routePaths
		restRoute(WebMethod.PUT, routePaths, srvAddress, srvMethod, routePaths.defaultParamMapsWithBody)
	}
	
	def void put(String uriPattern, String srvAddress, String srvMethod, List<String> paramMaps) {
		val route = baseRoute + uriPattern
		restRoute(WebMethod.PUT, route, srvAddress, srvMethod, paramMaps)
	}
	
	protected def restRoute(WebMethod webMethod, String uriPattern, String srvAddress, String srvMethod, List<String> paramMaps) {
		val route = baseRoute + uriPattern
		val routePaths = route.routeSplits.routePaths
		return restRoute(webMethod, routePaths, srvAddress, srvMethod, paramMaps)
	}
	
	protected def restRoute(WebMethod webMethod, List<RoutePath> routePaths, String srvAddress, String srvMethod, List<String> paramMaps) {
		val processBody = ( webMethod == WebMethod.POST || webMethod == WebMethod.PUT )
		val r = route(processBody, webMethod, routePaths, srvAddress, srvMethod, paramMaps)
		restRoutes.add(r.config)
		
		return r
	}
	
	protected def route(WebMethod webMethod, List<RoutePath> routePaths, String srvAddress, String srvMethod, List<String> paramMaps) {
		val processBody = ( webMethod == WebMethod.POST || webMethod == WebMethod.PUT )
		return route(processBody, webMethod, routePaths, srvAddress, srvMethod, paramMaps)
	}
	
	protected def route(boolean processBody, WebMethod webMethod, List<RoutePath> routePaths, String srvAddress, String srvMethod, List<String> paramMaps) {
		val sb = new StringBuilder
		
		var route = root
		for (rPath: routePaths) {
			val path = if (rPath.isParameter) '*' else rPath.name
			sb.append('/')
			sb.append(path)
			
			route = route.next(path)
		}
		
		if (route.config != null) logger.warn('Override of existent route {}', route.config)
		route.config = new RouteConfig(processBody, webMethod, srvAddress, srvMethod, paramMaps, routePaths)
		logger.info('ADD (route={} conf={})', sb.toString, route.config)
		
		return route
	}
	
	protected def routeSplits(String uriPattern) {
		val splits = new ArrayList<String>(uriPattern.split('/'))
		if (uriPattern.startsWith('/') && splits.size > 0)
			splits.remove(0)
		
		return splits
	}
	
	protected def routePaths(List<String> routeSplits) {
		return routeSplits.map[ new RoutePath(it) ]
	}
	
	protected def defaultParamMaps(List<RoutePath> routePaths) {
		return routePaths.filter[ isParameter ].map[ name ].toList
	}
	
	protected def defaultParamMapsWithBody(List<RoutePath> routePaths) {
		val defaultParamMaps = new LinkedList<String>
		defaultParamMaps.add('body')
		defaultParamMaps.addAll(routePaths.filter[ isParameter ].map[ name ])
		return defaultParamMaps
	}
	
	protected def search(WebMethod webMethod, List<String> routeSplits) {
		logger.debug('SEARCH {}', routeSplits)
		
		var route = root
		var RouteConfig rConfig = null
		var RouteConfig lastGenericConfig = null
		
		var isFinal = false
		var break = false
		val iter = routeSplits.iterator
		while (iter.hasNext && !break) {
			isFinal = false
			
			route = route.get(iter.next)
			if (route == null)
				break = true
			else
				if (route.config != null && (webMethod == route.config.wMethod || route.config.wMethod == WebMethod.ALL)) {
					isFinal = true
					rConfig = route.config
					if (rConfig.isGeneric) lastGenericConfig = rConfig
				}
		}
		
		//if not reached the end of path with a final RouteConfig, use the last generic path available
		if (!isFinal)
			rConfig = lastGenericConfig
		
		//last alternative...
		if (rConfig == null) {
			route = route?.get('*')
			if (route != null && route.config != null && route.config.isGeneric && (webMethod == route.config.wMethod || route.config.wMethod == WebMethod.ALL)) {
				rConfig = route.config
			}
		}
		
		if (rConfig == null) logger.warn('Not Found: {}', routeSplits)
		return rConfig
	}
	
	static class Route {
		@Accessors var RouteConfig config = null
		val options = new HashMap<String, Route>
		
		def next(String path) {
			var route = options.get(path)
			if (route == null) {
				route = new Route
				options.put(path, route)
			}
			
			return route
		}
		
		def get(String next) {
			return options.get(next) ?: options.get('*')
		}
	}
}
