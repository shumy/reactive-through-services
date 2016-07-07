package rt.pipeline.pipe.channel

import java.nio.ByteBuffer
import java.nio.channels.FileChannel
import java.nio.file.Paths
import java.nio.file.StandardOpenOption
import java.util.concurrent.atomic.AtomicInteger
import org.slf4j.LoggerFactory
import rt.pipeline.promise.Promise

import static rt.pipeline.promise.AsyncUtils.*

class SendBuffer extends ChannelBuffer {
	static val logger = LoggerFactory.getLogger('BUFFER-SEND')
	
	new(ChannelPump outPump, ChannelPump inPump) {
		super(inPump, outPump)
		
		//process backward signal...
		inPump.onSignal = [
			logger.debug('BACK-SIGNAL {}', it)
			if (startsWith(SIGNAL_BEGIN_CONFIRM)) {
				onReady?.apply
			} else if (startsWith(SIGNAL_END_CONFIRM)) {
				endOk(null)
			} else if (startsWith(SIGNAL_ERROR)) {
				val error = split(':', 2).get(1)
				endError(error, false)
			}
		]
	}
	
	def void begin(String name, () => void onReady) {
		if (isSignalBegin) {
			endError('Signal is already in begin status!', false)
			return
		}
		
		isSignalBegin = true
		val signal = '''«SIGNAL_BEGIN»:«name»'''
		logger.debug('SIGNAL {}', signal)
		
		this.onReady = onReady
		outPump.pushSignal(signal)
		/*TODO: process begin reponse timeout?*/
	}
	def void end() {
		if (!isSignalBegin) {
			endError('Signal is not in begin status!', false)
			return
		}
		
		isSignalBegin = false
		logger.debug('SIGNAL {}', SIGNAL_END)
		outPump.pushSignal(SIGNAL_END)
		/*TODO: process end reponse timeout?*/
	}
	
	def <<(ByteBuffer buffer) {
		if (!isSignalBegin)
			throw new RuntimeException('Can not send data with signal in end status!')
		
		outPump.pushData(buffer)
	}
	
	def Promise<Void> sendFile(String filePath, int bufferSize) {
		filePromise = [ promise |
			//TODO: secure the filesystem path
			val path = Paths.get(filePath)
			
			try {
				fileChannel = FileChannel.open(path, StandardOpenOption.READ)	
			} catch(Exception ex) {
				endError('''«ex.class.simpleName»: «ex.message»''', false)
				return
			}
			
			begin(filePath)[
				val fc = fileChannel
				val buffer = ByteBuffer.allocate(bufferSize)
				val pos = new AtomicInteger(fc.read(buffer))
				
				asyncWhile([ pos.get > 0 ],[
					if (!isSignalBegin) throw new RuntimeException('Closed before transfer conclusion!')
					if (outPump.ready) {
						buffer.flip
						outPump.pushData(buffer)
						
						buffer.clear
						pos.set = fc.read(buffer)	
					}
				],
				[ end ],
				[ endError('''«class.simpleName»: «message»''', true) ])
			]
		]
		
		return filePromise.promise
	}
	
	def sendFile(String filePath) {
		return sendFile(filePath, 1024 * 1024)//default size to 1MB
	}
}