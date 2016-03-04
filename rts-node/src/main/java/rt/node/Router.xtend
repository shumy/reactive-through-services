package rt.node

import io.vertx.core.http.HttpServer
import rt.node.pipeline.Pipeline
import java.util.HashMap
import java.util.UUID
import io.vertx.core.json.JsonObject

class Router {
	val HttpServer server;
	val routes = new HashMap<String, Pipeline>

	new(HttpServer server) {
		this.server = server
		
		server.websocketHandler[ ws |
			val splits = ws.uri.split("#")
			val path = splits.get(0)
			val session = if(splits.length > 1) splits.get(1) else UUID.randomUUID.toString

			val pipeline = routes.get(path)
			if(pipeline == null) {
				ws.reject return
			}
			
			val resource = pipeline.createResource(session, ws.textHandlerID, [ msg | ws.writeFinalTextFrame(msg.toString) ], [ ws.close ])
			ws.frameHandler[ resource.process(new JsonObject(textData)) ]
			ws.closeHandler[ resource.release ]
		]
	}
	
	def void route(String path, Pipeline pipeline) {
		routes.put(path, pipeline)
	}
	
	def void listen(int port) {
		server.listen(port)
	}
}