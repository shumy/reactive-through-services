package rt.vertx.server

import io.vertx.core.http.HttpServer
import java.util.HashMap
import io.vertx.core.Handler
import io.vertx.core.http.HttpServerRequest
import org.slf4j.LoggerFactory
import java.util.Stack
import java.util.ArrayList
import java.util.List
import static extension rt.vertx.server.URIParserHelper.*

class HttpRouter {
	static val logger = LoggerFactory.getLogger('HTTP-ROUTER')
	
	val HttpServer server
	val routes = new HashMap<String, Handler<HttpServerRequest>>
	
	new(HttpServer server) {
		this.server = server
		server.requestHandler[
			val route = uri.route
			logger.debug(route)
			
			val handler = route.search
			if (handler == null) {
				response.statusCode = 404
				response.end
				return
			}
			
			handler.handle(it)
		]
	}
	
	def route(String uri, Handler<HttpServerRequest> handler) {
		routes.put(uri, handler)
	}
	
	def route(List<String> uris, Handler<HttpServerRequest> handler) {
		uris.forEach[ routes.put(it, handler) ]
	}
	
	private def search(String route) {
		logger.debug('SEARCH {}', route)
		var handler = routes.get(route)
		if (handler == null) {
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
			
			while(handler == null && !path.isEmpty) {
				val newPath = path.pop
				logger.debug('SEARCH {}', newPath)
				handler = routes.get(newPath)
			}
		}
		
		return handler
	}
	
}