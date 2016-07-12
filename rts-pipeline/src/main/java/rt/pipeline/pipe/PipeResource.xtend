package rt.pipeline.pipe

import org.eclipse.xtend.lib.annotations.Accessors
import java.util.HashMap
import rt.pipeline.IMessageBus.Message
import rt.pipeline.IMessageBus.IListener
import org.slf4j.LoggerFactory
import rt.pipeline.IMessageBus
import rt.pipeline.pipe.channel.IPipeChannel

class PipeResource {
	static val logger = LoggerFactory.getLogger('RESOURCE')
	
	@Accessors val String client
	@Accessors var (Message) => void sendCallback
	@Accessors var (PipeContext) => void contextCallback
	@Accessors var () => void closeCallback
	
	val Pipeline pipeline
	val subscriptions = new HashMap<String, IListener>
	val channels = new HashMap<String, IPipeChannel>
	val objects = new HashMap<Class<?>, Object>
	
	def IMessageBus bus() { return pipeline.mb }
	
	def object(Class<?> type, Object instance) { objects.put(type, instance) }
	def <T> T object(Class<T> type) { return objects.get(type) as T }
	
	package new(Pipeline pipeline, String client) {
		logger.debug('CREATE {}', client)
		this.pipeline = pipeline
		
		this.client = client
	}
	
	def void process(Message msg) {
		if (contextCallback != null)
			pipeline.process(this, msg, contextCallback)
		else
			pipeline.process(this, msg)
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
	
	def void addChannel(IPipeChannel channel) {
		channels.put(channel.info.uuid, channel)
	}
	
	def removeChannel(String uuid) {
		return channels.remove(uuid)
	}
	
	def void release() {
		logger.debug('RELEASE {}', client)
		
		subscriptions.values.forEach[ remove ]
		subscriptions.clear
		
		channels.values.forEach[ close ]
		channels.clear
	}
	
	def void disconnect() {
		closeCallback?.apply
	}
}