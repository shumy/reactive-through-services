package rt.plugin.test.srv

import java.util.Map
import rt.plugin.service.an.Service
import rt.plugin.service.an.Public

@Service(metadata = true)
class AnnotatedService {
	
	@Public
	def String hello(String firstName, String lastName) {
		return '''Hello «firstName» «lastName»!'''
	}
	
	@Public
	def double sum(int first, long second, float third, double fourth) {
		return first + second + third + fourth
	}
	
	@Public
	def Map<String, Object> alexBrothers(Map<String, Object> data) {
		return #{
			'name' -> data.get('name'),
			'age' -> data.get('age'),
			'brothers' -> #[ 'Jorge', 'Mary' ]
		}
	}
}