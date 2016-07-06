package rt.pipeline.pipe.use

import rt.pipeline.IComponent
import rt.pipeline.pipe.PipeContext
import rt.pipeline.pipe.IPipeChannel.PipeChannelInfo
import rt.pipeline.IMessageBus.Message
import org.eclipse.xtend.lib.annotations.Accessors
import rt.pipeline.pipe.IPipeChannelReceiver

abstract class ChannelService implements IComponent {
	@Accessors static val name = 'ch:srv'
	
	override apply(PipeContext ctx) {
		val chMsg = ctx.message
		
		if (chMsg.cmd == 'request') {
			val args = chMsg.args(PipeChannelInfo)
			val chInfo = args.get(0) as PipeChannelInfo
			
			val replyMsg = new Message => [ id=chMsg.id clt=chMsg.clt ]
			try {
				request(chInfo)
				replyMsg => [ cmd=Message.CMD_OK result=chInfo]
			} catch(Exception ex) {
				replyMsg => [ cmd=Message.CMD_ERROR result=ex.message ]
			}
			
			ctx.bus.publish(ctx.resource.client + '/ch:rpl', replyMsg)
		} else if (chMsg.cmd == 'bind') {
			val channel = chMsg.result(IPipeChannelReceiver)
			bind(channel)
		}
	}
	
	abstract def void request(PipeChannelInfo chInfo)
	abstract def void bind(IPipeChannelReceiver channel)
}