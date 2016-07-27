package rt.pipeline.promise

abstract class PromiseResult<T> {
	var isResolved = false
	
	package var (T) => void onResolve
	package var (Throwable) => void onReject
	
	def promise() {
		return new Promise<T>(this)
	}
	
	def void resolve(T result) {
		if (!isResolved) {
			isResolved = true
			onResolve?.apply(result)
		}
	}
	
	def void reject(Throwable ex) {
		if (!isResolved) {
			isResolved = true
			onReject?.apply(ex)
		}
	}
	
	def void invoke(PromiseResult<T> result)
}