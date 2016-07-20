package rt.vertx.server.web

import io.vertx.core.http.HttpMethod
import io.vertx.core.http.HttpServer
import java.util.List
import org.slf4j.LoggerFactory
import rt.pipeline.DefaultMessageConverter
import rt.pipeline.pipe.Pipeline
import rt.plugin.service.RoutePath
import rt.plugin.service.Router
import rt.plugin.service.WebMethod

import static extension rt.vertx.server.web.URIParserHelper.*

class WebRouter extends Router {
	static val logger = LoggerFactory.getLogger('WEB-ROUTER')
	
	//@Accessors val resources = new HashMap<String, WebResource>
	
	package val converter = new DefaultMessageConverter
	package val HttpServer server
	package val Pipeline pipeline
	
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
			val webResource = new WebResource(this, config)
			webResource.process(req, routeSplits, queryParams)
		]
	}
	
	
	def vrtxRoute(String uriPattern, String srvAddress) {
		val routePaths = uriPattern.routeSplits.routePaths
		return route(false, WebMethod.ALL, routePaths, srvAddress, 'notify', #['ctx.request'])
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
		return route(processBody, webMethod, routePaths, srvAddress, srvMethod, paramMaps)
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
			default: 		return WebMethod.ALL
		}
	}
}