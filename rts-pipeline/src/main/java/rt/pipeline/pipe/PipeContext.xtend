package rt.pipeline.pipe

import java.util.Iterator
import org.eclipse.xtend.lib.annotations.Accessors
import java.util.Map
import rt.pipeline.IMessageBus.Message
import rt.pipeline.IComponent

class PipeContext {
	@Accessors val Message message
	@Accessors val PipeResource resource

	boolean inFail = false
	
	val Pipeline pipeline
	val Iterator<IComponent> iter
	
	new(Pipeline pipeline, PipeResource resource, Message message, Iterator<IComponent> iter) {
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
			val srv = pipeline.getService(message.path)
			if(srv != null) {
				println("DELIVER(" + message.path + ")")
				try {
					srv.apply(this)
				} catch(RuntimeException ex) {
					ex.printStackTrace
					fail('''«ex.class.simpleName»: «ex.message»''')
				}
			} else {
				publish(message)
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
					fail('''«ex.class.simpleName»: «ex.message»''')
				}
			} else {
				deliver
			}
		}
	}

	/** Publish message to address in msg.to
	 * @param msg Should be a new message to publish
	 */
	def void publish(Message msg) {
		if(!inFail) {
			println("PUBLISH(" + msg.path + ")")
			pipeline.registry.mb.publish(msg.path, msg)
		}
	}

	/** Interrupts the pipeline flow and sends an error message back to the original "from". After this, other calls to "next()" or "fail(..)" are useless.
	 * @param from The address that will be on reply "header.from".
	 * @param error The error descriptor message.
	 */
	def void fail(String error) {
		if(!inFail) {
			replyError(error)
			pipeline.fail(error)
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
				client = message.client
			]
			
			resource.reply(reply)
		}
	}
	
	/** Does nothing to the pipeline flow and sends a OK reply back with a pre formatted JSON schema.  
	 */
	def void replyOK() {
		if(!inFail) {
			val reply = new Message => [
				cmd = Message.OK
			]
	
			reply(reply)
		}
	}
	
	/** Does nothing to the pipeline flow and sends a OK reply back with a pre formatted JSON schema.
	 * @param value The address that will be on "from".
	 */
	def void replyOK(Map<String, Object> resultObj) {
		if(!inFail) {
			val reply = new Message => [
				cmd = Message.OK
				result = resultObj
			]
	
			reply(reply)
		}
	}
	
	/** Does nothing to the pipeline flow and sends a ERROR reply back with a pre formatted JSON schema. 
	 * @param value The error descriptor message.
	 */
	def void replyError(String errorMsg) {
		if(!inFail) {
			val reply = new Message => [
				cmd = Message.ERROR
				error = errorMsg
			]
			
			reply(reply)
		}
	}
	
	/** Order the underlying resource channel to disconnect. But the client can be configured to reconnect, so most of the times a reconnection is made by the client.
	 * To avoid this, the method should only be used when the client orders the disconnection.
	 */
	def void disconnect() {
		resource.disconnect
	}
}