package rt.pipeline.pipe

import java.util.ArrayList
import org.eclipse.xtend.lib.annotations.Accessors
import java.util.HashMap
import rt.pipeline.Registry
import rt.pipeline.IComponent
import rt.pipeline.IMessageBus.Message

class Pipeline {
	@Accessors val Registry registry
	@Accessors(PUBLIC_SETTER) (String) => void failHandler = null
	
	val interceptors = new ArrayList<IComponent>
	val services = new HashMap<String, IComponent>
	
	def void process(PipeResource resource, Message msg) {
		val ctx = new PipeContext(this, resource, msg, interceptors.iterator)
		ctx.next
	}
	
	new(Registry registry) {
		this.registry = registry
	}
	
	def createResource(String session, String resource, (Message) => void sendCallback, () => void closeCallback) {
		return new PipeResource(this, session, resource, sendCallback, closeCallback)
	}
	
	def fail(String error) {
		if(failHandler != null)
			failHandler.apply(error)
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