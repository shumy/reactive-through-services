package rt.async.observable

class Observable<T> {
	val ObservableResult<T> sub

	package new(ObservableResult<T> sub) {
		this.sub = sub
	}
	
	def subscribe((T) => void onNext, () => void onComplete, (Throwable) => void onError) {
		this.sub.subscribe(onNext, onComplete, onError)
	}
	
	def subscribe((T) => void onNext, () => void onComplete) {
		subscribe(onNext, onComplete, null)
	}
	
	def subscribe((T) => void onNext, (Throwable) => void onError) {
		subscribe(onNext, null, onError)
	}
	
	def subscribe((T) => void onNext) {
		subscribe(onNext, null, null)
	}
}