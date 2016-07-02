package rt.plugin.test.srv

import rt.plugin.service.an.Service
import rt.plugin.service.an.Public

@Service
class OtherService {
	@Public
	def String otherServiceHello() { return 'Hello' }
	
	@Public
	def void empty(String emptyArgs) { }
}