package rt.pipeline.pipe.use

import rt.pipeline.IComponent
import rt.pipeline.pipe.PipeContext
import rt.pipeline.pipe.IPipeChannel.PipeChannelInfo
import rt.pipeline.IMessageBus.Message
import org.eclipse.xtend.lib.annotations.Accessors

abstract class ChannelService implements IComponent {
	@Accessors val name = 'ch:srv'
	
	override apply(PipeContext ctx) {
		val chReqMsg = ctx.message
		
		val args = chReqMsg.args(PipeChannelInfo)
		val chInfo = args.get(0) as PipeChannelInfo
		println('CHANNEL-REQUEST: ' + chInfo.uuid)
		
		val replyMsg = new Message => [ id=chReqMsg.id clt=chReqMsg.clt ]
		try {
			request(chInfo)
			replyMsg => [ cmd=Message.CMD_OK result=chInfo]
		} catch(Exception ex) {
			replyMsg => [ cmd=Message.CMD_ERROR result=ex.message ]
		}
		
		ctx.bus.publish(ctx.resource.client + '/ch:rpl', replyMsg)
	}
	
	abstract def void request(PipeChannelInfo chInfo)
}