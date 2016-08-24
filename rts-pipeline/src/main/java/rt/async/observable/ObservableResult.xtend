package rt.async.observable

import java.util.LinkedList

abstract class ObservableResult<T> {
	var results = new LinkedList<T>
	var (T) => void onNext = null
	
	boolean isCompleted = false
	var () => void onComplete = null
	
	var Throwable error = null
	var (Throwable) => void onError = null
	
	def void setOnNext((T) => void onNext) {
		this.onNext = onNext
		if (results.size != 0)
			results.forEach[ runNext ]
	}
	
	def void setOnComplete(() => void onComplete) {
		this.onComplete = onComplete
		if (isCompleted)
			runComplete
	}
	
	def void setOnError((Throwable) => void onError) {
		this.onError = onError
		if (error != null)
			onError.apply(error)
	}
	
	def observe() {
		invoke(this)
		return new Observable<T>(this)
	}
	
	def void next(T data) {
		results.add(data)
		runNext(data)
	}
	
	def void complete() {
		isCompleted = true
		runComplete
	}
	
	def void error(Throwable error) {
		this.error = error
		onError?.apply(error)
	}
	
	def void invoke(ObservableResult<T> sub)
	
	private def void runNext(T data) {
		try {
			onNext?.apply(data)	
		} catch(Throwable ex) {
			onError?.apply(ex)
		}
	}
	
	private def void runComplete() {
		try {
			onComplete?.apply
		} catch(Throwable ex) {
			onError?.apply(ex)
		}
	}
}