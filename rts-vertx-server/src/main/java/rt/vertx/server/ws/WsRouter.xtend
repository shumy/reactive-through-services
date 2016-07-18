package rt.vertx.server.ws

import io.vertx.core.http.HttpServer
import java.util.HashMap
import org.eclipse.xtend.lib.annotations.Accessors
import org.slf4j.LoggerFactory
import rt.pipeline.DefaultMessageConverter
import rt.pipeline.pipe.Pipeline
import rt.pipeline.pipe.channel.IPipeChannel
import rt.pipeline.pipe.channel.IPipeChannel.PipeChannelInfo

import static extension rt.vertx.server.web.URIParserHelper.*

class WsRouter {
	static val logger = LoggerFactory.getLogger('WS-ROUTER')
	
	@Accessors val resources = new HashMap<String, WsResource>
	
	package val converter = new DefaultMessageConverter
	package val String route
	package val HttpServer server
	package val Pipeline pipeline
	
	var (WsResource) => void onOpen = null
	var (String) => void onClose = null
	
	//channels info...
	val chRequests = new HashMap<String, PipeChannelInfo>
	val chRequestsHandlers = new HashMap<String, (IPipeChannel) => void>
	
	new(String route, HttpServer server, Pipeline pipeline) {
		this.route = route
		this.server = server
		this.pipeline = pipeline
		
		server.websocketHandler[ ws |
			if (ws.uri.route != route) {
				logger.error('Invalid route for uri: {}', ws.uri)
				ws.close return
			}
			
			val clientUUID = ws.query.queryParams.get('client')
			if (clientUUID == null) {
				logger.error('Invalid client UUID: NULL')
				ws.close return
			}
			
			logger.debug('CLIENT {}', clientUUID)
			val channelUUID = ws.query.queryParams.get('channel')
			if (channelUUID != null) {
				logger.debug('CHANNEL {}', channelUUID)
				
				val chInfo = chRequests.remove(channelUUID)
				val chBindHandler = chRequestsHandlers.remove(channelUUID)
				if (chInfo == null || chBindHandler == null) {
					logger.error('CHANNEL - No request bind for channel: {}', channelUUID)
					ws.close return
				}
				
				val wsResource = resources.get(clientUUID)
				if (wsResource == null) {
					logger.error('CHANNEL - No resource for client: {}', clientUUID)
					ws.close return
				}
				
				chBindHandler.apply(new WsPipeChannel(wsResource.resource, chInfo, ws))
			} else {
				if (resources.get(clientUUID) != null) {
					logger.error('Invalid client UUID: Already exists - {}', clientUUID)
					ws.close return
				}
				
				val wsResource = new WsResource(this, ws, clientUUID)[ removeResource ]
				addResource(wsResource)
			}
		]
	}
	
	def void onOpen((WsResource) => void callback) { onOpen = callback }
	def void onClose((String) => void callback) { onClose = callback }
	
	package def void waitForChannelBind(PipeChannelInfo info, (IPipeChannel) => void onBind) {
		chRequests.put(info.uuid, info)
		chRequestsHandlers.put(info.uuid, onBind)
	}
	
	package def void forgetChannelBind(PipeChannelInfo info) {
		chRequests.remove(info.uuid)
		chRequestsHandlers.remove(info.uuid)
	}
	
	private def void addResource(WsResource resource) {
		resources.put(resource.client, resource)
		onOpen?.apply(resource)
	}
	
	private def void removeResource(String clientUUID) {
		resources.remove(clientUUID)
		onClose?.apply(clientUUID)
	}
}