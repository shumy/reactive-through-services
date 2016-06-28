package rt.ws.client

import org.java_websocket.client.WebSocketClient
import java.net.URI
import org.java_websocket.handshake.ServerHandshake
import rt.pipeline.IMessageBus.Message
import rt.pipeline.pipe.Pipeline
import java.util.UUID
import rt.pipeline.pipe.PipeResource

class ClientRouter {
	val URI uri
	val String session
	val Pipeline pipeline
	val MessageConverter converter
	
	var PipeResource resource = null
	var WebSocketClient ws = null
	
	new(String server, String client, Pipeline pipeline, MessageConverter converter) {
		uri = new URI(server + '?client=' + client)
		this.session = client
		this.pipeline = pipeline
		this.converter = converter
	}
	
	def void bind(() => void ready) {
		val router = this
		
		ws = new WebSocketClient(uri) {
			
			override onOpen(ServerHandshake handshakedata) {
				println('OPEN on ' + uri)
				router.onOpen
				ready.apply
			}
			
			override onClose(int code, String reason, boolean remote) {
				router.close
				
				//TODO: reopen ?
				//Thread.sleep(3000)
				//bind
			}
			
			override onError(Exception ex) {
				ex.printStackTrace
			}
			
			override onMessage(String textMsg) {
				println('RECEIVED: ' + textMsg)
				router.receive(textMsg)
			}
		}
		
		ws.connect
	}
	
	
	def void close() {
		ws?.close
		resource?.release
		
		ws = null
		resource = null
	}
	
	def void send(Message msg) {
		val textMsg = converter.toJson(msg)
		ws.send(textMsg)
	}
	
	private def onOpen() {
		val uuid = UUID.randomUUID.toString
		resource = pipeline.createResource(session, uuid, [ msg | this.send(msg) ], [ this.close ])
	}
	
	private def void receive(String textMsg) {
		val msg = converter.fromJson(textMsg)
		resource.process(msg)
	}
}