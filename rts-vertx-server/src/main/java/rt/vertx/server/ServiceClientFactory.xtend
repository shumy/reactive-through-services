package rt.vertx.server

import java.util.HashMap
import java.util.Map
import org.eclipse.xtend.lib.annotations.Accessors
import rt.pipeline.IResourceProvider
import rt.pipeline.bus.IMessageBus
import rt.plugin.service.IServiceClientFactory
import rt.plugin.service.ServiceClient

class ServiceClientFactory implements IServiceClientFactory {
	@Accessors val ServiceClient serviceClient
	@Accessors val Map<String, String> redirects = new HashMap
	
	new(IResourceProvider ctxProvider, IMessageBus bus, String server, String client) {
		this.serviceClient = new ServiceClient(ctxProvider, bus, server, client, redirects)
	}
}