package rt.vertx.server

import io.vertx.core.http.HttpServer
import rt.pipeline.Router
import rt.pipeline.DefaultMessageConverter
import org.slf4j.LoggerFactory
import static extension rt.vertx.server.URIParserHelper.*

class WsRouter extends Router {
	static val logger = LoggerFactory.getLogger('WS-ROUTER')
	
	val converter = new DefaultMessageConverter
	
	val HttpServer server

	new(HttpServer server) {
		this.server = server
		
		server.websocketHandler[ ws |
			val route = ws.uri.route
			val client = ws.query.queryParams.get('client')
			logger.debug('ROUTE {}', route)
			logger.debug('CLIENT {}', client)

			val pipeline = routes.get(route)
			if(pipeline == null) {
				ws.close return
			}
			
			val sb = new StringBuilder
			val resource = pipeline.createResource(client, [ msg |
				val textReply = converter.toJson(msg)
				ws.writeFinalTextFrame(textReply)
				logger.debug('SENT {}', textReply)
			], [ ws.close ])
			
			resource.subscribe(client)
			
			ws.frameHandler[
				sb.append(textData)
				if (isFinal) {
					val textMsg = sb.toString
					logger.debug('RECEIVED {}', textMsg)
					
					val msg = converter.fromJson(textMsg)
					sb.length = 0
					
					resource.process(msg)
				}
			]
			
			ws.closeHandler[ resource.release ]
		]
	}
	
	def void listen(int port) {
		server.listen(port)
	}
}