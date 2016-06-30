package rt.vertx.server.web

import io.vertx.core.Handler
import io.vertx.core.http.HttpServerRequest
import org.slf4j.LoggerFactory

class WebFileHandler {
	static val logger = LoggerFactory.getLogger('HTTP-REQUEST')
	
	static def Handler<HttpServerRequest> create(String folder) {
		return [ req |
			val file = if (req.path.equals('/')) 'index.html' else req.path
			
			logger.debug(file)
			req.response.sendFile(folder + '/' + file)
		]
	}
}