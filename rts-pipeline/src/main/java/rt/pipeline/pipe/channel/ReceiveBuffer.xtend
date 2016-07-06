package rt.pipeline.pipe.channel

import java.nio.ByteBuffer
import java.nio.file.Paths
import java.nio.channels.FileChannel

class ReceiveBuffer implements IChannelBuffer {
	val ChannelPump pump
	
	var isSignalBegin = false
	var String signalName = null
	
	var String filePath = null
	var FileChannel fileChannel = null
	
	var (String) => void onBegin
	var () => void onEnd
	var (ByteBuffer) => void onData
	
	new(ChannelPump pump) {
		this.pump = pump
		
		pump.onSignal = [ msg |
			if (msg.startsWith('bng')) {
				if (isSignalBegin)
					throw new RuntimeException('Signal is already in begin status!')
				
				isSignalBegin = true
				signalName = msg.split(':').get(1)
				onBegin?.apply(signalName)
				if (filePath != null) openFile
			} else {
				if (!isSignalBegin)
					throw new RuntimeException('Signal is not in begin status!')
				
				isSignalBegin = false
				if (filePath != null) closeFile
				onEnd?.apply
			}
		]
		
		pump.onData = [ buffer |
			if (!isSignalBegin)
				throw new RuntimeException('Can not receive data with signal in end status!')
			
			if (filePath != null) {
				buffer.writeToFile
			} else {
				onData?.apply(buffer)
			}
		]
	}
	
	def onBegin((String) => void onBegin) { this.onBegin = onBegin }
	def onEnd(() => void onEnd) { this.onEnd = onEnd }
	
	def >>((ByteBuffer) => void onData) {
		this.onData = onData
	}
	
	def void writeToFile(String filePath) {
		this.filePath = filePath
	}

	private def void openFile() {
		val path = Paths.get(filePath)
		fileChannel = FileChannel.open(path)
	} 

	private def void writeToFile(ByteBuffer buffer) {
		fileChannel.write(buffer)
	}
	
	private def void closeFile() {
		fileChannel.close
	}
	
	static class ChannelPump {
		var (String) => void onSignal
		var (ByteBuffer) => void onData
		
		def void pushSignal(String signal) { onSignal.apply(signal) }
		def void pushData(ByteBuffer buffer) { onData.apply(buffer) }
	}
}