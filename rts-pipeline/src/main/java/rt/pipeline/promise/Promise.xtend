package rt.pipeline.promise

class Promise<T> {
	val PromiseResult<T> result
	
	package new(PromiseResult<T> result) {
		this.result = result
	}
	
	def void then((T) => void onResolve, (Throwable) => void onReject) {
		result.onResolve = onResolve
		result.onReject = onReject
	}
	
	def Promise<T> then((T) => void onResolve) {
		result.onResolve = onResolve
		return this
	}
	
	def Promise<T> error((Throwable) => void onReject) {
		result.onReject = onReject
		return this
	}
}