package rt.vertx.server.web

import io.vertx.core.http.HttpMethod
import io.vertx.core.http.HttpServer
import java.util.HashMap
import java.util.List
import java.util.Stack
import org.slf4j.LoggerFactory
import rt.pipeline.IMessageBus.Message
import rt.pipeline.pipe.Pipeline
import rt.plugin.service.RoutePath
import rt.plugin.service.ServiceRoute
import rt.plugin.service.WebMethod
import rt.vertx.server.web.processor.HttpRouteProcessor

import static extension rt.vertx.server.web.URIParserHelper.*

class WebRouter {
	static val logger = LoggerFactory.getLogger('HTTP-ROUTER')
	
	val HttpServer server
	val Pipeline pipeline
	val routes = new HashMap<String, ServiceRoute>
	
	val httpProcessor = new HttpRouteProcessor
	
	new(HttpServer server, Pipeline pipeline) {
		this.server = server
		this.pipeline = pipeline
		
		server.requestHandler[ req |
			logger.debug('REQUEST {}', req.uri)
			val uriSplits = req.uri.split('\\?')
			
			val route = uriSplits.get(0).route
			val routeSplits = ServiceRoute.getRouteSplits(route)
			
			val srvRoute = search(req.method.webMethod, routeSplits)
			if (srvRoute == null) {
				req.response.statusCode = 404
				req.response.end
				return
			}
			
			//create msg parameters
			val params = new HashMap<String, Object>
			params.put('http', req)
			
			if (uriSplits.length > 1) {
				//TODO: search for reserved params?
				val queryParams = uriSplits.get(1).queryParams
				params.putAll(queryParams)
			}
			
			//if is REST service, add route parameters
			val restParams = srvRoute.getParameters(routeSplits)
			params.putAll(restParams)
			
			//create resource and process message
			val resource = pipeline.createResource(req.uri) => [
				sendCallback = [ reply |
					if (reply.cmd != Message.CMD_OK) {
						req.response.statusCode = 500
						req.response.end(reply.result(String))
						return
					}
					
					req.response.statusCode = 200
					req.response.end(srvRoute.processResponse(reply))
				]
			]
			
			val msg = srvRoute.processRequest(srvRoute, params)
			resource.process(msg)
		]
	}
	
	def void route(WebMethod webMethod, String uriPattern, String srvAddress, String srvMethod, List<String> paramMaps) {
		val routePaths = ServiceRoute.getRouteSplits(uriPattern).map[ new RoutePath(it) ]
		val path = ServiceRoute.routePathsToRoute(routePaths)
		
		val srvRoute = new ServiceRoute(webMethod, srvAddress, srvMethod, paramMaps, routePaths, httpProcessor)
		logger.info('NEW-ROUTE (path={} route={})', path, srvRoute)
		routes.put(path, srvRoute)
	}
	
	def void route(String uriPattern, String srvAddress) {
		route(WebMethod.GET, uriPattern, srvAddress, 'get', #['http'])
	}
	
	def void routes(List<String> uriPatterns, String srvAddress) {
		uriPatterns.forEach[ route(srvAddress) ]
	}
	
	private def getWebMethod(HttpMethod httpMethod) {
		switch httpMethod {
			case GET: 		return WebMethod.GET
			case POST: 		return WebMethod.POST
			case PUT:		return WebMethod.PUT
			case DELETE:	return WebMethod.DELETE
			case HEAD:		return WebMethod.HEAD
			case OPTIONS:	return WebMethod.OPTIONS
			case PATCH:		return WebMethod.PATCH
			case CONNECT:	return WebMethod.CONNECT
			case TRACE:		return WebMethod.TRACE
		}
	}
	
	private def search(WebMethod webMethod, List<String> routeSplits) {
		val path = new Stack<String>
		val newRoute = new StringBuilder
		
		var index = 0
		path.push('/*')
		for (item: routeSplits) {
			newRoute.append('/')
			newRoute.append(item)
			
			if (index == routeSplits.size - 1)
				path.push(newRoute.toString)
			else
				path.push(newRoute + '/*')
			
			index++
		}
		
		var ServiceRoute srvRoute = null
		while(srvRoute == null && !path.isEmpty) {
			val newPath = path.pop
			logger.trace('SEARCH {}', newPath)
			srvRoute = routes.get(newPath)
			if (srvRoute != null) {
				logger.trace('FOUND {}', srvRoute)
				if (!srvRoute.isValid(webMethod, routeSplits)) srvRoute = null
			}
		}
		
		return srvRoute
	}
}