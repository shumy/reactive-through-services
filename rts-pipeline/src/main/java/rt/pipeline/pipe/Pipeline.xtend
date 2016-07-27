package rt.pipeline.pipe

import java.util.ArrayList
import java.util.HashMap
import org.eclipse.xtend.lib.annotations.Accessors
import rt.pipeline.DefaultMessageBus
import rt.pipeline.IComponent
import rt.pipeline.IMessageBus
import rt.pipeline.IMessageBus.Message
import rt.pipeline.pipe.use.ChannelService

class Pipeline {
	@Accessors val IMessageBus mb
	@Accessors(PUBLIC_SETTER) (Throwable) => void failHandler = null
	
	val interceptors = new ArrayList<IComponent>
	val services = new HashMap<String, IComponent>
	
	new() { this(new DefaultMessageBus) }
	new(IMessageBus mb) {
		this.mb = mb
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
	
	def createResource(String client) {
		return new PipeResource(this, client)
	}
	
	def fail(Throwable ex) {
		failHandler?.apply(ex)
	}
	
	def void addInterceptor(IComponent interceptor) {
		interceptors.add(interceptor)
	}
	
	def void addChannelService(IComponent chService) {
		services.put(ChannelService.name, chService)
	}
	
	def getComponentPaths() {
		return services.keySet
	}
	
	def getComponent(String path) {
		return services.get(path)
	}
	
	def addComponent(String path, IComponent component) {
		services.put(path, component)
	}
	
	def void removeComponent(String path) {
		services.remove(path)
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