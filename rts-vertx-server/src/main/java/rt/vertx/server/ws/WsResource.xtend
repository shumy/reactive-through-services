package rt.vertx.server.ws

import io.vertx.core.http.ServerWebSocket
import org.eclipse.xtend.lib.annotations.Accessors
import org.slf4j.LoggerFactory
import rt.async.pubsub.ISubscription
import rt.async.pubsub.Message
import rt.pipeline.pipe.PipeResource
import rt.pipeline.pipe.channel.IPipeChannel.PipeChannelInfo
import rt.pipeline.pipe.use.ChannelService
import rt.plugin.service.IServiceClientFactory
import rt.vertx.server.CtxHeaders
import rt.vertx.server.ServiceClientFactory
import rt.plugin.service.ServiceException

class WsResource {
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
		
		this.srvClientFactory = new ServiceClientFactory(parent.pipeline.mb, client, ws.textHandlerID) => [
			redirects.put('srv:channel', client + '/ch:req')
		]
		
		val sb = new StringBuilder
		this.resource  => [
			object(IServiceClientFactory, srvClientFactory)
			
			sendCallback = [ send ]
			
			contextCallback = [
				object(IServiceClientFactory, srvClientFactory)
				if (parent.headersMap != null) {
					val reqHeaders = #{
						//TODO: add more possible required headers...
						'client' -> client
					}
					
					val headers = new CtxHeaders
					reqHeaders.forEach[ key, value |
						if (parent.headersMap.containsKey(key))
							headers.add(parent.headersMap.get(key), value)
					]
					
					object(CtxHeaders, headers)
				}
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
					logger.error('CHANNEL-BIND-ERROR {} {}', chInfo.uuid, result(String))
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
				logger.info('RECEIVED {} {}', Thread.currentThread, textMsg)
				
				val msg = parent.converter.fromJson(textMsg)
				sb.length = 0
				
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
			val ex = msg.result(Exception)
			if (ex instanceof ServiceException) {
				val sex = ex as ServiceException
				msg.result = #{ 'message' -> sex.message, 'httpCode' -> sex.httpCode }
			} else {
				msg.result = #{ 'message' -> ex.message }
			}
		}
		
		val textReply = parent.converter.toJson(msg)
		ws.writeFinalTextFrame(textReply)
		logger.info('SENT {} {}', Thread.currentThread, textReply)
	}
}