package rt.ws.client

import org.java_websocket.client.WebSocketClient
import java.net.URI
import org.java_websocket.handshake.ServerHandshake
import rt.pipeline.IMessageBus.Message
import rt.pipeline.pipe.Pipeline
import java.util.UUID
import rt.pipeline.pipe.PipeResource
import java.util.concurrent.atomic.AtomicBoolean

class ClientRouter {
	val URI uri
	val String client
	val Pipeline pipeline
	val MessageConverter converter
	
	PipeResource resource = null
	WebSocketClient ws = null
	
	var ready = new AtomicBoolean
	
	new(String server, String client, Pipeline pipeline, MessageConverter converter) {
		uri = new URI(server + '?client=' + client)
		this.client = client
		this.pipeline = pipeline
		this.converter = converter
		
		bind
	}
	
	def void bind() {
		val router = this
		
		println('TRY-OPEN: ' + uri)
		ws = new WebSocketClient(uri) {
			
			override onOpen(ServerHandshake handshakedata) {
				router.onOpen
				ready.set(true)
			}
			
			override onClose(int code, String reason, boolean remote) {
				router.close
				Thread.sleep(3000)
				router.bind
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
		ready.set(false)
		ws?.close
		resource?.release
		
		ws = null
		resource = null
	}
	
	def void send(Message msg) {
		waitReady[
			val textMsg = converter.toJson(msg)
			ws.send(textMsg)
		]
	}
	
	private def void waitReady(() => void readyCallback) {
		while (!ready.get)
			Thread.sleep(1000)
		readyCallback.apply
	}
	
	private def void onOpen() {
		val uuid = UUID.randomUUID.toString
		resource = pipeline.createResource(client, uuid, [ msg | this.send(msg) ], [ this.close ])
	}
	
	private def void receive(String textMsg) {
		val msg = converter.fromJson(textMsg)
		resource.process(msg)
	}
}