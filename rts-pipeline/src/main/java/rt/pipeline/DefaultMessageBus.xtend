package rt.pipeline

import java.util.HashMap
import java.util.HashSet
import java.util.Set
import java.util.concurrent.ConcurrentHashMap
import rt.pipeline.promise.AsyncUtils

class DefaultMessageBus implements IMessageBus {
	val listeners = new HashMap<String, Set<DefaultListener>>
	val replyListeners = new ConcurrentHashMap<String, (Message) => void>
	
	
	override publish(String address, Message msg) {
		if (msg.typ != null) msg.typ = Message.PUBLISH
		listeners.get(address)?.forEach[ send(msg) ]
	}
	
	override send(String address, Message msg, (Message) => void replyCallback) {
		val replyID = msg.replyID
		replyListener(replyID, replyCallback)
		
		msg.typ = Message.SEND
		listeners.get(address)?.forEach[ send(msg) ]
		
		AsyncUtils.timer(3000)[
			val replyTimeoutMsg = new Message => [ id=msg.id clt=msg.clt typ=Message.REPLY cmd=Message.CMD_TIMEOUT result='''Timeout for «msg.path» -> «msg.cmd»'''.toString]
			replyTimeoutMsg.reply
		]
	}
	
	override reply(Message msg) {
		val replyID = msg.replyID
		
		val replyOKBackFun = replyListeners.remove(replyID + '/reply-ok')
		val replyERRORBackFun = replyListeners.remove(replyID + '/reply-error')
		
		//process backward replies. In case of internal components need the information
		if (msg.cmd == Message.CMD_OK) {
			replyOKBackFun?.apply(msg)	
		} else {
			replyERRORBackFun?.apply(msg)
		}
		
		val replyFun = replyListeners.remove(replyID)
		replyFun?.apply(msg)
	}
	
	override replyListener(String replyID, (Message) => void listener) {
		replyListeners.put(replyID, listener)
	}
	
	override listener(String address, (Message) => void listener) {
		var holder = listeners.get(address)
		if (holder == null) {
			holder = new HashSet
			listeners.put(address, holder)
		}
		
		val rtsListener = new DefaultListener(this, address, listener)
		holder.add(rtsListener)
		
		return rtsListener
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
			holder?.remove(this)
		}
	}
}