package rt.vertx.server

import rt.plugin.service.IServiceClientFactory
import rt.plugin.service.ServiceClient
import rt.pipeline.IMessageBus

class ServiceClientFactory implements IServiceClientFactory {
	val IMessageBus bus
	val String server
	val String client
	
	new(IMessageBus bus, String server, String client) {
		this.bus = bus
		this.server = server
		this.client = client
	}
	
	override createServiceClient() {
		return new ServiceClient(bus, server, client)
	}
}