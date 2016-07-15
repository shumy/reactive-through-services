package rt.vertx.server.web

import io.vertx.core.http.HttpServer
import java.util.ArrayList
import java.util.HashMap
import java.util.List
import java.util.Stack
import org.slf4j.LoggerFactory
import rt.pipeline.IMessageBus.Message
import rt.pipeline.pipe.Pipeline

import static extension rt.vertx.server.web.URIParserHelper.*
import java.util.Map

class WebRouter {
	static val logger = LoggerFactory.getLogger('HTTP-ROUTER')
	
	val HttpServer server
	val Pipeline pipeline
	val routes = new HashMap<String, String>
	
	new(HttpServer server, Pipeline pipeline) {
		this.server = server
		this.pipeline = pipeline
		
		server.requestHandler[ req |
			logger.debug('REQUEST {}', req.uri)
			val route = req.uri.route
			logger.debug(route)
			
			val address = route.search
			if (address == null) {
				req.response.statusCode = 404
				req.response.end
				return
			}
			
			//TODO: optimize resource creation
			val resource = pipeline.createResource(req.uri)
			resource.process(new Message => [ id=1L cmd='get' path='srv:' + address args=#[req]])
		]
	}
	
	/** Add redirect of HttpServerRequest to the service address, public methods 'get, post, put, patch, delete'
	 * @param uri Http request path (accepts paths that end with /*)
	 * @param address Of the service registered in the pipeline
	 */
	def void route(String uri, String address) {
		routes.put(uri, address)
	}
	
	def void rest(WebMethod webMethod, String uri, String address, String method, Map<String, Integer> paramMaps) {
		//TODO: how to handle REST?
	}
	
	/** Add redirects of HttpServerRequest to the service address, public method 'get, post, put, patch, delete'
	 * @param uris Http request paths (accepts paths that end with /*)
	 * @param address Of the service registered in the pipeline
	 */
	def void routes(List<String> uris, String address) {
		uris.forEach[ routes.put(it, address) ]
	}
	
	private def search(String route) {
		logger.trace('SEARCH {}', route)
		var address = routes.get(route)
		if (address == null) {
			val splits = new ArrayList<String>(route.split('/'))
			if (splits.size > 1) {
				splits.remove(0)
				splits.remove(splits.size - 1)
			}
			
			val path = new Stack<String>
			val newRoute = new StringBuilder
			
			path.push('/*')
			splits.forEach[
				newRoute.append('/')
				newRoute.append(it)
				path.push(newRoute + '/*')
			]
			
			while(address == null && !path.isEmpty) {
				val newPath = path.pop
				logger.trace('SEARCH {}', newPath)
				address = routes.get(newPath)
			}
		}
		
		return address
	}
	
	private static class WebRouterConfig {
		
	}
}