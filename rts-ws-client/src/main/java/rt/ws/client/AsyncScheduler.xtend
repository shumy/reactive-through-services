package rt.ws.client

import rt.async.AsyncUtils
import java.util.concurrent.DelayQueue
import java.util.concurrent.Delayed
import java.util.concurrent.TimeUnit

class Task implements Delayed {
	public val () => void executor
	public val long atTime
	
	new(long delay, () => void executor) {
		this.executor = executor
		atTime = System.currentTimeMillis + delay
	}
	
	override getDelay(TimeUnit unit) {
		return atTime - System.currentTimeMillis 
	}
	
	override compareTo(Delayed delayed) {
		val t = delayed as Task
		return (t.atTime - atTime) as int
	}
}

class AsyncScheduler {
	val queue = new DelayQueue<Task>
	
	def void schedule(() => void executor) {
		queue.add(new Task(0, executor))
	}
	
	def void run() {
		AsyncUtils.set(new SchedulerAsyncUtils(this))
		while (true) {
			val task = queue.poll
			if (task != null)
				task.executor.apply
		}
	}
	
	static class SchedulerAsyncUtils extends AsyncUtils {
		val AsyncScheduler scheduler
		
		new(AsyncScheduler scheduler) { this(scheduler, false, 3000L) }
		new(AsyncScheduler scheduler, boolean isWorker) { this(scheduler, isWorker, 3000L) }
		new(AsyncScheduler scheduler, boolean isWorker, long timeout) {
			super(isWorker, timeout)
			this.scheduler = scheduler
		}
		
		override setTimer(long delay, () => void callback) {
			scheduler.queue.add(new Task(delay, callback))
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
		
		override setPeriodic(long delay, () => void callback) {
			throw new UnsupportedOperationException('setPeriodic')
		}
		
		override <T> setTask(() => T execute) {
			throw new UnsupportedOperationException('setTask')
		}
	}
}