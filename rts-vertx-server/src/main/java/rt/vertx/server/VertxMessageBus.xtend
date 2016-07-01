package rt.vertx.server

import io.vertx.core.eventbus.EventBus
import io.vertx.core.eventbus.MessageConsumer
import rt.pipeline.IMessageBus
import rt.pipeline.IMessageBus.Message
import rt.pipeline.DefaultMessageConverter

//TODO: not working
class VertxMessageBus implements IMessageBus {
	val converter = new DefaultMessageConverter
	
	val EventBus eb
	
	new(EventBus eb) {
		this.eb = eb
	}
	
	
	override publish(String address, Message msg) {
		val textMsg = converter.toJson(msg)
		
		println('''PUBLISH(«address») «textMsg»''')
		eb.publish(address, textMsg)
	}
	
	override send(String address, Message msg, (Message)=>void replyCallback) {
		val replyID = '''«msg.clt»+«msg.id»'''
		
		this.listener(replyID, replyCallback)
		
		//TODO: how to handle timeout?
		this.publish(address, msg)
	}
	
	override listener(String address, (Message) => void listener) {
		val consumer = eb.consumer(address) [
			val msg = converter.fromJson(body as String)
			listener.apply(msg)
		]

		return new VertxListener(consumer)
	}
	
	static class VertxListener implements IListener {
		val MessageConsumer<Object> consumer
		
		new(MessageConsumer<Object> consumer) {
			this.consumer = consumer
		}
		
		override remove() {
			consumer.unregister
		}
	}
}