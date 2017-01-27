package rt.pipeline.pipe

import java.util.ArrayList
import java.util.HashMap
import java.util.HashSet
import java.util.Map
import org.eclipse.xtend.lib.annotations.Accessors
import rt.pipeline.IComponent
import rt.pipeline.IResource
import rt.pipeline.bus.DefaultMessageBus
import rt.pipeline.bus.IMessageBus
import rt.pipeline.bus.IPublisher
import rt.pipeline.bus.Message

class Pipeline {
	@Accessors val IMessageBus mb
	@Accessors(PUBLIC_SETTER) (Throwable) => void failHandler = null
	
	val interceptors = new ArrayList<IComponent>
	
	val services = new HashMap<String, IComponent>
	package val serviceAuthorizations = new HashMap<String, Map<String, String>>
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
	
	
	def getComponentPaths() {
		return services.keySet
	}
	
	def getComponent(String path) {
		return services.get(path)
	}
	
	def void addComponent(String path, IComponent component) {
		addComponent(path, component, #{ 'all' -> 'all' })
	}
	
	def void addComponent(String path, IComponent component, Map<String, String> authorizations) {
		services.put(path, component)
		serviceAuthorizations.put(path, authorizations)
	}
	
	def removeComponent(String path) {
		val cmp = services.remove(path)
		serviceAuthorizations.remove(cmp)
		return cmp
	}
	
	
	def getService(String address) {
		return services.get('srv:' + address)
	}
	
	def void addService(String address, IComponent service) {
		addService(address, service, false)
	}
	
	def void addService(String address, IComponent service, Map<String, String> authorizations) {
		addService(address, service, false, authorizations)
	}
	
	def void addService(String address, IComponent service, boolean asContext) {
		addService(address, service, asContext, #{ 'all' -> 'all' })
	}

	def void addService(String address, IComponent service, boolean asContext, Map<String, String> authorizations) {
		val srvAddress = 'srv:' + address
		addComponent(srvAddress, service, authorizations)
		
		if (asContext) ctxServices.add(service)
	}
	
	def void removeService(String address) {
		val srvAddress = 'srv:' + address
		val srv = removeComponent(srvAddress)
		
		ctxServices.remove(srv)
	}
	
	def addAuthorization(String path, String cmd, String group) {
		var auths = serviceAuthorizations.get(path)
		if (auths === null) {
			auths = new HashMap<String, String>
			serviceAuthorizations.put(path, auths)
		}
		
		auths.put(cmd, group)
	}
}