package rt.vertx.server

import io.vertx.core.http.HttpServer
import rt.pipeline.Router
import java.util.HashMap
import rt.pipeline.DefaultMessageConverter

class VertxRouter extends Router {
	val converter = new DefaultMessageConverter
	
	val HttpServer server

	new(HttpServer server) {
		this.server = server
		
		server.websocketHandler[ ws |
			val route = getRoute(ws.uri)
			val client = getQueryParams(ws.query).get('client')
			println('ROUTE: ' + route)
			println('CLIENT: ' + client)

			val pipeline = routes.get(route)
			if(pipeline == null) {
				ws.close return
			}
			
			val sb = new StringBuilder
			val resource = pipeline.createResource(client, ws.textHandlerID, [ msg |
				val textReply = converter.toJson(msg)
				ws.writeFinalTextFrame(textReply)
				println('SENT: ' + textReply)
			], [ ws.close ])
			
			resource.subscribe(client)
			
			ws.frameHandler[
				sb.append(textData)
				if (isFinal) {
					val textMsg = sb.toString
					println('RECEIVED: ' + textMsg)
					
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
	
	private def getRoute(String uri) {
		return uri.split('\\?').get(0)
	}
	
	private def getQueryParams(String query) {
		val params = new HashMap<String, String>
		
		val paramsString = query.split('&')
		paramsString.forEach[
			val keyValue = split('=')
			params.put(keyValue.get(0), keyValue.get(1))
		]
		
		return params
	}
}