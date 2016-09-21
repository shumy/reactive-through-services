package rt.async

import java.util.Stack

class AsyncStack {
	static val local = new ThreadLocal<Stack<AsyncResult<?>>> {
		override protected initialValue() { new Stack<AsyncResult<?>> }
	}
	
	static def void push(AsyncResult<?> res) {
		local.get.push(res)
	}
	
	static def AsyncResult<?> pop() {
		local.get.pop
	}
	
	static def AsyncResult<?> peek() {
		if (local.get.empty()) return null 
		local.get.peek
	}
}