package rt.vertx.server.web

import io.vertx.core.http.HttpMethod
import io.vertx.core.http.HttpServer
import org.slf4j.LoggerFactory
import rt.pipeline.IComponent
import rt.pipeline.pipe.Pipeline
import rt.plugin.service.Router
import rt.plugin.service.WebMethod
import rt.vertx.server.DefaultVertxServer

import static extension rt.vertx.server.URIParserHelper.*

class WebRouter extends Router {
	static val logger = LoggerFactory.getLogger('WEB-ROUTER')
	
	//@Accessors val resources = new HashMap<String, WebResource>
	
	package val DefaultVertxServer parent
	package val HttpServer server
	package val Pipeline pipeline
	
	def getConverter() { return parent.converter }
	
	new(DefaultVertxServer parent, String baseRoute) {
		super(baseRoute)
		
		this.parent = parent
		this.server = parent.server
		this.pipeline = parent.pipeline
		
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
	
	def vrtxService(String uriPattern, String srvAddress, IComponent vrtxService) {
		pipeline.addService(srvAddress, vrtxService)
		
		val route = baseRoute + uriPattern
		val routePaths = route.routeSplits.routePaths
		return route(false, WebMethod.ALL, routePaths, srvAddress, 'notify', #['ctx.request'])
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