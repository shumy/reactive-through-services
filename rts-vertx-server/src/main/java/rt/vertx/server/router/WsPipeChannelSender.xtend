package rt.vertx.server.router

import io.vertx.core.http.ServerWebSocket
import org.eclipse.xtend.lib.annotations.Accessors
import io.vertx.core.buffer.Buffer
import rt.pipeline.pipe.IPipeChannelSender

class WsPipeChannelSender implements IPipeChannelSender {
	@Accessors val PipeChannelInfo info
	@Accessors val String status
	
	val WsRouter parent
	val ServerWebSocket ws
	//val (String) => void onClose
	
	package new(WsRouter parent, ServerWebSocket ws, PipeChannelInfo info) {
		this.parent = parent
		this.ws = ws
		this.info = info
		
		this.status = 'INIT'
		
		ws.closeHandler[
			println('SERVER-CHANNEL-CLOSE')
			//TODO: release channel on resource?
			//onClose?.apply(uuid)
		]
		
	}
	
	override send(byte[] data) {
		val buffer = Buffer.factory.buffer(data)
		ws.writeFinalBinaryFrame(buffer)
	}
	
	override close() {
		ws?.close
	}
	
}