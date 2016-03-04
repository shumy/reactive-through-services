package rt.node.pipeline

import org.eclipse.xtend.lib.annotations.Accessors
import java.util.HashMap
import io.vertx.core.eventbus.MessageConsumer
import io.vertx.core.json.JsonObject

class PipeResource {
	@Accessors val String session
	@Accessors val String resource

	val Pipeline pipeline
	val subscriptions = new HashMap<String, MessageConsumer<JsonObject>>
	
	val (JsonObject) => void sendCallback
	val () => void closeCallback
		
	new(Pipeline pipeline, String session, String resource, (JsonObject) => void sendCallback, () => void closeCallback) {
		println('''OPEN( #«session»?«resource» )''')
		
		this.pipeline = pipeline

		this.session = session
		this.resource = resource
		
		this.sendCallback = sendCallback
		this.closeCallback = closeCallback
		
		subscribe(session)
	}
	
	def void process(JsonObject msg) {
		println('''PROCESS( #«session»?«resource» ) «msg»''')
		pipeline.process(this, new PipeMessage(msg))
	}
	
	def void reply(JsonObject msg) {
		println('''REPLY( #«session»?«resource» ) «msg»''')
		sendCallback.apply(msg)
	}

	def subscribe(String address) {
		if(subscriptions.containsKey(address))
			return false
		
		println('''SUBSCRIBE( #«session»?«resource» ) «address»''')
		val value = pipeline.registry.eb.consumer(address)[ msg |
			println('''SEND( #«session»?«resource» ) «msg.body»''')
			sendCallback.apply(msg.body)
		]
		
		subscriptions.put(address, value)
		return true
	}
	
	def void unsubscribe(String address) {
		val value = subscriptions.remove(address)
		if(value != null) {
			println('''UNSUBSCRIBE( #«session»?«resource» ) «address»''')
			value.unregister
		}
	}

	def void release() {
		println('''CLOSE( #«session»?«resource» )''')
		subscriptions.values.forEach[ unregister ]
		subscriptions.clear
	}
	
	def void disconnect() {
		closeCallback.apply
	}
}