package rt.vertx.server.service

import rt.async.pubsub.IPublisher
import rt.async.pubsub.IResource
import rt.data.Data
import rt.data.Optional
import rt.plugin.service.an.Context
import rt.plugin.service.an.Public
import rt.plugin.service.an.Service

@Service
@Data(metadata = false)
class SubscriberService {
	
	@Public
	@Context(name = 'resource', type = IResource)
	def void subscribe(String address) {
		resource.subscribe(address)
	}
	
	@Public
	@Context(name = 'resource', type = IResource)
	def void unsubscribe(String address) {
		resource.unsubscribe(address)
	}
}

@Data(metadata = false)
class RemoteSubscriber {
	public static val String SERVICE 	= 'events'
	
	public static val String NEXT 		= 'nxt'
	public static val String COMPLETE 	= 'clp'
	
	val String address
	val IPublisher publisher
	
	def void next(Object sData) {
		publisher.publish(address, SERVICE, NEXT, Event.B => [ address = this.address data = sData ])
	}
	
	def void complete() {
		publisher.publish(address, SERVICE, COMPLETE, Event.B => [ address = this.address ])
	}
}

@Data(metadata = false)
class Event {
	val String address
	@Optional val Object data
}

@Data(metadata = false)
class Change {
	public static val String ADD 		= 'add'
	public static val String UPDATE 	= 'upd'
	public static val String REMOVE 	= 'rem'
	
	val String oper
	val Object data
}
