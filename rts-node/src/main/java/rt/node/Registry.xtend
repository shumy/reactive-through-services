package rt.node

import io.vertx.core.Vertx
import org.eclipse.xtend.lib.annotations.Accessors
import io.vertx.core.eventbus.EventBus
import rt.node.pipeline.Pipeline

class Registry {
	@Accessors val String domain
	@Accessors val EventBus eb

	new(String domain, Vertx vertx) {
		this.domain = domain
		this.eb = vertx.eventBus
	}
	
	def createPipeline() {
		return new Pipeline(this)
	}
}