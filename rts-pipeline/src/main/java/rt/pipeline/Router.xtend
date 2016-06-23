package rt.pipeline

import java.util.HashMap
import rt.pipeline.pipe.Pipeline

abstract class Router {
	protected val routes = new HashMap<String, Pipeline>

	def void route(String path, Pipeline pipeline) {
		routes.put(path, pipeline)
	}
}