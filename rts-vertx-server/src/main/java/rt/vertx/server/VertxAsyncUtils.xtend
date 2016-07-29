package rt.vertx.server

import io.vertx.core.Vertx
import rt.pipeline.promise.AsyncUtils
import rt.pipeline.promise.PromiseResult

class VertxAsyncUtils extends AsyncUtils {
	val Vertx vertx
	
	new(Vertx vertx) { this(vertx, false, 3000L) }
	new(Vertx vertx, boolean isWorker) { this(vertx, isWorker, 3000L) }
	new(Vertx vertx, boolean isWorker, long timeout) {
		super(isWorker, timeout)
		this.vertx = vertx
	}
	
	override setTimer(long delay, () => void callback) {
		val cDelay = if (delay < 1) 1 else delay 
		vertx.setTimer(cDelay)[ callback.apply ]
	}
	
	override setPeriodic(long delay, () => void callback) {
		vertx.setPeriodic(delay)[ callback.apply ]
	}
	
	override setAsyncWhile(() => boolean evaluate, () => boolean onWhileTrue, () => void onReturn, (Exception) => void onError) {
		try {
			if (evaluate.apply) {
				if (onWhileTrue.apply)
					setTimer(0, [ setAsyncWhile(evaluate, onWhileTrue, onReturn, onError) ])
			} else {
				onReturn.apply
			}
		} catch(Exception ex) {
			onError.apply(ex)
		}
	}
	
	override setWaitUntil(() => boolean evaluate, () => void onReturn) {
		if (!evaluate.apply) {
			setTimer(0, [ setWaitUntil(evaluate, onReturn) ])
		} else {
			onReturn.apply
		}
	}
	
	override <T> setTask(() => T execute) {
		val PromiseResult<T> pr = [
			vertx.executeBlocking([ 
				AsyncUtils.set(new VertxAsyncUtils(vertx, true))
				try {
					complete(execute.apply)
				} catch(Throwable throwable) {
					fail(throwable)
				}
			],[ res |
				if (res.succeeded)
					resolve(res.result)
				else
					reject(res.cause)
			])
		]
		
		return pr.promise
	}
}