package rt.async.promise

import rt.async.IAsyncError

class Promise<T> implements IAsyncError {
	val PromiseResult<T> result
	
	package new(PromiseResult<T> result) {
		this.result = result
	}
	
	def Promise<T> then((T) => void onResolve) {
		result.onResolve = onResolve
		return this
	}
	
	override error((Throwable) => void onReject) {
		result.onReject = onReject
	}
}