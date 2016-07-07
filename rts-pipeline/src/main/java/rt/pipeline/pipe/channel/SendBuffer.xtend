package rt.pipeline.pipe.channel

import java.nio.ByteBuffer
import java.nio.channels.FileChannel
import java.nio.file.Paths
import java.nio.file.StandardOpenOption
import java.util.concurrent.atomic.AtomicInteger
import org.slf4j.LoggerFactory

import static rt.pipeline.AsyncUtils.*
import rt.pipeline.promise.Promise
import rt.pipeline.promise.PromiseResult

class SendBuffer implements IChannelBuffer {
	static val logger = LoggerFactory.getLogger('BUFFER-SEND')
	
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
	
	def Promise<Void> sendFile(String filePath, int bufferSize) {
		val PromiseResult<Void> result = [ resolve, reject |
			//TODO: secure the filesystem path
			val path = Paths.get(filePath)
			
			var FileChannel fileChannel = null
			try {
				fileChannel = FileChannel.open(path, StandardOpenOption.READ)	
			} catch(Exception ex) {
				val errorMsg = '''«ex.class.simpleName»: «ex.message»'''
				errorNoSignal(errorMsg)
				reject.apply(errorMsg)
				return
			}
			
			begin(filePath)
				val fc = fileChannel
				val buffer = ByteBuffer.allocate(bufferSize)
				val pos = new AtomicInteger(fc.read(buffer))
				
				//TODO: detect async errors...
				asyncWhile([ pos.get > 0 ],[
					if (outPump.ready) {
						buffer.flip
						outPump.pushData(buffer)
						
						buffer.clear
						pos.set = fc.read(buffer)	
					}
				],
			[ fc.close end resolve.apply(null) ],
			[
				//on while error
				printStackTrace
				val errorMsg = '''«class.simpleName»: «message»'''
				fc.close
				error(errorMsg)
				reject.apply(errorMsg)
			])
		]
		
		return result.promise
	}
	
	def sendFile(String filePath) {
		return sendFile(filePath, 1024 * 1024)//default size to 1MB
	}
	
	private def void errorNoSignal(String message) {
		isSignalBegin = false
		logger.error('ERROR {}', message)
		onError?.apply(message)
	}
}