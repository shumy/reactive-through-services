package rt.vertx.server

import io.vertx.core.eventbus.EventBus
import io.vertx.core.eventbus.MessageConsumer
import rt.pipeline.IMessageBus

class VertxMessageBus implements IMessageBus {
	val EventBus eb
	val MessageConverter converter
	
	new(EventBus eb, MessageConverter converter) {
		this.eb = eb
		this.converter = converter
	}
	
	override publish(String address, Message msg) {
		val textMsg = converter.toJson(msg)
		
		println('''PUBLISH(«address») «textMsg»''')
		eb.publish(address, textMsg)
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