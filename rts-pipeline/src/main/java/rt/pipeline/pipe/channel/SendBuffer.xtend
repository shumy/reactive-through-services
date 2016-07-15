package rt.pipeline.pipe.channel

import java.nio.ByteBuffer
import java.nio.channels.FileChannel
import java.nio.file.Paths
import java.nio.file.StandardOpenOption
import java.util.concurrent.atomic.AtomicInteger
import org.slf4j.LoggerFactory

import static rt.pipeline.promise.AsyncUtils.*
import rt.pipeline.PathValidator

class SendBuffer extends ChannelBuffer {
	static val logger = LoggerFactory.getLogger('BUFFER-SEND')
	override getLogger() { return logger }
	
	var () => void onReady = null
	
	new(ChannelPump outPump, ChannelPump inPump) {
		super(inPump, outPump)
		
		//process backward signal...
		inPump.onSignal = [ signal |
			logger.debug('BACK-SIGNAL {}', signal)
			if (signal == null) {
				error('Received incorrect signal!')
				return
			}
			
			if (signal.name != signalName) {
				endError('''Signal confirmation '«signal.name»' != '«signalName»' ''')
				return
			}
			
			if (signal.flag == Signal.SIGNAL_BEGIN_CONFIRM) {
				if (needConfirmation) {
					needConfirmation = false
					onReady?.apply
				}
			} else if (signal.flag == Signal.SIGNAL_END_CONFIRM) {
				if (needConfirmation) {
					endOk
				}
			} else if (signal.flag == Signal.SIGNAL_ERROR) {
				endError(signal.message)
			}
		]
	}
	
	def void begin(String name, () => void onReady) {
		//wait for channel unlock
		waitUntil([ !isLocked ], [
			isLocked = true
			needConfirmation = true
			signalName = name
			
			this.onReady = onReady
			timeout[ if (needConfirmation) { needConfirmation = false endError('Begin confirmation timeout!') }]
			
			Signal.begin(signalName).push
		])
	}
	def void end() {
		if (!isLocked) {
			endError('Channel is not locked!')
			return
		}
		
		needConfirmation = true
		timeout[ if (needConfirmation) { needConfirmation = false endError('End confirmation timeout!') }]
		
		Signal.end(signalName).push
	}
	
	def <<(ByteBuffer buffer) {
		if (!isLocked) {
			endError('Can not send data with channel in unlocked state!')
			return
		}
		
		outPump.pushData(buffer)
	}
	
	def void sendSliced(ByteBuffer buffer, int bufferSize, () => void onFinal) {
		val limit = buffer.limit
		buffer.limit(if (bufferSize < limit) bufferSize else limit)
		
		val index = new AtomicInteger(0)
		asyncWhile([ index.get < limit ],[
			if (outPump.ready) {
				outPump.pushData(buffer)
				
				//next slice...
				val nextPosition = index.addAndGet(bufferSize)
				val nextLimit = nextPosition + bufferSize
				
				buffer.position(if (nextPosition < limit) nextPosition else limit)
				buffer.limit(if (nextLimit < limit) nextLimit else limit)
			}
			return true
		],
		[ if (onFinal != null) onFinal.apply ],
		[ error('''«class.simpleName»: «message»''') printStackTrace ])
	}
	
	def void sendSliced(ByteBuffer buffer, () => void onFinal) {
		sendSliced(buffer, 1024*1024, onFinal)
	}
	
	def void sendFile(String filePath, int bufferSize, () => void onFinal) {
		begin(filePath)[
			logger.info('FILE-BEGIN ' + filePath)
			if (onFinal != null) onEnd(onFinal)
			
			try {
				if (!PathValidator.isValid(filePath)) {
					endError('''Invalid path «filePath»''')
					return
				}
				
				val path = Paths.get(filePath)
				fileChannel = FileChannel.open(path, StandardOpenOption.READ)
			} catch(Exception ex) {
				endError('''«ex.class.simpleName»: «ex.message»''')
				return
			}
			
			val fc = fileChannel
			val buffer = ByteBuffer.allocate(bufferSize)
			val pos = new AtomicInteger(fc.read(buffer)) //TODO: remove AtomicInteger?
			
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
			[ end logger.info('FILE-END ' + filePath) ],
			[ error('''«class.simpleName»: «message»''') printStackTrace ])
		]
	}
	
	def sendFile(String filePath) {
		sendFile(filePath, 1024 * 1024, null)//default size to 1MB
	}
	
	def sendFile(String filePath, int bufferSize) {
		sendFile(filePath, bufferSize, null)
	}
	
	def sendFile(String filePath, () => void onEnd) {
		sendFile(filePath, 1024 * 1024, onEnd)//default size to 1MB
	}
	
	private def void push(Signal signal) {
		logger.debug('SIGNAL {}', signal)
		outPump.pushSignal(signal)
	}
}