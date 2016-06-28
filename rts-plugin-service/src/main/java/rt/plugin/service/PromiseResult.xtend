package rt.plugin.service

abstract class PromiseResult<T> {
	
	def promise() {
		return new Promise<T>(this)
	}
	
	def void invoke((T) => void resolve, (RuntimeException) => void reject)
}