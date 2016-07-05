package rt.pipeline.promise

class Promise<T> {
	val PromiseResult<T> result
	
	package new(PromiseResult<T> result) {
		this.result = result
	}
	
	def Promise<T> then((T) => void resultCallback) {
		result.invoke([ resultCallback.apply(it) ], [ println(it) ])
		return this
	}
	
	def Promise<T> then((T) => void resultCallback, (String) => void errorCallback) {
		result.invoke([ resultCallback.apply(it) ], [ errorCallback.apply(it) ])
		return this
	}
}