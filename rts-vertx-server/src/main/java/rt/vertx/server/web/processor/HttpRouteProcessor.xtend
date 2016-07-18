package rt.vertx.server.web.processor

import com.google.gson.Gson
import java.util.Map
import rt.pipeline.IMessageBus.Message
import rt.plugin.service.RouteProcessor
import rt.plugin.service.RouteConfig

class HttpRouteProcessor implements RouteProcessor {
	val gson = new Gson
	var long msgID = 0
	
	override request(RouteConfig srvRoute, Map<String, Object> params) {
		msgID++
		
		//TODO: do I need a client?
		return new Message => [
			id = msgID
			cmd = srvRoute.srvMethod
			path = 'srv:' + srvRoute.srvAddress
			args = srvRoute.paramMaps.map[ params.get(it) ]
		]
	}
	
	override response(Message msg) {
		return gson.toJson(msg.result(Object))
	}
	
}