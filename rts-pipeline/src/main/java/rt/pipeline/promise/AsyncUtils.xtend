package rt.pipeline.promise

import java.util.Timer

interface AsyncUtils {
	static val local = new ThreadLocal<AsyncUtils>
	
	static def AsyncUtils get() { local.get }
	static def void set(AsyncUtils instance) { local.set(instance) }
	static def void setDefault() { local.set(new DefaultAsyncUtils) }
	
	static def void timer(long delay, () => void callback) {
		local.get.setTimer(delay, callback)
	}
	
	static def void periodic(long delay, () => void callback) {
		local.get.setPeriodic(delay, callback)
	}
	
	static def void asyncWhile(() => boolean evaluate, () => boolean onWhileTrue, () => void onReturn, (Exception) => void onError) {
		local.get.setAsyncWhile(evaluate, onWhileTrue, onReturn, onError)
	}
	
	static def void waitUntil(() => boolean evaluate, () => void onReturn) {
		local.get.setWaitUntil(evaluate, onReturn)
	}
	
	def void setTimer(long delay, () => void callback)
	def void setPeriodic(long delay, () => void callback)
	def void setAsyncWhile(() => boolean evaluate, () => boolean onWhileTrue, () => void onReturn, (Exception) => void onError)
	def void setWaitUntil(() => boolean evaluate, () => void onReturn)
	
	static class DefaultAsyncUtils implements AsyncUtils {
		override setTimer(long delay, () => void callback) {
			new Timer().schedule([ callback.apply ], delay)
		}
		
		override setPeriodic(long delay, ()=>void callback) {
			throw new UnsupportedOperationException("TODO: auto-generated method stub")
		}
		
		override setAsyncWhile(() => boolean evaluate, () => boolean onWhileTrue, () => void onReturn, (Exception) => void onError) {
			try {
				while (evaluate.apply && onWhileTrue.apply)
				onReturn.apply
			} catch(Exception ex) {
				onError.apply(ex)
			}
		}
		
		override setWaitUntil(() => boolean evaluate, () => void onReturn) {
			while(!evaluate.apply) {}
			onReturn.apply
		}
	}
}