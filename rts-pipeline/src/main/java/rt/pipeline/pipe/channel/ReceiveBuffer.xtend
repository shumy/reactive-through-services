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
	
	new(ChannelPump inPump, ChannelPump outPump) {
		super(inPump, outPump)
		
		inPump.onSignal = [
			logger.debug('SIGNAL {}', it)
			if (startsWith(SIGNAL_BEGIN)) {
				if (isSignalBegin) {
					error('Signal is already in begin status!')
					return
				}
				
				isSignalBegin = true
				val signalName = split(':', 2).get(1)
				onBegin?.apply(signalName)
			} else if (startsWith(SIGNAL_END)) {
				if (!isSignalBegin) {
					error('Signal is not in begin status!')
					return
				}
				
				endOk(SIGNAL_END_CONFIRM)
			} else if (startsWith(SIGNAL_ERROR)) {
				val error = split(':', 2).get(1)
				endError(error, false)
			}
		]
		
		inPump.onData = [
			if (!isSignalBegin) {
				error('Can not receive data with signal in end status!')
			}
			
			logger.debug('SIGNAL-DATA {}B', limit)
			if (fileChannel != null) writeBufferToFile else onData?.apply(it)
		]
	}
	
	def void onBegin((String) => void onBegin) { this.onBegin = onBegin }
	def void onEnd(() => void onEnd) { this.onEnd = onEnd }
	
	def >>((ByteBuffer) => void onData) {
		this.onData = onData
		outPump.pushSignal(SIGNAL_BEGIN_CONFIRM)
	}
	
	def Promise<Void> writeToFile(String filePath) {
		filePromise = [
			//TODO: secure the filesystem path
			try {
				val path = Paths.get(filePath)
				fileChannel = FileChannel.open(path, StandardOpenOption.CREATE_NEW, StandardOpenOption.WRITE)
				outPump.pushSignal(SIGNAL_BEGIN_CONFIRM)	
			} catch(Exception ex) {
				endError('''«ex.class.simpleName»: «ex.message»''', true)
				return
			}
		]
		
		return filePromise.promise
	}
	
	private def void writeBufferToFile(ByteBuffer buffer) {
		try {
			fileChannel.write(buffer)
		} catch(Exception ex) {
			endError('''«ex.class.simpleName»: «ex.message»''', true)
		}
	}
}