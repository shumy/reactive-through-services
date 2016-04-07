# remote-entity (experimental)

Using Xtend Active Annotations and Vertx.io server.
Main objective of this project is to define services in the form of, ex:
```
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
}
```

And then, from a unique definition, generate code for:
* Client Stubs (JavaScript / TypeScript) and Server Skeletons (Java)
* Service definition (API Schema)
* Service UI for testing.

The advantage of Xtend Active Annotations over Xtext DSL for and code generation, is that we can mix the meta-programming, models and definitions with the user code. 
The code generation is easily controlled by developers. Other annotations can be added.

Some investigation must be made to see if the molymer project can be useful for this project.
Some molymer ideas can be applied here. Like code generators config file and plugins.
