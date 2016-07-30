package rt.pipeline.pipe

import java.util.ArrayList
import java.util.HashMap
import org.eclipse.xtend.lib.annotations.Accessors
import rt.async.pubsub.IMessageBus
import rt.async.pubsub.Message
import rt.pipeline.DefaultMessageBus
import rt.pipeline.IComponent
import rt.pipeline.pipe.use.ChannelService
import rt.async.pubsub.IPublisher
import rt.async.pubsub.IResource
import java.util.HashSet

class Pipeline {
	@Accessors val IMessageBus mb
	@Accessors(PUBLIC_SETTER) (Throwable) => void failHandler = null
	
	val interceptors = new ArrayList<IComponent>
	val services = new HashMap<String, IComponent>
	val ctxServices = new HashSet<IComponent>
	
	new() { this(new DefaultMessageBus) }
	new(IMessageBus mb) {
		this.mb = mb
	}
	
	package def void process(PipeResource resource, Message msg) {
		resource.process(msg, null)
	}
	
	package def void process(PipeResource resource, Message msg, (PipeContext) => void onContextCreated) {
		val ctx = new PipeContext(this, resource, msg, interceptors.iterator)
		onContextCreated?.apply(ctx)
		
		ctx => [
			object(IPublisher, mb)
			object(IResource, resource)
			for (ctxSrv: ctxServices)
				object(ctxSrv.class, ctxSrv)
			
			next
		]
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
		addService(address, service, false)
	}
	
	def void addService(String address, IComponent service, boolean asContext) {
		if (asContext)
			ctxServices.add(service)
			
		services.put('srv:' + address, service)
	}
	
	def void removeService(String address) {
		val srv = services.remove('srv:' + address)
		ctxServices.remove(srv)
	}
}