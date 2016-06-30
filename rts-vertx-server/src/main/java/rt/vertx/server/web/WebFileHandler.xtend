package rt.vertx.server.web

import io.vertx.core.Handler
import io.vertx.core.http.HttpServerRequest
import org.slf4j.LoggerFactory
import static extension rt.vertx.server.URIParserHelper.*

class WebFileHandler {
	static val logger = LoggerFactory.getLogger('HTTP-REQUEST')
	
	static def Handler<HttpServerRequest> create(String folder) {
		return [ req |
			//protect against filesystem attacks
			if (!req.path.validPath) {
				logger.error('Request path not accepted: {}', req.path)
				
				req.response.statusCode = 403
				req.response.end = 'Request path not accepted!'
				return
			}
			
			val file = if (req.path.equals('/')) {
				'/index.html'
			} else {
				if (!req.path.startsWith('/')) '/' + req.path else req.path 
			}
			
			logger.debug(file)
			req.response.sendFile(folder + file, 0, Long.MAX_VALUE)[
				if (!succeeded) {
					req.response.statusCode = 404
					req.response.end = 'Not found!'
				}
			]
		]
	}
}