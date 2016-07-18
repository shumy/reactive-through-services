package rt.plugin.service

import org.slf4j.LoggerFactory
import java.util.HashMap
import java.util.List
import java.util.ArrayList

class Router {
	static val logger = LoggerFactory.getLogger('ROUTER')
	
	val root = new Route
	
	def void route(WebMethod webMethod, String uriPattern, String srvAddress, String srvMethod, List<String> paramMaps, RouteProcessor routeProcessor) {
		val routePaths = uriPattern.routeSplits.map[ new RoutePath(it) ]
		val sb = new StringBuilder
		
		var route = root
		for (rPath: routePaths) {
			val path = if (rPath.isParameter) '*' else rPath.name
			sb.append('/')
			sb.append(path)
			
			route = route.next(path)
		}
		
		val srvRoute = new RouteConfig(webMethod, srvAddress, srvMethod, paramMaps, routePaths, routeProcessor)
		logger.info('ADD (path={} route={})', sb.toString, srvRoute)
		route.config = srvRoute
	}
	
	protected def routeSplits(String uriPattern) {
		val splits = new ArrayList<String>(uriPattern.split('/'))
		if (uriPattern.startsWith('/') && splits.size > 0)
			splits.remove(0)
		
		return splits
	}
	
	protected def search(WebMethod webMethod, List<String> routeSplits) {
		if (routeSplits.size == 0) routeSplits.add('*')
		
		var route = root
		var RouteConfig rConfig = null
		
		var break = false
		val iter = routeSplits.iterator
		while (iter.hasNext && !break) {
			route = route.get(iter.next)
			if (route == null)
				break = true
			else 
				rConfig = route.config
		}
		
		return rConfig
	}
	
	static class Route {
		val options = new HashMap<String, Route>
		var RouteConfig config = null
		
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
