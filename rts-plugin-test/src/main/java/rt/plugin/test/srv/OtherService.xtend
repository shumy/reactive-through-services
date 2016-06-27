package rt.plugin.test.srv

import rt.plugin.service.Service
import rt.plugin.service.Public

@Service('other')
class OtherService {
	@Public
	def otherServiceHello() { return 'Hello' }
	
	@Public
	def void empty(String emptyArgs) { }
}