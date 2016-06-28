package rt.plugin.service.test

import rt.pipeline.IMessageBus
import rt.pipeline.IMessageBus.Message
import java.util.HashMap

class MessageBus implements IMessageBus {
	val listeners = new HashMap<String, Listener>
	
	override publish(String address, Message msg) {
		listeners.get(address)?.send(msg)
	}
	
	override listener(String address, (Message)=>void listener) {
		val dpfListener = new Listener(this, address, listener)
		listeners.put(address, dpfListener)
		return dpfListener
	}
	
	static class Listener implements IListener {
		val MessageBus parent
		val String address
		val (Message)=>void  callback
		
		new(MessageBus parent, String address, (Message)=>void callback) {
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