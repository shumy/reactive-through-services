package rt.async.promise

import rt.async.AsyncStack
import rt.async.AsyncResult

abstract class PromiseResult<T> extends AsyncResult<PromiseResult<T>> {
	var (T) => void onResolve = null
	
	def promise() { new Promise<T>(this) }
	
	def void subscribe((T) => void onResolve, (Throwable) => void onReject) {
		this.onResolve = onResolve
		init(onReject)
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
}