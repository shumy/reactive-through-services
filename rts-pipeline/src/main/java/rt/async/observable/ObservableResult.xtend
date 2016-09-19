package rt.async.observable

import rt.async.AsyncResult
import rt.async.AsyncStack

abstract class ObservableResult<T> extends AsyncResult {
	var (T) => void onNext = null
	var () => void onComplete = null
	
	def observe() { new Observable<T>(this) }
	
	def subscribe((T) => void onNext, () => void onComplete, (Throwable) => void onReject) {
		this.upStack = AsyncStack.peek
		this.onNext = onNext
		this.onComplete = onComplete
		this.onReject = onReject
		
		try {
			invoke(this)
		} catch (Throwable error) {
			reject(error)
		}
	}
	
	def void next(T data) {
		if (!isComplete) {
			try {
				AsyncStack.push(this)
				onNext.apply(data)
				AsyncStack.pop
			} catch (Throwable error) {
				AsyncStack.pop
				reject(error)
			}
		}
	}
	
	def void complete() {
		if (!isComplete) {
			try {
				AsyncStack.push(this)
				onComplete?.apply
				AsyncStack.pop
				
				isComplete =  true
			} catch (Throwable error) {
				AsyncStack.pop
				reject(error)
			}
		}
	}
	
	def void invoke(ObservableResult<T> sub)
}