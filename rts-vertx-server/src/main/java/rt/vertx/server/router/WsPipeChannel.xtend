package rt.vertx.server.router

import io.netty.buffer.Unpooled
import io.vertx.core.buffer.Buffer
import io.vertx.core.http.ServerWebSocket
import org.eclipse.xtend.lib.annotations.Accessors
import org.slf4j.LoggerFactory
import rt.pipeline.pipe.PipeResource
import rt.pipeline.pipe.channel.IChannelBuffer
import rt.pipeline.pipe.channel.IPipeChannel
import rt.pipeline.pipe.channel.ReceiveBuffer
import rt.pipeline.pipe.channel.ReceiveBuffer.ChannelPump
import rt.pipeline.pipe.channel.SendBuffer

import static rt.pipeline.pipe.channel.IPipeChannel.PipeChannelInfo.Type.*

class WsPipeChannel implements IPipeChannel {
	static val logger = LoggerFactory.getLogger('WS-CHANNEL')
	
	@Accessors val PipeResource resource
	@Accessors val PipeChannelInfo info
	@Accessors val String status
	@Accessors val IChannelBuffer buffer
	
	val ServerWebSocket ws
	
	package new(PipeResource resource, PipeChannelInfo info, ServerWebSocket ws) {
		this.resource = resource
		this.info = info
		this.status = 'INIT'
		
		this.ws = ws
		ws.closeHandler[
			logger.trace('CLOSE {}', info.uuid)
			resource.removeChannel(info.uuid)
		]
		
		this.buffer = if (info.type == SENDER) senderSetup else receiverSetup
	}
	
	override close() { ws?.close }
	
	
	private def IChannelBuffer senderSetup() {
		return new SendBuffer([ ws.writeFinalTextFrame(it) ], [
			val buffer = Buffer.buffer(Unpooled.copiedBuffer(it))
			ws.writeBinaryMessage(buffer)
		])
	}
	
	private def IChannelBuffer receiverSetup() {
		//TODO: how to use drain and pump
		val pump = new ChannelPump
		ws.frameHandler[ msg |
			if (msg.binary) {
				val buffer = msg.binaryData.byteBuf.nioBuffer
				println('P: ' + buffer.position + ' L: ' + buffer.limit)
				//TODO: do I need to flip the buffer?
				pump.pushData(buffer)
			} else {
				pump.pushSignal(msg.textData)
			}
		]
		
		return new ReceiveBuffer(pump)
	}
}