package rt.async.promise

abstract class PromiseResult<T> {
	var T result = null
	var (T) => void onResolve = null
	
	var Throwable error = null
	var (Throwable) => void onReject = null
	
	def void setOnResolve((T) => void onResolve) {
		this.onResolve = onResolve
		if (result != null) onResolve.apply(result)
	}
	
	def void setOnReject((Throwable) => void onReject) {
		this.onReject = onReject
		if (error != null) onReject.apply(error)
	}
	
	def promise() {
		invoke(this)
		return new Promise<T>(this)
	}
	
	def void resolve(T result) {
		this.result = result
		onResolve?.apply(result)
	}
	
	def void reject(Throwable error) {
		this.error = error
		onReject?.apply(error)
	}
	
	def void invoke(PromiseResult<T> result)
}