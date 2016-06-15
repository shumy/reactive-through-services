package rt.node

import rt.node.annotation.Service
import rt.node.annotation.Public
import java.util.Map

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
	def alexBrothers(Map<String, Object> data) {
		return #{
			'name' -> data.get('name'),
			'age' -> data.get('age'),
			'brothers' -> #[ 'Jorge', 'Mary' ]
		}
	}
}