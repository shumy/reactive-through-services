package rt.vertx.server.router

import io.vertx.core.http.ServerWebSocket
import org.eclipse.xtend.lib.annotations.Accessors
import io.vertx.core.buffer.Buffer
import rt.pipeline.pipe.IPipeChannelSender
import rt.pipeline.pipe.PipeResource
import org.slf4j.LoggerFactory

class WsPipeChannelSender implements IPipeChannelSender {
	static val logger = LoggerFactory.getLogger('WS-CHANNEL-SENDER')
	
	@Accessors val PipeResource resource
	@Accessors val PipeChannelInfo info
	@Accessors val String status
	
	val ServerWebSocket ws
	
	package new(PipeResource resource, PipeChannelInfo info, ServerWebSocket ws) {
		this.resource = resource
		this.info = info
		this.status = 'INIT'
		
		this.ws = ws
		ws.closeHandler[
			logger.trace('CLOSE')
			resource.removeChannel(info.uuid)
		]
	}
	
	override send(byte[] data) {
		val buffer = Buffer.factory.buffer(data)
		ws.writeFinalBinaryFrame(buffer)
	}
	
	override close() { ws?.close }
}