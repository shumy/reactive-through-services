package rt.pipeline.pipe

import java.util.HashMap
import java.util.Iterator
import org.eclipse.xtend.lib.annotations.Accessors
import org.slf4j.LoggerFactory
import rt.pipeline.IComponent
import rt.pipeline.bus.IMessageBus
import rt.pipeline.bus.Message
import java.util.Set

class PipeContext {
	static val logger = LoggerFactory.getLogger('PIPELINE')
	
	@Accessors val Message message
	@Accessors val PipeResource resource
	
	boolean inFail = false
	
	val Pipeline pipeline
	val Iterator<IComponent> iter
	val objects = new HashMap<Class<?>, Object>
	
	def IMessageBus bus() { return pipeline.mb }
	
	def object(Class<?> type, Object instance) { objects.put(type, instance) }
	def <T> T object(Class<T> type) { return objects.get(type) as T }
	
	package new(Pipeline pipeline, PipeResource resource, Message message, Iterator<IComponent> iter) {
		this.pipeline = pipeline
		this.resource = resource
		this.message = message
		this.iter = iter
	}
	
	/** Sends the context to the delivery destination. Normally this methods is called in the end of the pipeline process.
	 *  So most of the time there is no need to call this.
	 */
	def void deliver() {
		if(!inFail) {
			try {
				if (message.typ == Message.REPLY)
					deliverReply
				else
					deliverRequest
				
			} catch(RuntimeException ex) {
				ex.printStackTrace
				if (message.typ != Message.PUBLISH) fail(ex)
			}
		}
	}

	/** Used by interceptors, order the pipeline to execute the next interceptor. If no other interceptor exits, a delivery is proceed.
	 */
	def void next() {
		if(!inFail) {
			if(iter.hasNext) {
				try {
					iter.next.apply(this)
				} catch(RuntimeException ex) {
					ex.printStackTrace
					fail(ex)
				}
			} else {
				deliver
			}
		}
	}
	
	/** Send a message to the client resource
	 * @param msg Should be a new message to send
	 */
	def void send(Message msg) {
		if(!inFail) {
			resource.send(msg)
		}
	}

	/** Interrupts the pipeline flow and sends an error message back to the original "from". After this, other calls to "next()" or "fail(..)" are useless.
	 * @param from The address that will be on reply "header.from".
	 * @param error The error descriptor message.
	 */
	def void fail(Throwable ex) {
		if(!inFail) {
			replyError(ex)
			pipeline.fail(ex)
			inFail = true
		}
	}

	/** Does nothing to the pipeline flow and sends a reply back.
	 * @param reply Should be a new PipeMessage
	 */
	def void reply(Message reply) {
		if(!inFail) {
			reply => [
				id = message.id
				clt = message.clt
				typ = Message.REPLY
			]
			
			resource.send(reply)
		}
	}
	
	/** Does nothing to the pipeline flow and sends a OK reply back with a pre formatted JSON schema.  
	 */
	def void replyOK() {
		if(!inFail) {
			val reply = new Message => [
				cmd = Message.CMD_OK
			]
	
			reply(reply)
		}
	}
	
	/** Does nothing to the pipeline flow and sends a OK reply back with a pre formatted JSON schema.
	 * @param value The address that will be on "from".
	 */
	def void replyOK(Object resultObj) {
		if(!inFail) {
			val reply = new Message => [
				cmd = Message.CMD_OK
				result = resultObj
			]
			
			reply(reply)
		}
	}
	
	def void replyObservable(String address) {
		if(!inFail) {
			val reply = new Message => [
				cmd = Message.CMD_OBSERVABLE
				result = address
			]
	
			reply(reply)
		}
	}
	
	/** Does nothing to the pipeline flow and sends a ERROR reply back with a pre formatted JSON schema. 
	 * @param value The error descriptor message.
	 */
	def void replyError(Throwable ex) {
		if(!inFail) {
			val reply = new Message => [
				cmd = Message.CMD_ERROR
				result = ex
			]
			
			logger.error('REPLY-ERROR {}', ex)
			reply(reply)
		}
	}
	
	
	def void publish(Message pub) {
		if(!inFail) {
			pub => [
				clt = message.clt
				typ = Message.PUBLISH
			]
			
			resource.send(pub)
		}
	}
	
	/** Order the underlying resource channel to disconnect. But the client can be configured to reconnect, so most of the times a reconnection is made by the client.
	 * To avoid this, the method should only be used when the client orders the disconnection.
	 */
	def void disconnect() {
		resource.disconnect
	}
	
	def boolean isAuthorized(Message msg, Set<String> groups) {
		val auth = pipeline.serviceAuthorizations.get(msg.path)
		if (auth === null) return false
		
		val allGroup = auth.get('all')
		if (allGroup !== null) {
			if (allGroup == 'all') return true
			
			return groups.contains(allGroup)
		}
		
		val methGroup = auth.get(msg.cmd)
		if (methGroup !== null) {
			if (methGroup == 'all') return true
			
			return groups.contains(methGroup)
		}
		
		return false
	}
	
	private def void deliverRequest() {
		val srv = pipeline.getComponent(message.path)
		if(srv != null) {
			logger.debug('DELIVER {}', message.path)
			srv.apply(this)
		} else {
			logger.info('PUBLISH {}', message.path)
			pipeline.mb.publish(message.path, message)
		}
	}
	
	private def void deliverReply() {
		logger.debug('DELIVER-REPLY {} {}', message.clt, message.id)
		pipeline.mb.reply(message)
	}
}