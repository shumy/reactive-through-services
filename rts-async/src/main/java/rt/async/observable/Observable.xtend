package rt.async.observable

import org.eclipse.xtend.lib.annotations.Accessors

class Observable<T> {
	val ObservableResult<T> oResult
	var () => void onComplete = null
	var (Throwable) => void onError = null
	
	@Accessors(PUBLIC_GETTER) var ObservableResult.Subscription subscription = null
	
	package new(ObservableResult<T> oResult) {
		this.oResult = oResult
	}
	
	def Observable<T> filter((T) => boolean filterFun) {
		val ObservableResult<T> newObs = [ obs |
			oResult.subscribe([ if (filterFun.apply(it)) obs.next(it) ], [ obs.complete ], [ obs.reject(it) ])
		]
		
		return newObs.observe
	}
	
	def <R> Observable<R> map((T) => R transformFun) {
		val ObservableResult<R> newObs = [ obs |
			oResult.subscribe([ obs.next( transformFun.apply(it) ) ], [ obs.complete ], [ obs.reject(it) ])
		]
		
		return newObs.observe
	}
	
	def Observable<T> forEach((T) => void processFun) {
		val ObservableResult<T> newObs = [ obs |
			oResult.subscribe([ processFun.apply(it) obs.next(it) ], [ obs.complete ], [ obs.reject(it) ])
		]
		
		return newObs.observe
	}
	
	def Observable<T> onComplete(() => void onComplete) {
		this.onComplete = onComplete
		return this
	}
	
	def Observable<T> onError((Throwable) => void onError) {
		this.onError = onError
		return this
	}
	
	def subscribe((T) => void onNext, () => void onComplete, (Throwable) => void onError) {
		//avoid override of onComplete(...)
		val () => void newOnComplete = 
			if (this.onComplete === null)
				onComplete
			else if (onComplete === null)
				this.onComplete
			else
				[ this.onComplete.apply onComplete.apply ]
		
		//avoid override of onError(...)
		val (Throwable) => void newOnError =
			if (this.onError === null)
				onError
			else if (this.onError === null)
				this.onError
			else
				[ this.onError.apply(it) onError.apply(it) ]
		
		this.subscription = oResult.subscribe(onNext, newOnComplete, newOnError)
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
	
	def void delegate(ObservableResult<T> to) {
		subscribe([to.next(it)], [to.complete], [to.reject(it)])
	}
}