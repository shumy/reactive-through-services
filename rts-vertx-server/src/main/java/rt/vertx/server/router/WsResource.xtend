package rt.vertx.server.router

import io.vertx.core.http.ServerWebSocket
import org.slf4j.LoggerFactory
import rt.vertx.server.ServiceClientFactory
import rt.plugin.service.IServiceClientFactory
import org.eclipse.xtend.lib.annotations.Accessors
import java.util.UUID
import rt.pipeline.pipe.PipeResource
import rt.pipeline.IMessageBus.Message
import rt.pipeline.pipe.IPipeChannel.PipeChannelInfo

class WsResource {
	static val logger = LoggerFactory.getLogger('WS-RESOURCE')
	
	@Accessors val String uuid
	@Accessors val PipeResource resource
	
	val WsRouter parent
	val ServerWebSocket ws
	val String client
	val (String) => void onClose
	
	package new(WsRouter parent, ServerWebSocket ws, String client, (String) => void onClose) {
		this.uuid = UUID.randomUUID.toString
		this.resource = parent.pipeline.createResource(client)
		
		this.parent = parent
		this.ws = ws
		this.client = client
		this.onClose = onClose
		
		val sb = new StringBuilder
		val srvClientFactory = new ServiceClientFactory(parent.pipeline.mb, client, ws.textHandlerID)
		this.resource  => [
			
			sendCallback = [ msg | this.send(msg) ]
			contextCallback = [ object(IServiceClientFactory, srvClientFactory) ]
			closeCallback = [ ws.close ]
			
			subscribe(client)
			
			parent.pipeline.mb.listener(client + '/ch:req')[ chReqMsg |
				val args = chReqMsg.args(PipeChannelInfo)
				val chInfo = args.get(0) as PipeChannelInfo
				println('CH-REQ-INTERCEPTED: ' + chInfo.uuid)
				
				//wait for channel bind and reply to service
				parent.waitForChannelBind(chInfo)[ channel |
					println('CH-BIND-INTERCEPTED: ' + chInfo.uuid)
					resource.addChannel(channel)
					
					val replyMsg = new Message => [ id=chReqMsg.id clt=chReqMsg.clt cmd=Message.CMD_OK result=channel ]
					parent.pipeline.mb.reply(replyMsg)
					
					//TODO: manage timeout!
				]
				
				//publish request to client
				chReqMsg.path = 'ch:srv'
				this.send(chReqMsg)
				//TODO: manage reject reply!
			]
		]
		
		ws.frameHandler[
			sb.append(textData)
			if (isFinal) {
				val textMsg = sb.toString
				logger.debug('RECEIVED {}', textMsg)
				
				val msg = parent.converter.fromJson(textMsg)
				sb.length = 0
				
				resource.process(msg)
			}
		]
		
		ws.closeHandler[
			resource.release
			onClose?.apply(uuid)
		]
	}
	
	private def void send(Message msg) {
		val textReply = parent.converter.toJson(msg)
		ws.writeFinalTextFrame(textReply)
		logger.debug('SENT {}', textReply)
	}
}