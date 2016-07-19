package rt.plugin.service

import org.slf4j.LoggerFactory
import java.util.HashMap
import java.util.List
import java.util.ArrayList
import org.eclipse.xtend.lib.annotations.Accessors

abstract class Router {
	static val logger = LoggerFactory.getLogger('ROUTER')
	
	val root = new Route
	
	protected def route(boolean isDirect, WebMethod webMethod, String uriPattern, String srvAddress, String srvMethod, List<String> paramMaps, RouteProcessor routeProcessor) {
		val routePaths = uriPattern.routeSplits.map[ new RoutePath(it) ]
		return route(isDirect, webMethod, routePaths, srvAddress, srvMethod, paramMaps, routeProcessor)
	}
	
	protected def route(boolean isDirect, WebMethod webMethod, List<RoutePath> routePaths, String srvAddress, String srvMethod, List<String> paramMaps, RouteProcessor routeProcessor) {
		val sb = new StringBuilder
		
		var route = root
		for (rPath: routePaths) {
			val path = if (rPath.isParameter) '*' else rPath.name
			sb.append('/')
			sb.append(path)
			
			route = route.next(path)
		}
		
		if (route.config != null) logger.warn('Override of existent route {}', route.config)
		route.config = new RouteConfig(isDirect, webMethod, srvAddress, srvMethod, paramMaps, routePaths, routeProcessor)
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
	
	protected def search(WebMethod webMethod, List<String> routeSplits) {
		if (routeSplits.size == 0) routeSplits.add('*')
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
