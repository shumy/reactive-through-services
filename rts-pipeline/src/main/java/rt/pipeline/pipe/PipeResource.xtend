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
		println('''RESOURCE-CREATE(«client», «resource»)''')
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
		
		println('''RESOURCE-SUBSCRIBE(«resource») «address»''')
		val listener = pipeline.mb.listener(address, sendCallback)
		
		subscriptions.put(address, listener)
		return true
	}
	
	def void unsubscribe(String address) {
		val listener = subscriptions.remove(address)
		if(listener != null) {
			println('''RESOURCE-UNSUBSCRIBE(«resource») «address»''')
			listener.remove
		}
	}

	def void release() {
		println('''RESOURCE-RELEASE(«resource»)''')
		subscriptions.values.forEach[ remove ]
		subscriptions.clear
	}
	
	def void disconnect() {
		closeCallback.apply
	}
}