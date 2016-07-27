package rt.pipeline.promise

class Promise<T> {
	val PromiseResult<T> result
	var isInvoked = false
	
	package new(PromiseResult<T> result) {
		this.result = result
	}
	
	def void then((T) => void onResolve) {
		result.onResolve = onResolve
		
		if (!isInvoked) {
			isInvoked = true
			result.invoke(result)
		}
	}
	
	def void then((T) => void onResolve, (Throwable) => void onReject) {
		result.onResolve = onResolve
		result.onReject = onReject
		
		if (!isInvoked) {
			isInvoked = true
			result.invoke(result)
		}
	}
}