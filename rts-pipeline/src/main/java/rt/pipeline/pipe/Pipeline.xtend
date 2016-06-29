package rt.pipeline.pipe

import java.util.ArrayList
import org.eclipse.xtend.lib.annotations.Accessors
import java.util.HashMap
import rt.pipeline.IComponent
import rt.pipeline.IMessageBus.Message
import rt.pipeline.IMessageBus
import rt.pipeline.DefaultMessageBus

class Pipeline {
	@Accessors val IMessageBus mb
	@Accessors(PUBLIC_SETTER) (String) => void failHandler = null
	
	val interceptors = new ArrayList<IComponent>
	val services = new HashMap<String, IComponent>
	
	new() { this(new DefaultMessageBus) }
	new(IMessageBus mb) {
		this.mb = mb
	}
	
	def void process(PipeResource resource, Message msg) {
		val ctx = new PipeContext(this, resource, msg, interceptors.iterator)
		ctx.next
	}
	
	def createResource(String client, String resource, (Message) => void sendCallback, () => void closeCallback) {
		return new PipeResource(this, client, resource, sendCallback, closeCallback)
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