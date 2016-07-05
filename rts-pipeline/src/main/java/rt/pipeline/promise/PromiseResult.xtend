package rt.pipeline.promise

abstract class PromiseResult<T> {
	
	def promise() {
		return new Promise<T>(this)
	}
	
	def void invoke((T) => void resolve, (String) => void reject)
}