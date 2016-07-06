package rt.pipeline.pipe.channel

import java.nio.ByteBuffer
import java.nio.channels.FileChannel
import java.nio.file.Paths
import java.nio.file.StandardOpenOption
import org.slf4j.LoggerFactory

class ReceiveBuffer implements IChannelBuffer {
	static val logger = LoggerFactory.getLogger(ReceiveBuffer)
	
	val ChannelPump inPump
	val ChannelPump outPump
	
	var isSignalBegin = false
	var String filePath = null
	var FileChannel fileChannel = null
	
	var (String) => void onBegin
	var () => void onEnd
	var (String) => void onError
	var (ByteBuffer) => void onData
	
	new(ChannelPump inPump, ChannelPump outPump) {
		this.outPump = outPump
		this.inPump = inPump
		
		inPump.onSignal = [
			logger.debug('SIGNAL {}', it)
			if (startsWith('bng')) {
				if (isSignalBegin) {
					error('Signal is already in begin status!')
					return
				}
				
				isSignalBegin = true
				val signalName = split(':').get(1)
				onBegin?.apply(signalName)
				if (filePath != null) createFile
			} else if (startsWith('end')) {
				if (!isSignalBegin) {
					error('Signal is not in begin status!')
					return
				}
				
				closeFile
				onEnd?.apply
			} else if (startsWith('err')) {
				val error = split(':').get(1)
				errorNoSignal(error)
			}
		]
		
		inPump.onData = [
			if (!isSignalBegin) {
				error('Can not receive data with signal in end status!')
				return
			}
			
			if (filePath != null) writeToFile else onData?.apply(it)
		]
	}
	
	def void onBegin((String) => void onBegin) { this.onBegin = onBegin }
	def void onEnd(() => void onEnd) { this.onEnd = onEnd }
	override onError((String) => void onError) { this.onError = onError }
	
	override error(String message) {
		errorNoSignal(message)
		outPump.pushSignal('''err:«message»''')
	}
	
	override close() {
		if (isSignalBegin)
			errorNoSignal('Irregular close!')
	}
	
	def >>((ByteBuffer) => void onData) {
		this.onData = onData
	}
	
	def void writeToFile(String filePath) {
		//TODO: secure the filesystem path
		this.filePath = filePath
	}
	
	private def void createFile() {
		try {
			val path = Paths.get(filePath)
			fileChannel = FileChannel.open(path, StandardOpenOption.CREATE_NEW, StandardOpenOption.WRITE)	
		} catch(Exception ex) {
			error(ex.message)
		}
	}

	private def void writeToFile(ByteBuffer buffer) {
		try {
			fileChannel.write(buffer)	
		} catch(Exception ex) {
			error(ex.message)
		}
	}
	
	private def void closeFile() {
		isSignalBegin = false
		fileChannel?.close
		
		filePath = null
		fileChannel = null
	}
	
	private def void errorNoSignal(String message) {
		logger.error('ERROR {}', message)
		
		closeFile
		onError?.apply(message)
	}
}