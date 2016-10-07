package rt.vertx.server.ws

import io.vertx.core.http.ServerWebSocket
import org.eclipse.xtend.lib.annotations.Accessors
import org.slf4j.LoggerFactory
import rt.pipeline.IResourceProvider
import rt.pipeline.bus.ISubscription
import rt.pipeline.bus.Message
import rt.pipeline.pipe.PipeResource
import rt.pipeline.pipe.channel.IPipeChannel.PipeChannelInfo
import rt.pipeline.pipe.use.ChannelService
import rt.plugin.service.CtxHeaders
import rt.plugin.service.IServiceClientFactory
import rt.plugin.service.ServiceException
import rt.vertx.server.ServiceClientFactory

class WsResource implements IResourceProvider {
	static val logger = LoggerFactory.getLogger('WS-RESOURCE')
	
	@Accessors val String client
	@Accessors val PipeResource resource
	
	val WsRouter parent
	val ServiceClientFactory srvClientFactory
	
	val ServerWebSocket ws
	val (String) => void onClose
	
	ISubscription chSubscription
	
	package new(WsRouter parent, ServerWebSocket ws, String client, (String) => void onClose) {
		this.resource = parent.pipeline.createResource(client)
		
		this.parent = parent
		this.ws = ws
		this.client = client
		this.onClose = onClose
		
		this.srvClientFactory = new ServiceClientFactory(this, parent.pipeline.mb, client, ws.textHandlerID) => [
			redirects.put('srv:channel', client + '/ch:req')
		]
		
		val sb = new StringBuilder
		this.resource  => [
			object(IServiceClientFactory, srvClientFactory)
			
			sendCallback = [ send ]
			
			contextCallback = [
				object(IServiceClientFactory, srvClientFactory)
				
				val headers = new CtxHeaders
				headers.add('client', client)
				
				message.headers?.forEach[ key, value |
					headers.add(key, value)
				]
				
				object(CtxHeaders, headers)
			]
			
			closeCallback = [ ws.close ]
			
			//TODO: if PipeResource is a ServiceClientFactory parameter, do I really need this?
			subscribe(client)
			
			//process channel requests..
			chSubscription = bus.subscribe(client + '/ch:req')[ chReqMsg |
				val args = chReqMsg.args(PipeChannelInfo)
				val chInfo = args.get(0) as PipeChannelInfo
				logger.debug('CHANNEL-REQ {}', chInfo.uuid)
				
				//process backward channel error/reject/timeout
				bus.replyListener(chReqMsg.replyID + '/reply-error')[
					logger.error('CHANNEL-BIND-ERROR {} {}', chInfo.uuid, result(RuntimeException).message)
					parent.forgetChannelBind(chInfo)
				]
				
				//wait for channel bind and reply to service
				parent.waitForChannelBind(chInfo)[ channel |
					logger.debug('CHANNEL-BIND {}', chInfo.uuid)
					resource.addChannel(channel)
					
					val replyMsg = new Message => [ id=chReqMsg.id clt=chReqMsg.clt cmd=Message.CMD_OK result=channel ]
					bus.reply(replyMsg)
				]
				
				//publish request to client
				chReqMsg.path = ChannelService.name
				this.send(chReqMsg)
			]
		]
		
		ws.frameHandler[
			sb.append(textData)
			if (isFinal) {
				val textMsg = sb.toString
				sb.length = 0
				
				logger.info('RECEIVED {}', textMsg)
				val msg = parent.converter.fromJson(textMsg)
				resource.process(msg)
			}
		]
		
		ws.closeHandler[
			chSubscription.remove
			resource.release
			onClose?.apply(client)
		]
	}
	
	def <T> T createProxy(String srvName, Class<T> proxy) {
		return srvClientFactory.serviceClient.create('srv:' + srvName, proxy)
	}
	
	private def void send(Message msg) {
		if (msg.cmd == Message.CMD_ERROR) {
			val ex = msg.result(RuntimeException)
			if (ex instanceof ServiceException) {
				val sex = ex as ServiceException
				msg.result = #{ 'message' -> sex.message, 'httpCode' -> sex.httpCode }
			} else {
				msg.result = #{ 'message' -> ex.message }
			}
		}
		
		val textReply = parent.converter.toJson(msg)
		ws.writeFinalTextFrame(textReply)
		logger.info('SENT {}', textReply)
	}
}