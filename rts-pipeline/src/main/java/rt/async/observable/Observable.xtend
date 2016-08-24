package rt.async.observable

import rt.async.IAsyncError

class Observable<T> implements IAsyncError {
	val ObservableResult<T> sub

	package new(ObservableResult<T> sub) {
		this.sub = sub
	}
	
	def Observable<T> next((T) => void onNext) {
		sub.onNext = onNext
		return this
	}
	
	def Observable<T> complete(() => void onComplete) {
		sub.onComplete = onComplete
		return this
	} 
	
	override error((Throwable) => void onError) {
		sub.onError = onError
	}
}