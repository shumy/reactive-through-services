package rt.plugin.test.srv

import java.util.Map
import rt.plugin.service.an.Service
import rt.plugin.service.an.Public

@Service
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