package rt.vertx.server.web

import io.netty.buffer.Unpooled
import io.vertx.core.buffer.Buffer
import io.vertx.core.http.HttpMethod
import io.vertx.core.http.HttpServer
import io.vertx.core.http.HttpServerRequest
import java.nio.ByteBuffer
import java.util.HashMap
import java.util.List
import java.util.Map
import org.slf4j.LoggerFactory
import rt.pipeline.IMessageBus.Message
import rt.pipeline.pipe.Pipeline
import rt.plugin.service.RouteConfig
import rt.plugin.service.RoutePath
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
			
			val config = search(req.method.webMethod, routeSplits)
			if (config == null) {
				req.response.statusCode = 404
				req.response.end
				return
			}
			
			val queryParams = if (uriSplits.length > 1) uriSplits.get(1).queryParams else emptyMap
			process(req, config, routeSplits, queryParams)
		]
	}
	
	
	def vrtxRoute(String uriPattern, String srvAddress) {
		val routePaths = uriPattern.routeSplits.routePaths
		return route(false, WebMethod.ALL, routePaths, srvAddress, 'notify', #['ctx.request'], httpProcessor)
	}
	
	def route(WebMethod webMethod, String uriPattern, String srvAddress, String srvMethod, List<String> paramMaps) {
		val routePaths = uriPattern.routeSplits.routePaths
		return route(webMethod, routePaths, srvAddress, srvMethod, paramMaps)
	}
	
	
	def void get(String uriPattern, String srvAddress, String srvMethod) {
		val routePaths = uriPattern.routeSplits.routePaths
		route(WebMethod.GET, routePaths, srvAddress, srvMethod, routePaths.defaultParamMaps)
	}
	
	def void get(String uriPattern, String srvAddress, String srvMethod, List<String> paramMaps) {
		route(WebMethod.GET, uriPattern, srvAddress, srvMethod, paramMaps)
	}
	
	
	def void delete(String uriPattern, String srvAddress, String srvMethod) {
		val routePaths = uriPattern.routeSplits.routePaths
		route(WebMethod.DELETE, routePaths, srvAddress, srvMethod, routePaths.defaultParamMaps)
	}
	
	def void delete(String uriPattern, String srvAddress, String srvMethod, List<String> paramMaps) {
		route(WebMethod.DELETE, uriPattern, srvAddress, srvMethod, paramMaps)
	}
	
	
	def void post(String uriPattern, String srvAddress, String srvMethod) {
		val routePaths = uriPattern.routeSplits.routePaths
		route(WebMethod.POST, routePaths, srvAddress, srvMethod, routePaths.defaultParamMapsWithBody)
	}
	
	def void post(String uriPattern, String srvAddress, String srvMethod, List<String> paramMaps) {
		route(WebMethod.POST, uriPattern, srvAddress, srvMethod, paramMaps)
	}
	
	
	def void put(String uriPattern, String srvAddress, String srvMethod) {
		val routePaths = uriPattern.routeSplits.routePaths
		route(WebMethod.PUT, routePaths, srvAddress, srvMethod, routePaths.defaultParamMapsWithBody)
	}
	
	def void put(String uriPattern, String srvAddress, String srvMethod, List<String> paramMaps) {
		route(WebMethod.PUT, uriPattern, srvAddress, srvMethod, paramMaps)
	}
	
	
	private def route(WebMethod webMethod, List<RoutePath> routePaths, String srvAddress, String srvMethod, List<String> paramMaps) {
		val processBody = ( webMethod == WebMethod.POST || webMethod == WebMethod.PUT )
		return route(processBody, webMethod, routePaths, srvAddress, srvMethod, paramMaps, httpProcessor)
	}
	
	private def process(HttpServerRequest req, RouteConfig config, List<String> routeSplits, Map<String, String> queryParams) {
		//if is REST service, add route parameters
		val routeParams = config.getParameters(routeSplits)
		
		//create msg parameters
		val params = new HashMap<String, Object> => [
			putAll(queryParams)
			putAll(routeParams)
		]
		
		//TODO: search for reserved params?
		
		//create resource and process message
		val resource = pipeline.createResource(req.uri) => [
			sendCallback = [ reply |
				if (reply.cmd != Message.CMD_OK) {
					req.response.statusCode = 500
					req.response.end(reply.result(String))
					return
				}
				
				req.response.statusCode = 200
				
				val content = config.processResponse(reply)
				if (content.class == String) {
					req.response.end(content as String)
				} else if (content instanceof ByteBuffer) {
					val cntBuffer = content as ByteBuffer
					val buffer = Buffer.buffer(Unpooled.wrappedBuffer(cntBuffer))
					req.response.end(buffer)
				} else {
					req.response.statusCode = 500
					req.response.end('Service output not supported (String or ByteBuffer)!')
				}
			]
		]
		
		if (!config.processBody) {
			params.put('ctx.request', req)
			params.put('ctx.path', req.path)
			
			//direct mode, request will be processed in the service
			val msg = config.processRequest(params)
			resource.process(msg)
		} else {
			//not a direct process, translate body
			req.bodyHandler[
				val textBody = getString(0, length)
				params.put('body', textBody)
				
				val msg = config.processRequest(params)
				resource.process(msg)
			]
		}
	}
	
	private def getWebMethod(HttpMethod httpMethod) {
		switch httpMethod {
			case GET: 		return WebMethod.GET
			case POST: 		return WebMethod.POST
			case PUT:		return WebMethod.PUT
			case DELETE:	return WebMethod.DELETE
			//case HEAD:		return WebMethod.HEAD
			//case OPTIONS:		return WebMethod.OPTIONS
			//case PATCH:		return WebMethod.PATCH
			//case CONNECT:		return WebMethod.CONNECT
			//case TRACE:		return WebMethod.TRACE
			default: return WebMethod.ALL
		}
	}
}