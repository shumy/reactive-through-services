package rt.pipeline.pipe.channel

import java.nio.ByteBuffer

class ChannelPump {
	public var (String) => void onSignal
	public var (ByteBuffer) => void onData
	public var () => boolean isReady
	
	def void pushSignal(String signal) { onSignal.apply(signal) }
	def void pushData(ByteBuffer buffer) { onData.apply(buffer) }
	def boolean isReady() { if(isReady == null) true else isReady.apply }
}