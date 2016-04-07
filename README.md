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

Some objectives are similar to projects like [Swagger](http://swagger.io/)
The advantage of Xtend Active Annotations over DSL's for code generation, is that we can mix the meta-programming, models and definitions with the user code.
* The code generation is easily controlled by developers. Other annotations can be added.
* The re-generation do not interfere with already existent user code.


### Why not REST API ?
The communication protocol is a custom JSON message system, using Websockets. 
Although REST if fine, I'm experimenting alternatives that can acomplish more complex use cases.
* That can be extended with other annotation definitions and generators.
* That can support other data communication schemes, like "pub/sub" [Reactive Streams](https://github.com/reactive-streams/reactive-streams-jvm/) with back pressure, notification events, ...

### Related to molymer 
Some investigation must be made to see if the molymer project can be useful for this project.
Some molymer ideas can be applied here. Like code generators config file and plugins.
