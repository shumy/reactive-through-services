package rt.pipeline.pipe.channel

import java.nio.ByteBuffer
import java.nio.channels.FileChannel
import java.nio.file.Paths
import java.nio.file.StandardOpenOption
import org.slf4j.LoggerFactory

class SendBuffer implements IChannelBuffer {
	static val logger = LoggerFactory.getLogger(SendBuffer)
	
	val ChannelPump outPump
	val ChannelPump inPump
	
	var isSignalBegin = false
	var (String) => void onError
	
	new(ChannelPump outPump, ChannelPump inPump) {
		this.outPump = outPump
		this.inPump = inPump
		
		//process backward signal!
		inPump.onSignal = [
			logger.debug('SIGNAL {}', it)
			if (startsWith('err')) {
				val error = split(':').get(1)
				logger.error('ERROR {}', error)
				errorNoSignal(error)
			}
			//TODO: process timeout if no end signal received
		]
	}
	
	def void begin(String name) {
		if (isSignalBegin) {
			errorNoSignal('Signal is already in begin status!')
			return
		}
		
		isSignalBegin = true
		val signal = '''bng:«name»'''
		logger.debug('SIGNAL {}', signal)
		outPump.pushSignal(signal)
	}
	def void end() {
		if (!isSignalBegin) {
			errorNoSignal('Signal is not in begin status!')
			return
		}
		
		isSignalBegin = false
		val signal = 'end'
		logger.debug('SIGNAL {}', signal)
		outPump.pushSignal(signal)
		//TODO: process end reponse timeout? 
	}
	
	override onError((String) => void onError) { this.onError = onError }
	
	override error(String message) {
		errorNoSignal(message)
		outPump.pushSignal('''err:«message»''')
	}
	
	override close() {
		if (isSignalBegin)
			errorNoSignal('Irregular close!')
	}
	
	def <<(ByteBuffer buffer) {
		if (!isSignalBegin)
			throw new RuntimeException('Can not send data with signal in end status!')
		
		outPump.pushData(buffer)
	}
	
	def void sendFile(String filePath, int bufferSize) {
		//TODO: secure the filesystem path
		val path = Paths.get(filePath)
		
		val fileChannel = FileChannel.open(path, StandardOpenOption.READ)
		try {
			begin(filePath)
				val buffer = ByteBuffer.allocate(bufferSize)
				var position = fileChannel.read(buffer)
				while (position > 0) {
					buffer.flip
					outPump.pushData(buffer)
					
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
	
	private def void errorNoSignal(String message) {
		isSignalBegin = false
		logger.error('ERROR {}', message)
		onError?.apply(message)
	}
}