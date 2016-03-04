package rt.node.pipeline

import java.util.ArrayList
import io.vertx.core.Handler
import org.eclipse.xtend.lib.annotations.Accessors
import rt.node.Registry
import java.util.HashMap
import rt.node.IComponent
import io.vertx.core.json.JsonObject

class Pipeline {
	@Accessors val Registry registry
	@Accessors(PUBLIC_SETTER) Handler<String> failHandler = null
	
	val interceptors = new ArrayList<IComponent>
	val services = new HashMap<String, IComponent>
	
	def void process(PipeResource resource, PipeMessage msg) {
		val ctx = new PipeContext(this, resource, msg, interceptors.iterator)
		ctx.next
	}
	
	new(Registry registry) {
		this.registry = registry
	}
	
	def createResource(String session, String resource, (JsonObject) => void sendCallback, () => void closeCallback) {
		return new PipeResource(this, session, resource, sendCallback, closeCallback)
	}
	
	def fail(String error) {
		if(failHandler != null)
			failHandler.handle(error)
	}
	
	def void addInterceptor(IComponent interceptor) {
		interceptors.add(interceptor)
	}
	
	def getService(String name) {
		return services.get(name)
	}
		
	def void addService(IComponent service) {
		services.put(service.name, service)
	}
	
	def void removeService(IComponent service) {
		services.remove(service.name)
	}
}