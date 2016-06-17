package rt.node

import org.eclipse.xtend.lib.annotations.Accessors
import rt.node.pipeline.Pipeline

class Registry {
	@Accessors val String domain
	@Accessors val IMessageBus mb

	new(String domain, IMessageBus mb) {
		this.domain = domain
		this.mb = mb
	}
	
	def createPipeline() {
		return new Pipeline(this)
	}
}