package rt.vertx.server.web

import io.vertx.core.http.HttpMethod
import io.vertx.core.http.HttpServer
import java.util.HashMap
import java.util.List
import org.slf4j.LoggerFactory
import rt.pipeline.IMessageBus.Message
import rt.pipeline.pipe.Pipeline
import rt.plugin.service.Router
import rt.plugin.service.WebMethod
import rt.vertx.server.web.processor.HttpRouteProcessor

import static extension rt.vertx.server.web.URIParserHelper.*

class WebRouter extends Router {
	static val logger = LoggerFactory.getLogger('HTTP-ROUTER')
	
	val HttpServer server
	val Pipeline pipeline
	
	val httpProcessor = new HttpRouteProcessor
	
	new(HttpServer server, Pipeline pipeline) {
		this.server = server
		this.pipeline = pipeline
		
		server.requestHandler[ req |
			logger.debug('REQUEST {}', req.uri)
			val uriSplits = req.uri.split('\\?')
			
			val route = uriSplits.get(0).route
			val routeSplits = route.routeSplits
			
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
		route(webMethod, uriPattern, srvAddress, srvMethod, paramMaps, httpProcessor)
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
}