package rt.ws.client

import java.net.URI
import java.util.HashMap
import java.util.Map
import java.util.concurrent.atomic.AtomicBoolean
import org.eclipse.xtend.lib.annotations.Accessors
import org.java_websocket.client.WebSocketClient
import org.java_websocket.handshake.ServerHandshake
import org.slf4j.LoggerFactory
import rt.async.AsyncScheduler
import rt.async.AsyncScheduler.SchedulerAsyncUtils
import rt.async.AsyncUtils
import rt.pipeline.IResourceProvider
import rt.pipeline.bus.DefaultMessageConverter
import rt.pipeline.bus.ISubscription
import rt.pipeline.bus.Message
import rt.pipeline.pipe.PipeResource
import rt.pipeline.pipe.Pipeline
import rt.pipeline.pipe.channel.IPipeChannel.PipeChannelInfo
import rt.pipeline.pipe.use.ChannelService
import rt.plugin.service.IServiceClientFactory
import rt.plugin.service.ServiceClient

import static rt.async.AsyncUtils.*

class ClientRouter implements IServiceClientFactory, IResourceProvider {
	static val logger = LoggerFactory.getLogger('CLIENT-ROUTER')
	
	@Accessors val String server
	@Accessors val String client
	@Accessors val Pipeline pipeline
	@Accessors val ServiceClient serviceClient
	@Accessors val Map<String, String> redirects = new HashMap
	
	val scheduler = new AsyncScheduler
	val converter = new DefaultMessageConverter
	val URI url
	
	val ready = new AtomicBoolean
	
	@Accessors(PUBLIC_GETTER) var PipeResource resource = null
	
	WebSocketClient ws = null
	ISubscription chSubscription = null
	
	var () => void onOpen = null
	var () => void onClose = null
	
	new(String server, String client) {
		this(server, client, new Pipeline)
	}

	new(String server, String client, Pipeline pipeline) {
		this.url = new URI(server + '?client=' + client)
		
		this.server = server
		this.client = client
		this.pipeline = pipeline
		this.serviceClient = new ServiceClient(this, pipeline.mb, server, client, redirects)
		
		pipeline.mb.subscribe(server)[ send ]
		
		AsyncUtils.set(new SchedulerAsyncUtils(scheduler))
		AsyncUtils.publisher = pipeline.mb
	}
	
	def <T> T createProxy(String srvName, Class<T> proxy) {
		return serviceClient.create('srv:' + srvName, proxy)
	}
	
	def run() {
		connect
		scheduler.run
	}
	
	def void close() {
		logger.trace('CLOSE')
		ready.set(false)
		
		chSubscription?.remove
		resource?.release
		ws?.close
		
		chSubscription = null
		resource = null
		ws = null
		
		onClose?.apply()
	}
	
	def void onOpen(() => void callback) { onOpen = callback }
	def void onClose(() => void callback) { onClose = callback }
	
	private def void connect() {
		val router = this
		
		logger.info('TRY-OPEN {}', url)
		ws = new WebSocketClient(url) {
			
			override onOpen(ServerHandshake handshakedata) {
				ready.set(true)
				scheduler.schedule[ router.onClientOpen ]
			}
			
			override onClose(int code, String reason, boolean remote) {
				scheduler.schedule[ router.close ]
				Thread.sleep(3000)
				router.connect
			}
			
			override onError(Exception ex) {
				ex.printStackTrace
			}
			
			override onMessage(String textMsg) {
				println('RECEIVED? ' + textMsg)
				scheduler.schedule[ router.receive(textMsg) ]
			}
		}
		
		ws.connect
	}
	
	private def void send(Message msg) {
		waitReady[
			val textReply = converter.toJson(msg)
			ws.send(textReply)
			logger.info('SENT {} {}', Thread.currentThread, textReply)
		]
	}
	
	private def void waitReady(() => void readyCallback) {
		while (!ready.get)
			Thread.sleep(1000)
		readyCallback.apply
	}
	
	private def void onClientOpen() {
		logger.trace('OPEN')
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
		onOpen?.apply()
	}
	
	private def void receive(String textMsg) {
		logger.info('RECEIVED {} {}', Thread.currentThread, textMsg)
		val msg = converter.fromJson(textMsg)
		resource.process(msg)
	}
}