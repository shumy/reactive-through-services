package rt.plugin.service

class Promise<T> {
	val PromiseResult<T> result
	
	package new(PromiseResult<T> result) {
		this.result = result
	}
	
	def Promise<T> then((T) => void callback) {
		result.invoke([ callback.apply(it) ], [ it.printStackTrace ])
		
		return this
	}
}