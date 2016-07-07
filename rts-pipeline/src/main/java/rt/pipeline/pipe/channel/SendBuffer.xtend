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
	
	var needConfirmation = false
	
	new(ChannelPump outPump, ChannelPump inPump) {
		super(inPump, outPump)
		
		//process backward signal...
		inPump.onSignal = [
			logger.debug('BACK-SIGNAL {}', it)
			if (startsWith(SIGNAL_BEGIN_CONFIRM)) {
				if (needConfirmation) {
					needConfirmation = false
					onReady?.apply
				}
			} else if (startsWith(SIGNAL_END_CONFIRM)) {
				if (needConfirmation) {
					needConfirmation = false
					endOk
				}
			} else if (startsWith(SIGNAL_ERROR)) {
				needConfirmation = false
				val error = split(':', 2).get(1)
				endError(error)
			}
		]
	}
	
	def void begin(String name, () => void onReady) {
		//wait for channel unlock
		waitUntil([ !isLocked ], [
			isLocked = true
			val signal = '''«SIGNAL_BEGIN»:«name»'''
			logger.debug('SIGNAL {}', signal)
			
			needConfirmation = true
			this.onReady = onReady
			timer(3000)[ if (needConfirmation) { needConfirmation = false endError('Begin confirmation timeout!') }]
			outPump.pushSignal(signal)
		])
	}
	def void end() {
		if (!isLocked) {
			endError('Channel is not locked!')
			return
		}
		
		isLocked = false
		logger.debug('SIGNAL {}', SIGNAL_END)
		
		needConfirmation = true
		timer(3000)[ if (needConfirmation) { needConfirmation = false endError('End confirmation timeout!') }]
		outPump.pushSignal(SIGNAL_END)
	}
	
	def <<(ByteBuffer buffer) {
		if (!isLocked) {
			endError('Can not send data with channel in unlocked state!')
			return
		}
		
		outPump.pushData(buffer)
	}
	
	def Promise<Void> sendFile(String filePath, int bufferSize) {
		filePromise = [ promise |
			//TODO: secure the filesystem path
			val path = Paths.get(filePath)
			
			try {
				fileChannel = FileChannel.open(path, StandardOpenOption.READ)	
			} catch(Exception ex) {
				endError('''«ex.class.simpleName»: «ex.message»''')
				return
			}
			
			begin(filePath)[
				val fc = fileChannel
				val buffer = ByteBuffer.allocate(bufferSize)
				val pos = new AtomicInteger(fc.read(buffer))
				
				asyncWhile([ pos.get > 0 ],[
					if (!isLocked) { endError('Unlocked before transfer conclusion!') return false }
					if (outPump.ready) {
						buffer.flip
						outPump.pushData(buffer)
						
						buffer.clear
						pos.set = fc.read(buffer)
					}
					return true
				],
				[ end ],
				[ error('''«class.simpleName»: «message»''') ])
			]
		]
		
		return filePromise.promise
	}
	
	def sendFile(String filePath) {
		return sendFile(filePath, 1024 * 1024)//default size to 1MB
	}
}