package rt.async.observable

import rt.async.AsyncResult
import rt.async.AsyncStack

abstract class ObservableResult<T> extends AsyncResult<ObservableResult<T>> {
	var (T) => void onNext = null
	var () => void onComplete = null
	
	var () => void onCancel = null
	var (long) => void onRequest = null
	
	def void onCancel(() => void onCancel) { this.onCancel = onCancel }
	def void onRequest((long) => void onRequest) { this.onRequest = onRequest }
	
	def observe() { new Observable<T>(this) }
	
	def Subscription subscribe((T) => void onNext, () => void onComplete, (Throwable) => void onReject) {
		this.onNext = onNext
		this.onComplete = onComplete
		init(onReject)
		
		return new Subscription(this)
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
	
	static class Subscription {
		val ObservableResult<?> oResult
		new(ObservableResult<?> oResult) {
			this.oResult = oResult
		}
		
		def void cancel() {
			oResult.onCancel?.apply
		}
	
		def void request(long n) {
			oResult.onRequest?.apply(n)
		}
	}
}