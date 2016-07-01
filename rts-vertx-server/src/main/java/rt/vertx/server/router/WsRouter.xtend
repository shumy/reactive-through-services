package rt.vertx.server.router

import io.vertx.core.http.HttpServer
import rt.pipeline.DefaultMessageConverter
import org.slf4j.LoggerFactory
import rt.plugin.service.IServiceClientFactory
import static extension rt.vertx.server.URIParserHelper.*
import rt.pipeline.pipe.Pipeline
import rt.vertx.server.ServiceClientFactory

class WsRouter {
	static val logger = LoggerFactory.getLogger('WS-ROUTER')
	
	val converter = new DefaultMessageConverter
	
	val String route
	val HttpServer server
	val Pipeline pipeline

	new(String route, HttpServer server, Pipeline pipeline) {
		this.route = route
		this.server = server
		this.pipeline = pipeline
		
		server.websocketHandler[ ws |
			val client = ws.query.queryParams.get('client')
			logger.debug('CLIENT {}', client)
			
			if (ws.uri.route != route) {
				ws.close return
			}
			
			val sb = new StringBuilder
			val resource = pipeline.createResource(client, [ msg |
				val textReply = converter.toJson(msg)
				ws.writeFinalTextFrame(textReply)
				logger.debug('SENT {}', textReply)
			], [ ws.close ])
			
			val srvClientFactory = new ServiceClientFactory(pipeline.mb, client, ws.textHandlerID)
			resource.subscribe(client)
			
			ws.frameHandler[
				sb.append(textData)
				if (isFinal) {
					val textMsg = sb.toString
					logger.debug('RECEIVED {}', textMsg)
					
					val msg = converter.fromJson(textMsg)
					sb.length = 0
					
					resource.process(msg)[
						object(IServiceClientFactory, srvClientFactory)
					]
				}
			]
			
			ws.closeHandler[ resource.release ]
		]
	}
}