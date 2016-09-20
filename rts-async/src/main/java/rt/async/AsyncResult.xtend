package rt.async

abstract class AsyncResult<R> {
	protected var boolean isComplete = false
	protected var AsyncResult<?> upStack = null
	
	protected var (Throwable) => void onReject = null
	
	def void reject(Throwable error) {
		isComplete =  true
		
		if (onReject !== null) {
			try {
				AsyncStack.push(this)
				onReject.apply(error)
				AsyncStack.pop
			} catch (Throwable ex) {
				AsyncStack.pop
				throwError(ex)
			}
		} else
			throwError(error)
	}
	
	protected def void init((Throwable) => void onReject) {
		this.upStack = AsyncStack.peek
		this.onReject = onReject
		
		try {
			AsyncStack.push(this)
			invoke(this as R)
			AsyncStack.pop
		} catch (Throwable error) {
			AsyncStack.pop
			reject(error)
		}
	}
	
	protected def void throwError(Throwable error) {
		if (upStack === null) {
			error.printStackTrace
			return
		}
		
		upStack.reject(error)
	}
	
	def void invoke(R sub)
}