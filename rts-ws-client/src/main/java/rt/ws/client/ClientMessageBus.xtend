package rt.ws.client

import rt.pipeline.IMessageBus
import rt.pipeline.IMessageBus.Message
import java.util.HashMap

class ClientMessageBus implements IMessageBus {
	val listeners = new HashMap<String, ClientListener>
	
	override publish(String address, Message msg) {
		listeners.get(address)?.send(msg)
	}
	
	override listener(String address, (Message)=>void listener) {
		val dpfListener = new ClientListener(this, address, listener)
		listeners.put(address, dpfListener)
		return dpfListener
	}
	
	static class ClientListener implements IListener {
		val ClientMessageBus parent
		val String address
		val (Message)=>void  callback
		
		new(ClientMessageBus parent, String address, (Message)=>void callback) {
			this.parent = parent
			this.address = address
			this.callback = callback
		}
		
		def send(Message msg) {
			callback.apply(msg)
		}
		
		override remove() {
			parent.listeners.remove(address)
		}
		
	}
	
}