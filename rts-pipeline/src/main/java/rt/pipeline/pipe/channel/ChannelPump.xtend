package rt.pipeline.pipe.channel

import java.nio.ByteBuffer
import rt.pipeline.pipe.channel.ChannelBuffer.Signal

class ChannelPump {
	public var (Signal) => void onSignal
	public var (ByteBuffer) => void onData
	public var () => boolean isReady
	
	def void pushSignal(Signal signal) { onSignal.apply(signal) }
	def void pushData(ByteBuffer buffer) { onData.apply(buffer) }
	def boolean isReady() { if(isReady == null) true else isReady.apply }
}