package rt.pipeline.pipe.channel

import java.nio.file.Paths
import java.nio.channels.FileChannel
import java.nio.ByteBuffer
import java.nio.file.StandardOpenOption
import org.slf4j.LoggerFactory

class SendBuffer implements IChannelBuffer {
	static val logger = LoggerFactory.getLogger(SendBuffer)
	
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
		val signal = '''bng:«name»'''
		logger.debug('SIGNAL {}', signal)
		sendSignal.apply(signal)
	}
	def end() {
		if (!isSignalBegin)
			throw new RuntimeException('Signal is not in begin status!')
		
		isSignalBegin = false
		val signal = 'end'
		logger.debug('SIGNAL {}', signal)
		sendSignal.apply(signal)
	}

	def error(String message) {
		isSignalBegin = false
		val signal = '''err:«message»'''
		logger.error('SIGNAL {}', signal)
		sendSignal.apply(signal)
	}
	
	def <<(ByteBuffer buffer) {
		if (!isSignalBegin)
			throw new RuntimeException('Can not send data with signal in end status!')
		
		sendData.apply(buffer)
	}
	
	def void sendFile(String filePath, int bufferSize) {
		val path = Paths.get(filePath)
		
		val fileChannel = FileChannel.open(path, StandardOpenOption.READ)
		try {
			begin(filePath)
				val buffer = ByteBuffer.allocate(bufferSize)
				var position = fileChannel.read(buffer)
				while (position > 0) {
					buffer.flip
					sendData.apply(buffer)
					
					buffer.clear
					position = fileChannel.read(buffer)
				}
			end
		} catch(Exception ex) {
			error(ex.message)
		} finally {
			fileChannel.close
		}
	}
	
	def void sendFile(String filePath) {
		sendFile(filePath, 1024 * 1024)//default size to 1MB
	}
}