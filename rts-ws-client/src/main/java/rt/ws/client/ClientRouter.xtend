package rt.ws.client

import java.net.URI
import java.util.HashMap
import java.util.Map
import java.util.concurrent.atomic.AtomicBoolean
import org.eclipse.xtend.lib.annotations.Accessors
import org.java_websocket.client.WebSocketClient
import org.java_websocket.handshake.ServerHandshake
import org.slf4j.LoggerFactory
import rt.async.pubsub.Message
import rt.pipeline.DefaultMessageConverter
import rt.pipeline.pipe.PipeResource
import rt.pipeline.pipe.Pipeline
import rt.pipeline.pipe.channel.IPipeChannel.PipeChannelInfo
import rt.pipeline.pipe.use.ChannelService
import rt.plugin.service.IServiceClientFactory
import rt.plugin.service.ServiceClient
import rt.async.pubsub.ISubscription

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
	ISubscription chSubscription = null
	
	var ready = new AtomicBoolean
	
	new(String server, String client) {
		this(server, client, new Pipeline)
	}

	new(String server, String client, Pipeline pipeline) {
		this.url = new URI(server + '?client=' + client)
		
		this.server = server
		this.client = client
		this.pipeline = pipeline
		this.serviceClient = new ServiceClient(pipeline.mb, server, client, redirects)
		
		pipeline.mb.subscribe(server)[ send ]
		
		connect
	}
	
	def <T> T createProxy(String srvName, Class<T> proxy) {
		return serviceClient.create('srv:' + srvName, proxy)
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
		
		chSubscription?.remove
		resource?.release
		ws?.close
		
		chSubscription = null
		resource = null
		ws = null
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
			
			chSubscription = bus.subscribe(server + '/ch:rpl')[ chReqMsg |
				if (chReqMsg.cmd != Message.CMD_OK) {
					chReqMsg.typ = Message.REPLY
					this.send(chReqMsg)
					return
				}
				
				val chInfo = chReqMsg.result(PipeChannelInfo).invertType
				
				val channel = new ClientPipeChannel(resource, chInfo, client)
				addChannel(channel)
				process(new Message => [ path=ChannelService.name cmd='bind' result=channel ])
				
				channel.connect
				logger.debug('CHANNEL-BIND {}', chInfo.uuid)
			]
		]
		ready.set(true)
	}
	
	private def void receive(String textMsg) {
		val msg = converter.fromJson(textMsg)
		resource.process(msg)
	}
}