package rt.pipeline.pipe.channel

import java.nio.ByteBuffer
import java.nio.channels.FileChannel
import java.nio.file.Paths
import java.nio.file.StandardOpenOption
import org.slf4j.LoggerFactory
import rt.pipeline.promise.Promise

class ReceiveBuffer extends ChannelBuffer {
	static val logger = LoggerFactory.getLogger('BUFFER-RECEIVE')
	
	var (String) => void onBegin
	var (ByteBuffer) => void onData
	
	var needConfirmation = false
	
	new(ChannelPump inPump, ChannelPump outPump) {
		super(inPump, outPump)
		
		inPump.onSignal = [
			logger.debug('SIGNAL {}', it)
			if (startsWith(SIGNAL_BEGIN)) {
				if (isLocked) {
					error('Channel is already locked!')
					return
				}
				
				needConfirmation = true
				isLocked = true
				val signalName = split(':', 2).get(1)
				onBegin?.apply(signalName)
			} else if (startsWith(SIGNAL_END)) {
				if (!isLocked) {
					error('Channel is not locked!')
					return
				}
				
				endOk(SIGNAL_END_CONFIRM)
			} else if (startsWith(SIGNAL_ERROR)) {
				val error = split(':', 2).get(1)
				endError(error)
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
	
	def void onBegin((String) => void onBegin) { this.onBegin = onBegin }
	def void onEnd(() => void onEnd) { this.onEnd = onEnd }
	
	def >>((ByteBuffer) => void onData) {
		this.onData = onData
		if (needConfirmation) { needConfirmation = false outPump.pushSignal(SIGNAL_BEGIN_CONFIRM) }
	}
	
	def Promise<Void> writeToFile(String filePath) {
		filePromise = [
			//TODO: secure the filesystem path
			try {
				val path = Paths.get(filePath)
				fileChannel = FileChannel.open(path, StandardOpenOption.CREATE, StandardOpenOption.WRITE)
				if (needConfirmation) { needConfirmation = false outPump.pushSignal(SIGNAL_BEGIN_CONFIRM) }
			} catch(Exception ex) {
				error('''«ex.class.simpleName»: «ex.message»''')
			}
		]
		
		return filePromise.promise
	}
	
	private def void writeBufferToFile(ByteBuffer buffer) {
		try {
			fileChannel.write(buffer)
		} catch(Exception ex) {
			error('''«ex.class.simpleName»: «ex.message»''')
		}
	}
}