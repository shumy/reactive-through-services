package rt.vertx.server.ws

import io.netty.buffer.Unpooled
import io.vertx.core.buffer.Buffer
import io.vertx.core.http.ServerWebSocket
import org.eclipse.xtend.lib.annotations.Accessors
import org.slf4j.LoggerFactory
import rt.pipeline.pipe.PipeResource
import rt.pipeline.pipe.channel.ChannelBuffer
import rt.pipeline.pipe.channel.ChannelBuffer.Signal
import rt.pipeline.pipe.channel.ChannelPump
import rt.pipeline.pipe.channel.IPipeChannel
import rt.pipeline.pipe.channel.ReceiveBuffer
import rt.pipeline.pipe.channel.SendBuffer

import static rt.pipeline.pipe.channel.IPipeChannel.PipeChannelInfo.Type.*

class WsPipeChannel implements IPipeChannel {
	static val logger = LoggerFactory.getLogger('WS-CHANNEL')
	
	@Accessors val PipeResource resource
	@Accessors val PipeChannelInfo info
	@Accessors(PUBLIC_GETTER) var ChannelBuffer buffer
	@Accessors val String status
	
	val ServerWebSocket ws
	
	package new(PipeResource resource, PipeChannelInfo info, ServerWebSocket ws) {
		logger.trace('OPEN {}', info.uuid)
		
		this.resource = resource
		this.info = info
		this.status = 'INIT'
		
		val inPump = new ChannelPump
		val outPump = new ChannelPump => [
			isReady = [ !ws.writeQueueFull ]
			onSignal = [
				if (ws.writeQueueFull) logger.error('Send queue is full!')
				ws.writeFinalTextFrame(toString)
			]
			onData = [
				if (ws.writeQueueFull) logger.error('Send queue is full!')
				val buffer = Buffer.buffer(Unpooled.wrappedBuffer(it))
				ws.writeFinalBinaryFrame(buffer)
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
				inPump.pushData(buffer)
			} else {
				inPump.pushSignal(Signal.process(textData))
			}
		]
		
		this.buffer = if (info.type == SENDER) new SendBuffer(outPump, inPump) else new ReceiveBuffer(inPump, outPump)
	}
	
	override close() { ws.close }
}