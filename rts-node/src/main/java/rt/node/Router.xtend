package rt.node

import rt.node.pipeline.Pipeline
import java.util.HashMap

abstract class Router {
	protected val routes = new HashMap<String, Pipeline>

	def void route(String path, Pipeline pipeline) {
		routes.put(path, pipeline)
	}
	
	abstract def void listen(int port)
}