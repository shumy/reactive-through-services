package rt.pipeline.pipe.use

import rt.pipeline.IComponent
import rt.pipeline.pipe.PipeContext

class ValidatorInterceptor implements IComponent {

	override def getName() { return "hlr:validator" }

	override def apply(PipeContext ctx) {
		val msg = ctx.message

		if(msg.id == 0)
			ctx.fail("No mandatory field 'id'")
		
		if(msg.cmd == null)
			ctx.fail("No mandatory field 'cmd'")

		if(msg.client == null)
			ctx.fail("No mandatory field 'client'")

		if(msg.path == null)
			ctx.fail("No mandatory field 'path'")

		ctx.next
	}
}