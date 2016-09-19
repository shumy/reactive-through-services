package rt.async

abstract class AsyncResult {
	protected var boolean isComplete = false
	protected var AsyncResult upStack = null
	
	protected var (Throwable) => void onReject = null
	
	def void reject(Throwable error) {
		isComplete =  true
		
		if (onReject !== null) {
			AsyncStack.push(this)
			onReject.apply(error)
			AsyncStack.pop
		} else
			throwError(error)
	}
	
	protected def void throwError(Throwable error) {
		if (upStack === null) {
			println('Unhandled error!')
			return
		}
		
		upStack.reject(error)
	}
}