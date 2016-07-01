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
	
	def createResource(String client) {
		return new PipeResource(this, client, null, null)
	}
	
	def createResource(String client, (Message) => void sendCallback, () => void closeCallback) {
		return new PipeResource(this, client, sendCallback, closeCallback)
	}
	
	package def void process(PipeResource resource, Message msg) {
		val ctx = new PipeContext(this, resource, msg, interceptors.iterator)
		ctx.next
	}
	
	package def void process(PipeResource resource, Message msg, (PipeContext) => void onContextCreated) {
		val ctx = new PipeContext(this, resource, msg, interceptors.iterator)
		onContextCreated.apply(ctx)
		ctx.next
	}
	
	def fail(String error) {
		failHandler?.apply(error)
	}
	
	def void addInterceptor(IComponent interceptor) {
		interceptors.add(interceptor)
	}
	
	def getServiceFromPath(String path) {
		return services.get(path)
	}
	
	def getService(String address) {
		return services.get('srv:' + address)
	}
		
	def void addService(String address, IComponent service) {
		services.put('srv:' + address, service)
	}
	
	def void removeService(String address) {
		services.remove('srv:' + address)
	}
}