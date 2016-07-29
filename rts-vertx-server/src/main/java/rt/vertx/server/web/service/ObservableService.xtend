package rt.vertx.server.web.service

import java.util.HashMap
import java.util.UUID
import rt.data.Data
import rt.plugin.service.an.Public
import rt.plugin.service.an.Service
import rt.plugin.service.an.ServiceProxy
import rt.data.Optional

interface EventsInterface {
	@Public(notif = true)
	def void event(Event event)
}

@ServiceProxy(EventsInterface)
interface EventsProxy {}

@Service
@Data(metadata = false)
class ObserverService {
	transient val observers = new HashMap<String, RemoteObserver>
	
	//only used internally from other services
	def RemoteObserver register(EventsProxy eventsProxy) {
		val uuid = UUID.randomUUID.toString
		val ro = RemoteObserver.B => [ id = uuid proxy = eventsProxy ]
		
		observers.put(uuid, ro)
		return ro
	}
	
	@Public
	def void unregister(String uuid) {
		observers.remove(uuid)
	}
}

@Data(metadata = false)
class RemoteObserver {
	val String id
	val EventsProxy proxy
	
	def void next(Object sData) {
		proxy.event(Event.B => [ uuid = id type = Event.NEXT event = sData])
	}
	
	def void complete() {
		proxy.event(Event.B => [ uuid = id type = Event.COMPLETE ])
	}
}

@Data(metadata = false)
class Event {
	public static val String NEXT 		= 'nxt'
	public static val String COMPLETE 	= 'clp'
	
	val String uuid
	val String type
	@Optional val Object event
}

@Data(metadata = false)
class Change {
	public static val String ADD 		= 'add'
	public static val String UPDATE 	= 'upd'
	public static val String REMOVE 	= 'rem'
	
	val String oper
	val Object data
}
