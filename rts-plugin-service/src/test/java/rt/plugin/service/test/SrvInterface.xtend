package rt.plugin.service.test

import rt.async.promise.Promise
import rt.plugin.service.an.Public

interface SrvInterface {
	
	@Public(retType = Void)
	def Promise<Void> hello(String name)
	
	@Public(retType = Double)
	def Promise<Double> sum(int first, long second, float third, double fourth)
	
	@Public(retType = Double)
	def Promise<Double> error()
}