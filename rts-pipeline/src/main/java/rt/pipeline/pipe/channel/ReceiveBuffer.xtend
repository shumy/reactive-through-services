package rt.pipeline.pipe.channel

import java.nio.ByteBuffer
import java.nio.channels.FileChannel
import java.nio.file.Files
import java.nio.file.Paths
import java.nio.file.StandardOpenOption
import org.slf4j.LoggerFactory
import rt.pipeline.PathValidator

class ReceiveBuffer extends ChannelBuffer {
	static val logger = LoggerFactory.getLogger('BUFFER-RECEIVE')
	override getLogger() { return logger }
	
	var (String) => void onBegin = null
	var (ByteBuffer) => void onData = null
	
	def void onBegin((String) => void onBegin) { this.onBegin = onBegin }
	def void onData((ByteBuffer) => void onData) { this.onData = onData }
	
	new(ChannelPump inPump, ChannelPump outPump) {
		super(inPump, outPump)
		
		inPump.onSignal = [ signal |
			logger.debug('SIGNAL {}', signal)
			if (signal == null) {
				error('Received incorrect signal!')
				return
			}
			
			if (signal.flag == Signal.SIGNAL_BEGIN) {
				if (isLocked) {
					error('Channel is already locked!')
					return
				}
				
				isLocked = true
				needConfirmation = true
				signalName = signal.name
				
				onBegin?.apply(signalName)
			} else if (signal.flag == Signal.SIGNAL_END) {
				if (!isLocked) {
					error('Channel is not locked!')
					return
				}
				
				if (signal.name != signalName) {
					error('''Signal value != signalName: «signal.name» != «signalName»''')
					return
				}
				
				endOk(Signal.endConfirm(signalName))
			} else if (signal.flag == Signal.SIGNAL_ERROR) {
				if (signal.name != signalName) {
					error('''Signal value != signalName: «signal.name» != «signalName»''')
					return
				}
				
				endError(signal.message)
			}
		]
		
		inPump.onData = [
			if (!isLocked) {
				error('Can not receive data with channel in unlocked state!')
				return
			}
			
			logger.debug('SIGNAL-DATA {}B', limit)
			if (fileChannel != null) writeBufferToFile else onData?.apply(it)
		]
	}
	
	def >>((ByteBuffer) => void onData) {
		if (!isLocked) {
			error('Channel is not locked!')
			return
		}
		
		this.onData = onData
		confirm
	}
	
	def void writeToFile(String filePath, () => void onFinal) {
		if (!isLocked) {
			error('Channel is not locked!')
			return
		}
		
		if (onFinal != null) onEnd(onFinal)
		
		try {
			if (!PathValidator.isValid(filePath)) {
				error('''Invalid path «filePath»''')
				return
			}
			
			val path = Paths.get(filePath)
			Files.createDirectories(path.parent)
			fileChannel = FileChannel.open(path, StandardOpenOption.CREATE, StandardOpenOption.WRITE)
			confirm
		} catch(Exception ex) {
			error('''«ex.class.simpleName»: «ex.message»''')
		}
	}
	
	def void writeToFile(String filePath) {
		writeToFile(filePath, null)
	}
	
	private def void writeBufferToFile(ByteBuffer buffer) {
		try {
			fileChannel.write(buffer)
		} catch(Exception ex) {
			error('''«ex.class.simpleName»: «ex.message»''')
		}
	}
	
	private def void confirm() {
		if (needConfirmation) {
			needConfirmation = false
			outPump.pushSignal(Signal.beginConfirm(signalName))
		}
	}
}