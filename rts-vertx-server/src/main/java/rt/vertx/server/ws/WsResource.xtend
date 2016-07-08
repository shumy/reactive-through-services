package rt.vertx.server.ws

import io.vertx.core.http.ServerWebSocket
import org.slf4j.LoggerFactory
import rt.vertx.server.ServiceClientFactory
import rt.plugin.service.IServiceClientFactory
import org.eclipse.xtend.lib.annotations.Accessors
import rt.pipeline.pipe.PipeResource
import rt.pipeline.IMessageBus.Message
import rt.pipeline.pipe.channel.IPipeChannel.PipeChannelInfo
import rt.pipeline.pipe.use.ChannelService
import rt.pipeline.IMessageBus.IListener

class WsResource {
	static val logger = LoggerFactory.getLogger('WS-RESOURCE')
	
	@Accessors val String client
	@Accessors val PipeResource resource
	
	val WsRouter parent
	val ServerWebSocket ws
	val (String) => void onClose
	
	IListener chListener
	
	package new(WsRouter parent, ServerWebSocket ws, String client, (String) => void onClose) {
		this.resource = parent.pipeline.createResource(client)
		
		this.parent = parent
		this.ws = ws
		this.client = client
		this.onClose = onClose
		
		val sb = new StringBuilder
		val srvClientFactory = new ServiceClientFactory(parent.pipeline.mb, client, ws.textHandlerID) => [
			redirects.put('srv:channel', client + '/ch:req')
		]
		
		this.resource  => [
			sendCallback = [ send ]
			contextCallback = [ object(IServiceClientFactory, srvClientFactory) ]
			closeCallback = [ ws.close ]
			
			subscribe(client)
			
			//process channel requests..
			chListener = bus.listener(client + '/ch:req')[ chReqMsg |
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
				logger.trace('RECEIVED {}', textMsg)
				
				val msg = parent.converter.fromJson(textMsg)
				sb.length = 0
				
				resource.process(msg)
			}
		]
		
		ws.closeHandler[
			chListener.remove
			resource.release
			onClose?.apply(client)
		]
	}
	
	private def void send(Message msg) {
		val textReply = parent.converter.toJson(msg)
		ws.writeFinalTextFrame(textReply)
		logger.trace('SENT {}', textReply)
	}
}