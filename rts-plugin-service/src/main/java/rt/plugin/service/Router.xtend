package rt.plugin.service

import org.slf4j.LoggerFactory
import java.util.HashMap
import java.util.List
import java.util.ArrayList

abstract class Router {
	static val logger = LoggerFactory.getLogger('ROUTER')
	
	val root = new Route => [ path = new RoutePath('root') ]
	
	protected def void route(WebMethod webMethod, String uriPattern, String srvAddress, String srvMethod, List<String> paramMaps, RouteProcessor routeProcessor) {
		val routePaths = uriPattern.routeSplits.map[ new RoutePath(it) ]
		val sb = new StringBuilder
		
		var route = root
		for (rPath: routePaths) {
			val path = if (rPath.isParameter) '*' else rPath.name
			sb.append('/')
			sb.append(path)
			
			route = route.next(path)
			route.path = rPath
		}
		
		if (route.config != null) logger.warn('Override of existent route {}', route.config)
		route.config = new RouteConfig(webMethod, srvAddress, srvMethod, paramMaps, routePaths, routeProcessor)
		logger.info('ADD (route={} conf={})', sb.toString, route.config)
	}
	
	protected def routeSplits(String uriPattern) {
		val splits = new ArrayList<String>(uriPattern.split('/'))
		if (uriPattern.startsWith('/') && splits.size > 0)
			splits.remove(0)
		
		return splits
	}
	
	protected def search(WebMethod webMethod, List<String> routeSplits) {
		if (routeSplits.size == 0) routeSplits.add('*')
		logger.debug('SEARCH {}', routeSplits)
		
		var route = root
		var RouteConfig rConfig = null
		
		var break = false
		val iter = routeSplits.iterator
		while (iter.hasNext && !break) {
			//REST services need exact URI path
			if (route.path.isParameter) rConfig = null
			
			route = route.get(iter.next)
			if (route == null)
				break = true
			else
				if (route.config != null && (webMethod == route.config.wMethod || route.config.wMethod == WebMethod.ALL))
					rConfig = route.config
		}
		
		if (rConfig == null) logger.warn('Not Found: {}', routeSplits)
		return rConfig
	}
	
	static class Route {
		var RoutePath path = null
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
