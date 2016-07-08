package rt.pipeline.pipe.channel

import java.nio.channels.FileChannel
import org.slf4j.Logger

abstract class ChannelBuffer {
	def Logger getLogger()
	
	protected val ChannelPump inPump
	protected val ChannelPump outPump
	
	protected var isLocked = false
	protected var needConfirmation = false
	protected var String signalName = ''
	protected var FileChannel fileChannel = null
	
	var () => void onEnd = null
	var (String) => void onError = null
	
	def void onEnd(() => void onEnd) { this.onEnd = onEnd }
	def void onError((String) => void onError) { this.onError = onError }
	
	new(ChannelPump inPump, ChannelPump outPump) {
		this.outPump = outPump
		this.inPump = inPump
	}
	
	def void error(String error) {
		endError(error, true)
	}
	
	def void close() {
		if (isLocked)
			endError('Irregular close!')
	}
	
	
	protected def void endOk() { endOk(null) }
	
	protected def void endOk(Signal signal) {
		logger.debug('endOk')
		onEnd?.apply
		if (signal != null) outPump.pushSignal(signal)
		reset
	}
	
	protected def void endError(String error) { endError(error, false) }
	
	private def void endError(String error, boolean sendSignal) {
		logger.error('endError: {}', error)
		onError?.apply(error)
		if (sendSignal) outPump.pushSignal(Signal.error(signalName, error))
		reset
	}
	
	private def void reset() {
		isLocked = false
		needConfirmation = false
		
		fileChannel?.close
		
		fileChannel = null
		signalName = ''
	}
	
	static class Signal {
		public static val SIGNAL_BEGIN = 'bgn'
		public static val SIGNAL_BEGIN_CONFIRM = 'bgn-cnf'
		
		public static val SIGNAL_END = 'end'
		public static val SIGNAL_END_CONFIRM = 'end-cnf'
		
		public static val SIGNAL_ERROR = 'err'
		
		public val String flag
		public val String name
		public val String message
		
		private new(String flag, String name) { this(flag, name, null) }
		private new(String flag, String name, String message) {
			this.flag = flag
			this.name = name
			this.message = message
		}
		
		static def begin(String name) { new Signal(SIGNAL_BEGIN, name) }
		static def end(String name) { new Signal(SIGNAL_END, name) }
		static def error(String name, String message) { new Signal(SIGNAL_ERROR, name, message) }
		
		static def beginConfirm(String name) { new Signal(SIGNAL_BEGIN_CONFIRM, name) }
		static def endConfirm(String name) { new Signal(SIGNAL_END_CONFIRM, name) }
		
		static def process(String msg) {
			val firstSplits = msg.split(':', 2)
			
			if (firstSplits.length < 2)
				return null
			
			val signal = firstSplits.get(0)
			val value = firstSplits.get(1)
			
			val secondSplits = value.split(':', 2)
			val name = secondSplits.get(0)
			val message = if (secondSplits.length > 1) secondSplits.get(1) else null 
			
			return new Signal(signal, name, message) 
		}
		
		override toString() '''«flag»:«name»«IF message != null»:«message»«ENDIF»'''
	}
}