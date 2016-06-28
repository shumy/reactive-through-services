package rt.pipeline

import java.util.HashMap

class DefaultMessageBus implements IMessageBus {
	val listeners = new HashMap<String, DefaultListener>
	
	override publish(String address, Message msg) {
		listeners.get(address)?.send(msg)
	}
	
	override listener(String address, (Message)=>void listener) {
		val dpfListener = new DefaultListener(this, address, listener)
		listeners.put(address, dpfListener)
		return dpfListener
	}
	
	static class DefaultListener implements IListener {
		val DefaultMessageBus parent
		val String address
		val (Message)=>void  callback
		
		package new(DefaultMessageBus parent, String address, (Message)=>void callback) {
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