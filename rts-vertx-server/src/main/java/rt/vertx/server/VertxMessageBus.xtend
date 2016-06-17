package rt.vertx.server

import io.vertx.core.eventbus.EventBus
import io.vertx.core.eventbus.MessageConsumer
import com.google.gson.Gson
import rt.pipeline.IMessageBus

class VertxMessageBus implements IMessageBus {
	val gson = new Gson
	val EventBus eb
	
	new(EventBus eb) {
		this.eb = eb
	}
	
	override publish(String address, Message msg) {
		val obj = gson.toJson(msg)
		eb.publish(address, obj)
	}
	
	override listener(String address, (Message) => void listener) {
		val consumer = eb.consumer(address) [
			val msg = gson.fromJson(body as String, Message)
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