package rt.node

import rt.node.annotation.Service
import rt.node.annotation.Public

@Service('other')
class OtherService {
	@Public
	def otherServiceHello() { return 'Hello' }
}