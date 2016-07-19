package rt.vertx.server.web.processor

import java.util.Map
import rt.pipeline.IMessageBus.Message
import rt.plugin.service.RouteProcessor
import rt.plugin.service.RouteConfig
import rt.pipeline.DefaultMessageConverter
import java.nio.ByteBuffer

class HttpRouteProcessor implements RouteProcessor {
	val converter = new DefaultMessageConverter
	
	var long msgID = 0
	
	override request(RouteConfig config, Map<String, Object> params) {
		msgID++
		
		val rawParams = config.paramMaps.map[ params.get(it) ]
		val argsConverter = converter.createArgsConverter(rawParams)
		
		//TODO: do I need a client?
		return new Message(argsConverter, null) => [
			id = msgID
			typ = Message.SEND
			cmd = config.srvMethod
			path = 'srv:' + config.srvAddress
		]
	}
	
	override response(Message msg) {
		val res = msg.result(Object)
		if (res.class == String || res instanceof ByteBuffer)
			return res
		
		return converter.toJson(res)
	}
	
}