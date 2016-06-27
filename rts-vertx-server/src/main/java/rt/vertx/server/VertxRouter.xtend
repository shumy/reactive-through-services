package rt.vertx.server

import io.vertx.core.http.HttpServer
import java.util.UUID
import rt.pipeline.Router

class VertxRouter extends Router {
	val HttpServer server
	val converter = new MessageConverter

	new(HttpServer server) {
		this.server = server
		
		server.websocketHandler[ ws |
			val splits = ws.uri.split('#')
			val srvPath = splits.get(0)
			val session = if(splits.length > 1) splits.get(1) else UUID.randomUUID.toString

			val pipeline = routes.get(srvPath)
			if(pipeline == null) {
				ws.reject return
			}
			
			val sb = new StringBuilder
			val resource = pipeline.createResource(session, ws.textHandlerID, [ msg | ws.writeFinalTextFrame(converter.toJson(msg)) ], [ ws.close ])
			ws.frameHandler[
				sb.append(textData)
				if (isFinal) {
					val msg = converter.fromJson(sb.toString)
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