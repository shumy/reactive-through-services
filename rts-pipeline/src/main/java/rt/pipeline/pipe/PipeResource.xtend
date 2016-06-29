package rt.pipeline.pipe

import org.eclipse.xtend.lib.annotations.Accessors
import java.util.HashMap
import rt.pipeline.IMessageBus.Message
import rt.pipeline.IMessageBus.IListener

class PipeResource {
	@Accessors val String client
	@Accessors val String resource

	val Pipeline pipeline
	val subscriptions = new HashMap<String, IListener>
	
	val (Message) => void sendCallback
	val () => void closeCallback
		
	package new(Pipeline pipeline, String client, String resource, (Message) => void sendCallback, () => void closeCallback) {
		this.pipeline = pipeline

		this.client = client
		this.resource = resource
		
		this.sendCallback = sendCallback
		this.closeCallback = closeCallback
	}
	
	def void process(Message msg) {
		pipeline.process(this, msg)
	}
	
	def void send(Message msg) {
		sendCallback.apply(msg)
	}

	def subscribe(String address) {
		if(subscriptions.containsKey(address))
			return false
		
		println('''SUBSCRIBE( #«client»?«resource» ) «address»''')
		val listener = pipeline.mb.listener(address)[ msg |
			sendCallback.apply(msg)
		]
		
		subscriptions.put(address, listener)
		return true
	}
	
	def void unsubscribe(String address) {
		val listener = subscriptions.remove(address)
		if(listener != null) {
			println('''UNSUBSCRIBE( #«client»?«resource» ) «address»''')
			listener.remove
		}
	}

	def void release() {
		subscriptions.values.forEach[ remove ]
		subscriptions.clear
	}
	
	def void disconnect() {
		closeCallback.apply
	}
}