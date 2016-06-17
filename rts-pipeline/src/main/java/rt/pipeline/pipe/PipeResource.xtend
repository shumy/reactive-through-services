package rt.pipeline.pipe

import org.eclipse.xtend.lib.annotations.Accessors
import java.util.HashMap
import rt.pipeline.IMessageBus.Message
import rt.pipeline.IMessageBus.IListener

class PipeResource {
	@Accessors val String session
	@Accessors val String resource

	val Pipeline pipeline
	val subscriptions = new HashMap<String, IListener>
	
	val (Message) => void sendCallback
	val () => void closeCallback
		
	new(Pipeline pipeline, String session, String resource, (Message) => void sendCallback, () => void closeCallback) {
		println('''OPEN( #«session»?«resource» )''')
		
		this.pipeline = pipeline

		this.session = session
		this.resource = resource
		
		this.sendCallback = sendCallback
		this.closeCallback = closeCallback
		
		subscribe(session)
	}
	
	def void process(Message msg) {
		println('''PROCESS( #«session»?«resource» ) «msg»''')
		pipeline.process(this, msg)
	}
	
	def void reply(Message msg) {
		println('''REPLY( #«session»?«resource» ) «msg»''')
		sendCallback.apply(msg)
	}

	def subscribe(String address) {
		if(subscriptions.containsKey(address))
			return false
		
		println('''SUBSCRIBE( #«session»?«resource» ) «address»''')
		val listener = pipeline.registry.mb.listener(address)[ msg |
			println('''SEND( #«session»?«resource» ) «msg»''')
			sendCallback.apply(msg)
		]
		
		subscriptions.put(address, listener)
		return true
	}
	
	def void unsubscribe(String address) {
		val listener = subscriptions.remove(address)
		if(listener != null) {
			println('''UNSUBSCRIBE( #«session»?«resource» ) «address»''')
			listener.remove
		}
	}

	def void release() {
		println('''CLOSE( #«session»?«resource» )''')
		subscriptions.values.forEach[ remove ]
		subscriptions.clear
	}
	
	def void disconnect() {
		closeCallback.apply
	}
}