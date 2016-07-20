package rt.pipeline.pipe.use

import rt.pipeline.IComponent
import rt.pipeline.pipe.PipeContext

class ValidatorInterceptor implements IComponent {
	
	override def apply(PipeContext ctx) {
		val msg = ctx.message
		
		if(msg.id == 0)
			ctx.fail(new RuntimeException("No mandatory field 'id'"))
		
		if(msg.cmd == null)
			ctx.fail(new RuntimeException("No mandatory field 'cmd'"))
		
		if(msg.clt == null)
			ctx.fail(new RuntimeException("No mandatory field 'client'"))
		
		if(msg.path == null)
			ctx.fail(new RuntimeException("No mandatory field 'path'"))
		
		ctx.next
	}
}