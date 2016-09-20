package rt.async.observable

import rt.async.AsyncResult
import rt.async.AsyncStack

abstract class ObservableResult<T> extends AsyncResult<ObservableResult<T>> {
	var (T) => void onNext = null
	var () => void onComplete = null
	
	def observe() { new Observable<T>(this) }
	
	def void subscribe((T) => void onNext, () => void onComplete, (Throwable) => void onReject) {
		this.onNext = onNext
		this.onComplete = onComplete
		init(onReject)
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
}