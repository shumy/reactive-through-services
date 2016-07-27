package rt.pipeline.promise

import java.util.Timer
import org.eclipse.xtend.lib.annotations.Accessors

abstract class AsyncUtils {
	static val local = new ThreadLocal<AsyncUtils>
	
	static def AsyncUtils get() { local.get }
	static def void set(AsyncUtils instance) { local.set(instance) }
	static def setDefault() { local.set(new DefaultAsyncUtils) return local.get }
	
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
	@Accessors var long timeout = 3000L
	
	def void setTimeout(() => void callback) {
		setTimer(timeout, callback)
	}
	
	def void setTimer(long delay, () => void callback)
	def void setPeriodic(long delay, () => void callback)
	def void setAsyncWhile(() => boolean evaluate, () => boolean onWhileTrue, () => void onReturn, (Exception) => void onError)
	def void setWaitUntil(() => boolean evaluate, () => void onReturn)
	def <T> Promise<T> setTask(() => T execute)
	
	static class DefaultAsyncUtils extends AsyncUtils {
		
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