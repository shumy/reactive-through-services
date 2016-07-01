package rt.pipeline.pipe

import org.eclipse.xtend.lib.annotations.Accessors
import java.util.HashMap
import rt.pipeline.IMessageBus.Message
import rt.pipeline.IMessageBus.IListener
import org.slf4j.LoggerFactory

class PipeResource {
	static val logger = LoggerFactory.getLogger('RESOURCE')
	
	@Accessors val String client

	val Pipeline pipeline
	val subscriptions = new HashMap<String, IListener>
	
	val (Message) => void sendCallback
	val () => void closeCallback
		
	package new(Pipeline pipeline, String client, (Message) => void sendCallback, () => void closeCallback) {
		logger.debug('CREATE {}', client)
		this.pipeline = pipeline
		
		this.client = client
		
		this.sendCallback = sendCallback
		this.closeCallback = closeCallback
	}
	
	def void process(Message msg) {
		pipeline.process(this, msg)
	}
	
	def void process(Message msg, (PipeContext) => void onContextCreated) {
		pipeline.process(this, msg, onContextCreated)
	}
	
	def void send(Message msg) {
		sendCallback?.apply(msg)
	}

	def subscribe(String address) {
		if(subscriptions.containsKey(address))
			return false
		
		logger.debug('SUBSCRIBE {}', address)
		val listener = pipeline.mb.listener(address, sendCallback)
		
		subscriptions.put(address, listener)
		return true
	}
	
	def void unsubscribe(String address) {
		val listener = subscriptions.remove(address)
		if(listener != null) {
			logger.debug('UNSUBSCRIBE {}', address)
			listener.remove
		}
	}

	def void release() {
		logger.debug('RELEASE {}', client)
		subscriptions.values.forEach[ remove ]
		subscriptions.clear
	}
	
	def void disconnect() {
		closeCallback?.apply
	}
}