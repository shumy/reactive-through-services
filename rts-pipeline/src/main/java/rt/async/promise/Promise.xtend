package rt.async.promise

class Promise<T> {
	val PromiseResult<T> result
	
	package new(PromiseResult<T> result) {
		this.result = result
	}

	def Promise<T> then((T) => void onResolve, (Throwable) => void onReject) {
		this.result.subscribe(onResolve, onReject)
		return this
	}
		
	def Promise<T> then((T) => void onResolve) {
		return then(onResolve, null)
	}
}