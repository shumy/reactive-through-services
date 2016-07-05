package rt.vertx.server.router

import io.vertx.core.http.HttpServer
import rt.pipeline.DefaultMessageConverter
import org.slf4j.LoggerFactory
import rt.pipeline.pipe.Pipeline
import java.util.HashMap
import static extension rt.vertx.server.URIParserHelper.*
import rt.pipeline.pipe.PipeResource
import rt.pipeline.pipe.IPipeChannel.PipeChannelInfo
import org.eclipse.xtend.lib.annotations.Accessors
import rt.pipeline.pipe.IPipeChannelSender

class WsRouter {
	static val logger = LoggerFactory.getLogger('WS-ROUTER')
	
	@Accessors val resources = new HashMap<String, PipeResource>
	
	package val converter = new DefaultMessageConverter
	package val String route
	package val HttpServer server
	package val Pipeline pipeline
	
	//channels info...
	val chRequests = new HashMap<String, PipeChannelInfo>
	val chRequestsHandlers = new HashMap<String, (IPipeChannelSender) => void>
	
	new(String route, HttpServer server, Pipeline pipeline) {
		this.route = route
		this.server = server
		this.pipeline = pipeline
		
		server.websocketHandler[ ws |
			if (ws.uri.route != route) {
				ws.close return
			}
			
			val channelUUID = ws.query.queryParams.get('channel')
			
			if (channelUUID != null) {
				logger.debug('CHANNEL {}', channelUUID)
				
				val chInfo = chRequests.remove(channelUUID)
				val chBindHandler = chRequestsHandlers.remove(channelUUID)
				if (chInfo == null || chBindHandler == null) {
					logger.info('CHANNEL - no request bind for channel {}', channelUUID)
					ws.close return
				}
				
				val channel = new WsPipeChannelSender(this, ws, chInfo)
				chBindHandler.apply(channel)
				
			} else {
				val clientID = ws.query.queryParams.get('client')
				logger.debug('CLIENT {}', clientID)
				if (clientID == null) {
					ws.close return
				}
				
				val wsResource = new WsResource(this, ws, clientID)[ resources.remove(it) ]
				resources.put(wsResource.uuid, wsResource.resource)
			}
		]
	}
	
	package def void waitForChannelBind(PipeChannelInfo info, (IPipeChannelSender) => void onBind) {
		chRequests.put(info.uuid, info)
		chRequestsHandlers.put(info.uuid, onBind)
	}
	
	package def void forgetChannelBind(PipeChannelInfo info) {
		chRequests.remove(info.uuid)
		chRequestsHandlers.remove(info.uuid)
	}  
}