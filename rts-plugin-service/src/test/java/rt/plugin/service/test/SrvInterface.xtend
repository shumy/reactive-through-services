package rt.plugin.service.test

import rt.plugin.service.Promise

interface SrvInterface {
	def Promise<Void> hello(String name)
	def Promise<Double> sum(int first, long second, float third, double fourth)
	def Promise<Double> error()
}