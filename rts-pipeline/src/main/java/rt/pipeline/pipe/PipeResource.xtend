package rt.pipeline.pipe

import java.util.HashMap
import org.eclipse.xtend.lib.annotations.Accessors
import org.slf4j.LoggerFactory
import rt.pipeline.IResource
import rt.pipeline.bus.IMessageBus
import rt.pipeline.bus.ISubscription
import rt.pipeline.bus.Message
import rt.pipeline.pipe.channel.IPipeChannel

class PipeResource implements IResource {
	static val logger = LoggerFactory.getLogger('RESOURCE')
	
	@Accessors val String client
	@Accessors var (Message) => void sendCallback
	@Accessors var (PipeContext) => void contextCallback
	@Accessors var () => void closeCallback
	
	val Pipeline pipeline
	val subscriptions = new HashMap<String, ISubscription>
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
	
	override subscribe(String address) {
		subscribe(address, sendCallback)
	}
	
	override subscribe(String address, (Message)=>void listener) {
		if(subscriptions.containsKey(address)) return;
		
		val sub = pipeline.mb.subscribe(address, listener)
		subscriptions.put(address, sub)
	}
	
	override unsubscribe(String address) {
		val listener = subscriptions.remove(address)
		listener?.remove
	}
	
	override send(Message msg) {
		sendCallback?.apply(msg)
	}
	
	override disconnect() {
		closeCallback?.apply
	}
	
	def void process(Message msg) {
		if (contextCallback != null)
			pipeline.process(this, msg, contextCallback)
		else
			pipeline.process(this, msg)
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
}