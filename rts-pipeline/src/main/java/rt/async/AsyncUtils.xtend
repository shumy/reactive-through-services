package rt.async

import java.util.Timer
import org.eclipse.xtend.lib.annotations.Accessors
import rt.async.promise.Promise

abstract class AsyncUtils {
	static val local = new ThreadLocal<AsyncUtils>
	
	static def AsyncUtils get() { local.get }
	static def void set(AsyncUtils instance) { local.set(instance) }
	
	static def setDefault() { local.set(new DefaultAsyncUtils()) }
	static def setDefault(long timeout) { local.set(new DefaultAsyncUtils(false, timeout)) }
	
	static def isWorker() {
		return local.get.isWorker
	}
	
	static def void schedule(() => void callback) {
		local.get.setTimer(0, callback)
	}
	
	static def void timeout(() => void callback) {
		local.get.setTimeout(callback)
	}
	
	static def void timer(long delay, () => void callback) {
		local.get.setTimer(delay, callback)
	}
	
	static def void periodic(long delay, () => void callback) {
		local.get.setPeriodic(delay, callback)
	}
	
	static def void waitUntil(() => boolean evaluate, () => void onReturn) {
		local.get.setWaitUntil(evaluate, onReturn)
	}
	
	static def void asyncWhile(() => boolean evaluate, () => boolean onWhileTrue, () => void onReturn, (Exception) => void onError) {
		local.get.setAsyncWhile(evaluate, onWhileTrue, onReturn, onError)
	}
	
	static def <T> Promise<T> task(() => T execute) {
		local.get.setTask(execute)
	}
	
	//configs...
	@Accessors val boolean isWorker
	@Accessors val long timeout
	
	new(boolean isWorker, long timeout) {
		this.isWorker = isWorker
		this.timeout = timeout
	}
	
	def void setTimeout(() => void callback) {
		setTimer(timeout, callback)
	}
	
	def void setTimer(long delay, () => void callback)
	def void setPeriodic(long delay, () => void callback)
	def void setAsyncWhile(() => boolean evaluate, () => boolean onWhileTrue, () => void onReturn, (Exception) => void onError)
	def void setWaitUntil(() => boolean evaluate, () => void onReturn)
	def <T> Promise<T> setTask(() => T execute)
	
	static class DefaultAsyncUtils extends AsyncUtils {
		new() { this(false, 3000L) }
		new(boolean isWorker) { this(isWorker, 3000L) }
		new(boolean isWorker, long timeout) {
			super(isWorker, timeout)
		}
		
		override setTimer(long delay, () => void callback) {
			new Timer().schedule([ callback.apply ], delay)
		}
		
		override setPeriodic(long delay, () => void callback) {
			throw new UnsupportedOperationException('setPeriodic')
		}
		
		override setAsyncWhile(() => boolean evaluate, () => boolean onWhileTrue, () => void onReturn, (Exception) => void onError) {
			try {
				while (evaluate.apply && onWhileTrue.apply) {}
				onReturn.apply
			} catch(Exception ex) {
				onError.apply(ex)
			}
		}
		
		override setWaitUntil(() => boolean evaluate, () => void onReturn) {
			while(!evaluate.apply) {}
			onReturn.apply
		}
		
		override <T> setTask(()=>T execute) {
			throw new UnsupportedOperationException('setTask')
		}
	}
}