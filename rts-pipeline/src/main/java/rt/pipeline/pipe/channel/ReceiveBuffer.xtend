package rt.pipeline.pipe.channel

import java.nio.ByteBuffer
import java.nio.file.Paths
import java.nio.channels.FileChannel
import java.nio.file.StandardOpenOption
import org.slf4j.LoggerFactory

class ReceiveBuffer implements IChannelBuffer {
	static val logger = LoggerFactory.getLogger(ReceiveBuffer)
	
	val ChannelPump pump
	
	var isSignalBegin = false
	var String filePath = null
	var FileChannel fileChannel = null
	
	var (String) => void onBegin
	var () => void onEnd
	var (String) => void onError
	var (ByteBuffer) => void onData
	
	new(ChannelPump pump) {
		this.pump = pump
		
		pump.onSignal = [ signal |
			if (signal.startsWith('bng')) {
				logger.debug('SIGNAL {}', signal)
				if (isSignalBegin) {
					val error = 'Signal is already in begin status!'
					logger.error(error)
					
					closeFile
					onError?.apply(error)
					return
				}
				
				isSignalBegin = true
				val signalName = signal.split(':').get(1)
				onBegin?.apply(signalName)
				if (filePath != null) createFile
			} else if (signal.startsWith('end')) {
				logger.debug('SIGNAL {}', signal)
				if (!isSignalBegin) {
					val error = 'Signal is not in begin status!'
					logger.error(error)
					
					closeFile
					onError?.apply(error)
					return
				}
				
				closeFile
				onEnd?.apply
			} else {
				logger.error('SIGNAL {}', signal)
				val error = signal.split(':').get(1)
				
				//process error...
				closeFile
				onError?.apply(error)
			}
		]
		
		pump.onData = [ buffer |
			if (!isSignalBegin) {
				val error = 'Can not receive data with signal in end status!'
				logger.error(error)
				
				closeFile
				onError?.apply(error)
				return
			}
			
			if (filePath != null) {
				buffer.writeToFile
			} else {
				onData?.apply(buffer)
			}
		]
	}
	
	def onBegin((String) => void onBegin) { this.onBegin = onBegin }
	def onEnd(() => void onEnd) { this.onEnd = onEnd }
	def onError((String) => void onError) { this.onError = onError }
	
	def >>((ByteBuffer) => void onData) {
		this.onData = onData
	}
	
	def void writeToFile(String filePath) {
		this.filePath = filePath
	}

	private def void createFile() {
		try {
			val path = Paths.get(filePath)
			fileChannel = FileChannel.open(path, StandardOpenOption.CREATE_NEW, StandardOpenOption.WRITE)	
		} catch(Exception ex) {
			logger.error(ex.message)
			
			closeFile
			//TODO: sen backward error to the SendBuffer!
			onError?.apply(ex.message)
		}
	} 

	private def void writeToFile(ByteBuffer buffer) {
		fileChannel.write(buffer)
	}
	
	private def void closeFile() {
		isSignalBegin = false
		fileChannel?.close
		
		filePath = null
		fileChannel = null
	}
	
	static class ChannelPump {
		var (String) => void onSignal
		var (ByteBuffer) => void onData
		
		def void pushSignal(String signal) { onSignal.apply(signal) }
		def void pushData(ByteBuffer buffer) { onData.apply(buffer) }
	}
}