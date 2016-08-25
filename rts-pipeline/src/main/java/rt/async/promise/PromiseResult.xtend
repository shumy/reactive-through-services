package rt.async.promise

import rt.async.IAsyncError

abstract class PromiseResult<T> {
	var T result = null
	var (T) => void onResolveVoid = null
	var (T) => IAsyncError onResolveError = null
	
	var Throwable error = null
	var (Throwable) => void onReject = null
	
	def void setOnResolve((T) => void onResolve) {
		this.onResolveVoid = onResolve
		if (result != null)
			runResolve(result)
	}
	
	def void setOnResolve((T) => IAsyncError onResolve) {
		this.onResolveError = onResolve
		if (result != null)
			runResolve(result)
	}
	
	def void setOnReject((Throwable) => void onReject) {
		this.onReject = onReject
		if (error != null) 
			onReject.apply(error)
	}
	
	def promise() {
		invoke(this)
		return new Promise<T>(this)
	}
	
	def void resolve(T result) {
		this.result = result
		runResolve(result)
	}
	
	def void reject(Throwable error) {
		this.error = error
		onReject?.apply(error)
	}
	
	def void invoke(PromiseResult<T> result)
	
	private def void runResolve(T data) {
		try {
			if (onResolveVoid != null) {
				onResolveVoid.apply(data)
			} else {
				if (onResolveError != null) {
					//error forward...
					onResolveError.apply(data).error(onReject)
				}
			}
		} catch(Throwable ex) {
			onReject?.apply(ex)
		}
	}
}