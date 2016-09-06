package rt.pipeline

import java.util.HashMap
import java.util.HashSet
import java.util.Set
import java.util.concurrent.ConcurrentHashMap
import org.eclipse.xtend.lib.annotations.Accessors
import rt.async.pubsub.IMessageBus
import rt.async.pubsub.IObserver
import rt.async.pubsub.ISubscription
import rt.async.pubsub.Message

import static rt.async.AsyncUtils.*
import org.slf4j.LoggerFactory

class DefaultMessageBus implements IMessageBus {
	static val logger = LoggerFactory.getLogger('BUS')
	
	val subscriptions = new HashMap<String, Set<DefaultSubscription>>
	val replyListeners = new ConcurrentHashMap<String, (Message) => void>
	
	val observers = new HashMap<String, IObserver>
	
	override publish(String address, String inCmd, Object inResult) {
		publish(address, address, inCmd, inResult)
	}
	
	override publish(String address, String inPath, String inCmd, Object inResult) {
		val msg = new Message => [ typ = Message.PUBLISH path = 'srv:' + inPath cmd = inCmd result = inResult ]
		subscriptions.get(address)?.forEach[ send(msg) ]
	}
	
	override publish(String address, Message msg) {
		if (msg.typ != null) msg.typ = Message.PUBLISH
		subscriptions.get(address)?.forEach[ send(msg) ]
	}
	
	override send(String address, Message msg, (Message) => void replyCallback) {
		val replyID = msg.replyID
		replyListener(replyID, replyCallback)
		
		msg.typ = Message.SEND
		subscriptions.get(address)?.forEach[ send(msg) ]
		
		timeout[
			val replyTimeoutMsg = new Message => [
				id=msg.id clt=msg.clt typ=Message.REPLY cmd=Message.CMD_TIMEOUT
				result=new RuntimeException('''Timeout for «msg.path» -> «msg.cmd»''')
			]
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
	
	override subscribe(String address, (Message) => void listener) {
		logger.info('SUBSCRIBE {}', address)
		var holder = subscriptions.get(address)
		if (holder == null) {
			holder = new HashSet
			subscriptions.put(address, holder)
			observers.get(address)?.onCreate(address)
		}
		
		val sub = new DefaultSubscription(this, address, listener)
		holder.add(sub)
		
		return sub
	}
	
	override addObserver(String address, IObserver observer) {
		observers.put(address, observer)
	}
	
	static class DefaultSubscription implements ISubscription {
		@Accessors val String address
		
		val DefaultMessageBus parent
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
			logger.info('UNSUBSCRIBE {}', address)
			val holder = parent.subscriptions.get(address)
			if (holder != null) {
				holder.remove(this)
				
				if (holder.size == 0) {
					parent.observers.get(address)?.onDestroy(address)
					parent.subscriptions.remove(address)
				}	
			}
		}
	}
}