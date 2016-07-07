package rt.pipeline.pipe.channel

import java.nio.channels.FileChannel
import rt.pipeline.promise.PromiseResult
import org.slf4j.LoggerFactory

abstract class ChannelBuffer {
	static val logger = LoggerFactory.getLogger('BUFFER')
	
	public static val SIGNAL_BEGIN = 'bgn'
	public static val SIGNAL_BEGIN_CONFIRM = 'bgn-cnf'
	
	public static val SIGNAL_END = 'end'
	public static val SIGNAL_END_CONFIRM = 'end-cnf'
	
	public static val SIGNAL_ERROR = 'err'
	
	protected val ChannelPump inPump
	protected val ChannelPump outPump
	
	protected var isSignalBegin = false
	protected var FileChannel fileChannel = null
	protected var PromiseResult<Void> filePromise = null
	
	protected var () => void onReady = null
	protected var () => void onEnd = null
	protected var (String) => void onError = null
	
	new(ChannelPump inPump, ChannelPump outPump) {
		this.outPump = outPump
		this.inPump = inPump
	}
	
	def void onError((String) => void onError) { this.onError = onError }
	
	def void error(String error) {
		endError(error, true)
	}
	
	def void close() {
		if (isSignalBegin)
			endError('Irregular close!', false)
	}
	
	protected def void endOk(String signal) {
		logger.debug('END')
		endProcess
		onEnd?.apply
		
		val promise = filePromise
		filePromise = null
		promise?.resolve(null) //this action can replace the filePromise, so we can't set it to null after
		
		if (signal != null) outPump.pushSignal(signal)
	}
	
	protected def void endError(String error, boolean sendSignal) {
		logger.error('END {}', error)
		endProcess
		onError?.apply(error)
		
		val promise = filePromise
		filePromise = null
		promise?.reject(error) //this action can replace the filePromise, so we can't set it to null after
		
		if (sendSignal) outPump.pushSignal('''«SIGNAL_ERROR»:«error»''')
	}
	
	private def void endProcess() {
		isSignalBegin = false
		fileChannel?.close
		fileChannel = null
		onReady = null
	}
}