package rt.vertx.server

import io.vertx.core.http.HttpServer
import java.util.UUID
import io.vertx.core.json.JsonObject
import rt.pipeline.Router
import rt.pipeline.IMessageBus.Message

class VertxRouter extends Router {
	val HttpServer server
	
	new(HttpServer server) {
		this.server = server
		
		server.websocketHandler[ ws |
			val splits = ws.uri.split("#")
			val srvPath = splits.get(0)
			val session = if(splits.length > 1) splits.get(1) else UUID.randomUUID.toString

			val pipeline = routes.get(srvPath)
			if(pipeline == null) {
				ws.reject return
			}
			
			val resource = pipeline.createResource(session, ws.textHandlerID, [ msg | ws.writeFinalTextFrame(msg.toString) ], [ ws.close ])
			ws.frameHandler[
				val json = new JsonObject(textData)
				val msg = new Message => [
					id = json.getLong(Message.ID)
					cmd = json.getString(Message.CMD)
					client = json.getString(Message.CLIENT)
					path = json.getString(Message.PATH)
					args = json.getJsonArray(Message.ARGS).list
				]
				
				resource.process(msg)
			]
			
			ws.closeHandler[ resource.release ]
		]
	}
	
	override listen(int port) {
		server.listen(port)
	}
}