package rt.plugin

import java.lang.reflect.Method

class InvokerHelper {
	def static invoke(Object obj, String method, Object... args) {
		val Class<?>[] argTypes = newArrayOfSize(args.size)
		
		var i = 0
		for (arg: args) {
			argTypes.set(i, arg.class)
			i++
		}
		
		val iMethod = obj.method(method, argTypes)
		return iMethod.call(args)
	}
	
	def static method(Object obj, String method, Class<?>... argTypes) {
		val cObject = if (obj.class == Class) obj as Class<?> else obj.class
		return new InvokerMethod(obj, cObject.getMethod(method, argTypes))
	}
	
	static class InvokerMethod {
		val Object instance
		val Method method
		  
		new(Object instance, Method method) {
			this.instance = instance
			this.method = method
		}
		
		def call(Object... args) {
			method.invoke(instance, args)
		}
	}
}