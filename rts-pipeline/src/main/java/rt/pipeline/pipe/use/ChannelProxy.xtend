package rt.pipeline.pipe.use

import rt.pipeline.pipe.IPipeChannel.PipeChannelInfo
import rt.pipeline.IMessageBus.Message
import rt.pipeline.IMessageBus
import rt.pipeline.promise.Promise
import rt.pipeline.promise.PromiseResult
import rt.pipeline.pipe.IPipeChannelSender

class ChannelProxy {
	val IMessageBus bus
	val String server
	
	val String uuid
	var long msgID = 100
	
	new(IMessageBus bus, String server, String uuid) {
		this.bus = bus
		this.server = server
		this.uuid = uuid
	}
	
	def Promise<IPipeChannelSender> requestChannel(PipeChannelInfo chInfo) {
		val PromiseResult<IPipeChannelSender> result = [ resolve, reject |
			msgID++
			val chReqMsg = new Message => [ id=msgID clt=uuid args=#[chInfo] ]
			
			bus.send(server + '/ch:req', chReqMsg)[ replyMsg |
				println('CHANNEL-PROXY-REPLY')
				if (replyMsg.cmd == Message.CMD_OK) {
					resolve.apply(replyMsg.result(IPipeChannelSender))
				} else {
					reject.apply(replyMsg.result(String))
				}
			]
		] 
		
		return result.promise
	}
}