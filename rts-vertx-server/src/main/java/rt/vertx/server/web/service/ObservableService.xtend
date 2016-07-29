package rt.vertx.server.web.service

import java.util.UUID
import rt.data.Data
import rt.plugin.service.an.Proxy
import rt.plugin.service.an.Public
import rt.plugin.service.an.Service
import rt.plugin.service.an.ServiceProxy
import java.util.HashMap
import rt.data.Validation
import rt.pipeline.promise.AsyncUtils

interface EventsInterface {
	@Public(notif = true)
	def void event(ChangeEvent change)
}

@ServiceProxy(EventsInterface)
interface EventsProxy {}

@Service(metadata = false)
@Data(metadata = false)
class ObservableService {
	transient val observers = new HashMap<String, Observer>
	
	@Public
	@Proxy(name = 'events', type = EventsProxy)
	def String register() {
		val uuid = UUID.randomUUID.toString
		observers.put(uuid, Observer.B => [ id = uuid proxy = events ])
		return uuid
	}
	
	@Public
	def void unregister(String uuid) {
		observers.remove(uuid)
	}
}

@Data(metadata = false)
class ChangeEvent {
	public static val String ADD 		= 'add'
	public static val String UPDATE 	= 'upd'
	public static val String REMOVE 	= 'rem'
	
	val String type
	val String uuid
	val Object data
}

@Data(metadata = false)
class Observer {
	val String id
	val EventsProxy proxy
	
	@Validation
	def void construct() {
		AsyncUtils.periodic(5000)[
			proxy.event(ChangeEvent.B => [
				type = ChangeEvent.ADD
				uuid = id
				data = #{ 'x' -> Math.random, 'y' -> Math.random }
			])
		]
	}
}
