package rt.utils.service

import rt.async.AsyncUtils
import rt.async.pubsub.IPublisher
import rt.async.pubsub.IResource
import rt.data.Change
import rt.data.Data
import rt.data.Optional
import rt.data.Validation
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
	
	public static val String NEXT 		= 'ev:nxt'
	public static val String ERROR 		= 'ev:err'
	public static val String COMPLETE 	= 'ev:cpl'
	
	transient var IPublisher publisher
	
	val String address
	
	@Validation
	def void constructor() {
		publisher = AsyncUtils.publisher
	}
	
	def (Change) => void link() { return [ next ] }
	
	def void next(Object sData) {
		publisher.publish(address, SERVICE, NEXT, Event.B => [ address = this.address data = sData ])
	}
	
	def void error(String message) {
		publisher.publish(address, SERVICE, ERROR, Event.B => [ address = this.address data = message ])
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
