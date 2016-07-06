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
import org.eclipse.xtend.lib.annotations.Accessors
import rt.pipeline.pipe.IPipeChannel.PipeChannelInfo
import java.util.Map
import java.util.HashMap
import org.slf4j.LoggerFactory

class ClientRouter implements IServiceClientFactory {
	static val logger = LoggerFactory.getLogger('CLIENT-ROUTER')
	
	@Accessors val String server
	@Accessors val String client
	@Accessors val Pipeline pipeline
	@Accessors val ServiceClient serviceClient
	@Accessors val Map<String, String> redirects = new HashMap
	
	val converter = new DefaultMessageConverter
	val URI url
	
	PipeResource resource = null
	WebSocketClient ws = null
	
	var ready = new AtomicBoolean
	
	def IMessageBus getBus() { return pipeline.mb }
	
	new(String server, String client) {
		this(server, client, new Pipeline)
	}

	new(String server, String client, Pipeline pipeline) {
		this.url = new URI(server + '?client=' + client)
		
		this.server = server
		this.client = client
		this.pipeline = pipeline
		this.serviceClient = new ServiceClient(bus, server, client, redirects)
		
		pipeline.mb.listener(server)[ send ]
		
		connect
	}
	
	def void connect() {
		val router = this
		
		logger.info('TRY-OPEN {}', url)
		ws = new WebSocketClient(url) {
			
			override onOpen(ServerHandshake handshakedata) {
				logger.trace('OPEN')
				router.onOpen
			}
			
			override onClose(int code, String reason, boolean remote) {
				logger.trace('CLOSE')
				router.close
				Thread.sleep(3000)
				router.connect
			}
			
			override onError(Exception ex) {
				ex.printStackTrace
			}
			
			override onMessage(String textMsg) {
				logger.trace('RECEIVED {}', textMsg)
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
		resource = pipeline.createResource(server) => [
			sendCallback = [ send ]
			contextCallback = [ object(IServiceClientFactory, this) ]
			closeCallback = [ close ]
			
			it.bus.listener(server + '/ch:rpl')[ chReqMsg |
				if (chReqMsg.cmd != Message.CMD_OK) {
					chReqMsg.typ = Message.REPLY
					this.send(chReqMsg)
					return
				}
				
				val chInfo = chReqMsg.result(PipeChannelInfo)
				logger.debug('CHANNEL-BIND {}', chInfo.uuid)
				
				val channel = new ClientPipeChannelReceiver(resource, chInfo, client)
				resource.addChannel(channel)
				channel.connect
			]
		]
		ready.set(true)
	}
	
	private def void receive(String textMsg) {
		val msg = converter.fromJson(textMsg)
		resource.process(msg)
	}
}