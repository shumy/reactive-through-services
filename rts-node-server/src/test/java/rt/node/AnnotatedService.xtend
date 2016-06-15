package rt.node

import rt.node.annotation.Service
import rt.node.annotation.Public

@Service("test")
class AnnotatedService {
	
	@Public
	def hello(String firstName, String lastName) {
		return '''Hello «firstName» «lastName»!'''
	}
	
	@Public
	def sum(int first, long second, float third, double fourth) {
		return first + second + third + fourth
	}
	
	@Public
	def alexBrothers() {
		return #{
			'name' -> 'Alex',
			'age' -> 35,
			'brothers' -> #[ 'Jorge', 'Mary' ]
		}
	}
}