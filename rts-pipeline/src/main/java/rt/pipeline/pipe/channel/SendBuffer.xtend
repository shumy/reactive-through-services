package rt.pipeline.pipe.channel

import java.nio.file.Paths
import java.nio.channels.FileChannel
import java.nio.ByteBuffer

class SendBuffer implements IChannelBuffer {
	
	var isSignalBegin = false
	val (String) => void sendSignal
	val (ByteBuffer) => void sendData
	
	new((String) => void sendSignal, (ByteBuffer) => void sendData) {
		this.sendSignal = sendSignal
		this.sendData = sendData
	}
	
	def begin(String name) {
		if (isSignalBegin)
			throw new RuntimeException('Signal is already in begin status!')
			
		isSignalBegin = true
		sendSignal.apply('''bng:«name»''')
	}
	def end() {
		if (!isSignalBegin)
			throw new RuntimeException('Signal is not in begin status!')
		
		isSignalBegin = false
		sendSignal.apply('''end''')
	}
	
	def <<(ByteBuffer buffer) {
		if (!isSignalBegin)
			throw new RuntimeException('Can not send data with signal in end status!')
		
		sendData.apply(buffer)
	}
	
	def sendFile(String filePath) {
		val path = Paths.get(filePath)
		
		val fileChannel = FileChannel.open(path)
		try {
			begin(filePath)
				val buffer = ByteBuffer.allocateDirect(1024) //set to 1KB
				var position = fileChannel.read(buffer)
				while (position > 0) {
					sendData.apply(buffer)
					buffer.clear
					position = fileChannel.read(buffer, position)
				}
			end	
		} finally {
			fileChannel.close
		}
	}
}