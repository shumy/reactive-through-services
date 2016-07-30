package rt.vertx.server.web.service

import java.util.HashMap
import java.util.UUID
import rt.async.pubsub.IPublisher
import rt.async.pubsub.IResource
import rt.data.Data
import rt.data.Optional
import rt.plugin.service.an.Context
import rt.plugin.service.an.Public
import rt.plugin.service.an.Service

@Service
@Data(metadata = false)
class ObserverService {
	transient val observers = new HashMap<String, RemoteSubscriber>
	
	val IPublisher publisher
	
	//only used internally from other services
	def RemoteSubscriber register() {
		val uuid = UUID.randomUUID.toString
		val ro = RemoteSubscriber.B => [ id = uuid publisher = this.publisher ]
		
		observers.put(uuid, ro)
		return ro
	}
	
	@Public
	@Context(name = 'resource', type = IResource)
	def void unregister(String uuid) {
		observers.remove(uuid)
	}
}

@Data(metadata = false)
class RemoteSubscriber {
	public static val String ADDRESS 	= 'events'
	
	public static val String NEXT 		= 'nxt'
	public static val String COMPLETE 	= 'clp'
	
	val String id
	val IPublisher publisher
	
	def void next(Object sData) {
		publisher.publish(ADDRESS, NEXT, Event.B => [ uuid = id data = sData ])
	}
	
	def void complete() {
		publisher.publish(ADDRESS, COMPLETE, Event.B => [ uuid = id ])
	}
}

@Data(metadata = false)
class Event {
	val String uuid
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
