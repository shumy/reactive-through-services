package rt.vertx.server

import rt.plugin.service.IServiceClientFactory
import rt.plugin.service.ServiceClient
import rt.pipeline.IMessageBus
import org.eclipse.xtend.lib.annotations.Accessors

class ServiceClientFactory implements IServiceClientFactory {
	@Accessors val ServiceClient serviceClient
	
	val IMessageBus bus
	val String server
	val String client
	
	new(IMessageBus bus, String server, String client) {
		this.bus = bus
		this.server = server
		this.client = client
		
		this.serviceClient = new ServiceClient(bus, server, client)
	}
}