package rt.plugin.service.observable

import java.util.UUID
import rt.async.observable.Observable
import rt.pipeline.pipe.PipeContext
import rt.pipeline.bus.Message
import org.eclipse.xtend.lib.annotations.Accessors

class ObservableSkeleton {
	val Observable<?> obs
	val PipeContext ctx
	
	@Accessors val address = 'obs:' + UUID.randomUUID.toString
	
	new(Observable<?> obs, PipeContext ctx) {
		this.obs = obs
		this.ctx = ctx
	}
	
	def void process() {
		//deal with client signals
		ctx.resource.subscribe(address)[ msg |
			if (msg.cmd == Message.CMD_REQUEST) {
				obs.subscription.request(msg.result(Long))
			} else if (msg.cmd == Message.CMD_CANCEL) {
				ctx.resource.unsubscribe(address)
				obs.subscription.cancel
			}
		]
		
		obs.subscribe([ res |
			ctx.publish(new Message => [
				cmd = Message.CMD_OK
				path = address
				result = res
			])
		], [
			ctx.resource.unsubscribe(address)
			ctx.publish(new Message => [
				cmd = Message.CMD_COMPLETE
				path = address
			])
		], [ error |
			error.printStackTrace
			ctx.resource.unsubscribe(address)
			ctx.publish(new Message => [
				cmd = Message.CMD_OK
				path = address
				result = error
			])
		])
	}
}