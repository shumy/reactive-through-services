package rt.async.promise

import rt.async.AsyncStack
import rt.async.AsyncResult

abstract class PromiseResult<T> extends AsyncResult {
	var (T) => void onResolve = null
	
	def promise() { new Promise<T>(this) }
	
	def subscribe((T) => void onResolve, (Throwable) => void onReject) {
		this.upStack = AsyncStack.peek
		this.onResolve = onResolve
		this.onReject = onReject
		
		try {
			invoke(this)
		} catch (Throwable error) {
			reject(error)
		}
	}
	
	def void resolve(T data) {
		if (!isComplete) {
			try {
				AsyncStack.push(this)
				onResolve.apply(data)
				AsyncStack.pop
				
				isComplete =  true
			} catch (Throwable error) {
				AsyncStack.pop
				reject(error)
			}
		}
	}
	
	def void invoke(PromiseResult<T> sub)
}