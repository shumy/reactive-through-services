package rt.ws.client

import org.java_websocket.client.WebSocketClient
import java.net.URI
import org.java_websocket.handshake.ServerHandshake
import rt.pipeline.IMessageBus.Message
import rt.pipeline.pipe.Pipeline
import rt.pipeline.pipe.PipeResource
import java.util.concurrent.atomic.AtomicBoolean
import rt.pipeline.IMessageBus
import rt.pipeline.DefaultMessageConverter
import rt.plugin.service.ServiceClient
import rt.plugin.service.IServiceClientFactory

class ClientRouter implements IServiceClientFactory {
	val converter = new DefaultMessageConverter
	
	val URI uri
	val String server
	val String client
	val Pipeline pipeline
	
	PipeResource resource = null
	WebSocketClient ws = null
	
	var ready = new AtomicBoolean
	
	def IMessageBus getBus() { return pipeline.mb }
	
	new(String server, String client) {
		this(server, client, new Pipeline)
	}

	new(String server, String client, Pipeline pipeline) {
		this.uri = new URI(server + '?client=' + client)
		
		this.server = server
		this.client = client
		this.pipeline = pipeline
		
		pipeline.mb.listener(server)[ send ]
		
		connect
	}
	
	override createServiceClient() {
		return new ServiceClient(bus, server, client)
	}
	
	def void connect() {
		val router = this
		
		println('TRY-OPEN: ' + uri)
		ws = new WebSocketClient(uri) {
			
			override onOpen(ServerHandshake handshakedata) {
				router.onOpen
			}
			
			override onClose(int code, String reason, boolean remote) {
				router.close
				Thread.sleep(3000)
				router.connect
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
	
	private def void send(Message msg) {
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
		resource = pipeline.createResource(server, [ send ], [ close ])
		ready.set(true)
	}
	
	private def void receive(String textMsg) {
		val msg = converter.fromJson(textMsg)
		resource.process(msg)[
			object(IServiceClientFactory, this)
		]
	}
}