# real-time-services

Using Xtend Active Annotations and Vertx.io server.
Main objective of this project is to define bidirectional services in the form of, ex:
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
* Client Stubs and Server Skeletons for several languages, first to support are (JavaScript / TypeScript, Java / Xtend)
* Service definition (API Schema)
* Service UI for testing.

Some objectives are similar to projects like [Swagger](http://swagger.io/)
The advantage of Xtend Active Annotations over other DSL's for code generation, is that we can mix the meta-programming, models and definitions with the user code.
* The code generation is easily controlled by developers. Other annotations can be added.
* The re-generation do not interfere with already existent user code.
* API definitions and implementations can still be separated (but in the same language), using interfaces.

### Why not REST API ?
The communication protocol is a custom JSON message system, using Websockets.
Although REST if fine, I'm experimenting alternatives that can acomplish more complex use cases, like:
* Creation of new extensions with annotation definitions and generators.
* Better support for other data communication schemes, like "pub/sub" [Reactive Streams](https://github.com/reactive-streams/reactive-streams-jvm/) with back pressure, notification events, ...
* Better support for bi-directional services without firewall problems. Network connections are made always in the same direction, but it's possible to deploy services both in server and client.

[WebSockets solves a few issues with REST, or HTTP in general](http://blog.arungupta.me/rest-vs-websocket-comparison-benchmarks/):
* **Bi-directional**: HTTP is a uni-directional protocol where a request is always initiated by client, server processes and returns a response, and then the client consumes it. WebSocket is a bi-directional protocol where there are no pre-defined message patterns such as request/response. Either client or server can send a message to the other party.
* **Full-duplex**: HTTP allows the request message to go from client to server and then server sends a response message to the client. At a given time, either client is talking to server or server is talking to client. WebSocket allows client and server to talk independent of each other.
* **Single TCP Connection**: Typically a new TCP connection is initiated for a HTTP request and terminated after the response is received. A new TCP connection need to be established for another HTTP request/response. For WebSocket, the HTTP connection is upgraded using standard [HTTP Upgrade mechanism](https://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.42) and client and server communicate over that same TCP connection for the lifecycle of WebSocket connection.
* **Lean protocol**: HTTP is a chatty protocol. Here is the set of HTTP headers sent in request message by Advanced REST Client Chrome extension.
```
POST /websocket-vs-rest-payload/webresources/rest HTTP/1.1\r\n
Host: localhost:8080\r\n
Connection: keep-alive\r\n
Content-Length: 11\r\n
User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/32.0.1700.107 Safari/537.36\r\n
Origin: chrome-extension://hgmloofddffdnphfgcellkdfbfbjeloo\r\n
Content-Type: text/plain \r\n
Accept: */*\r\n
Accept-Encoding: gzip,deflate,sdch\r\n
Accept-Language: en-US,en;q=0.8\r\n
\r\n
```

#### References
* [WebSockets vs REST: Understanding the Difference](https://www.pubnub.com/blog/2015-01-05-websockets-vs-rest-api-understanding-the-difference/)
* [REST vs WebSocket Comparison and Benchmarks](http://blog.arungupta.me/rest-vs-websocket-comparison-benchmarks/)

### Related to molymer 
Some investigation must be made to see if the molymer project can be useful for this project.
Some molymer ideas can be applied here. Like code generators config file and plugins.
