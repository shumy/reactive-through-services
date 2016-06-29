package rt.pipeline

import java.util.HashMap
import java.util.Set
import java.util.HashSet
import org.eclipse.xtend.lib.annotations.Accessors
import rt.pipeline.IMessageBus.Message

class DefaultMessageBus implements IMessageBus {
	@Accessors String defaultAddress
	val listeners = new HashMap<String, Set<DefaultListener>>
	
	override publish(Message msg) {
		publish(defaultAddress, msg)
	}
	
	override publish(String address, Message msg) {
		listeners.get(address)?.forEach[ send(msg) ]
	}
	
	override listener(String address, (Message) => void listener) {
		var holder = listeners.get(address)
		if (holder == null) {
			holder = new HashSet
			listeners.put(address, holder)
		}
		
		val dpfListener = new DefaultListener(this, address, listener)
		holder.add(dpfListener)
		
		return dpfListener
	}
	
	static class DefaultListener implements IListener {
		val DefaultMessageBus parent
		val String address
		val (Message) => void  callback
		
		package new(DefaultMessageBus parent, String address, (Message) => void callback) {
			this.parent = parent
			this.address = address
			this.callback = callback
		}
		
		def send(Message msg) {
			callback.apply(msg)
		}
		
		override remove() {
			val holder = parent.listeners.get(address)
			holder?.remove(address)
		}
	}
}