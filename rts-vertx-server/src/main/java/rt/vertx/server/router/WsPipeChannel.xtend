package rt.vertx.server.router

import io.netty.buffer.Unpooled
import io.vertx.core.buffer.Buffer
import io.vertx.core.http.ServerWebSocket
import org.eclipse.xtend.lib.annotations.Accessors
import org.slf4j.LoggerFactory
import rt.pipeline.pipe.PipeResource
import rt.pipeline.pipe.channel.ChannelPump
import rt.pipeline.pipe.channel.IChannelBuffer
import rt.pipeline.pipe.channel.IPipeChannel
import rt.pipeline.pipe.channel.ReceiveBuffer
import rt.pipeline.pipe.channel.SendBuffer

import static rt.pipeline.pipe.channel.IPipeChannel.PipeChannelInfo.Type.*

class WsPipeChannel implements IPipeChannel {
	static val logger = LoggerFactory.getLogger('WS-CHANNEL')
	
	@Accessors val PipeResource resource
	@Accessors val PipeChannelInfo info
	@Accessors(PUBLIC_GETTER) var IChannelBuffer buffer
	@Accessors val String status
	
	val ServerWebSocket ws
	
	package new(PipeResource resource, PipeChannelInfo info, ServerWebSocket ws) {
		logger.trace('OPEN {}', info.uuid)
		
		this.resource = resource
		this.info = info
		this.status = 'INIT'
		
		val inPump = new ChannelPump
		val outPump = new ChannelPump => [
			onSignal = [ ws.writeFinalTextFrame(it) ]
			onData = [
				val buffer = Buffer.buffer(Unpooled.copiedBuffer(it))
				ws.writeBinaryMessage(buffer)
			]
		]
		
		this.ws = ws
		ws.closeHandler[
			logger.trace('CLOSE {}', info.uuid)
			resource.removeChannel(info.uuid)
			buffer.close
		]
		
		ws.frameHandler[
			if (binary) {
				val buffer = binaryData.byteBuf.nioBuffer
				println('P: ' + buffer.position + ' L: ' + buffer.limit)
				//TODO: do I need to flip the buffer?
				inPump.pushData(buffer)
			} else {
				inPump.pushSignal(textData)
			}
		]
		
		this.buffer = if (info.type == SENDER) new SendBuffer(outPump, inPump) else new ReceiveBuffer(inPump, outPump)
	}
	
	override close() { ws.close }
}