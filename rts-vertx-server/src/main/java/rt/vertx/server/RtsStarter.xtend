package rt.vertx.server

import io.vertx.spi.cluster.hazelcast.HazelcastClusterManager
import io.vertx.core.VertxOptions
import io.vertx.core.AbstractVerticle
import io.vertx.core.http.HttpServerOptions

import static io.vertx.core.Vertx.*
import rt.pipeline.Registry
import rt.pipeline.IComponent
import rt.pipeline.pipe.PipeContext
import rt.pipeline.IMessageBus.Message

class RtsStarter extends AbstractVerticle {
	def static void main(String[] args) {
		var domain = args.get(0)
		var port = 9090
		
		if(args.length > 1) {
			port = Integer.parseInt(args.get(1))
		}
		
		val node = new RtsStarter(domain, port)
		val options = new VertxOptions => [
			clusterManager = new HazelcastClusterManager
		]
		
		factory.clusteredVertx(options)[
			if (succeeded) {
				result.deployVerticle(node)
			} else {
				System.exit(-1)
			}
		]
	}
	
	val String domain
	val int port
	
	new(String domain, int port) {
		this.domain = domain
		this.port = port
	}
	
	override def start() {
		val converter = new MessageConverter
		
		val server = vertx.createHttpServer(new HttpServerOptions => [
			tcpKeepAlive = true
		])
		
		val ping = new IComponent() {
			override getName() { return 'srv:ping' }
			
			override apply(PipeContext ctx) {
				//fire service on the client
				ctx.send(new Message => [id=1L cmd='hello' client='server' path='srv:test' args=#['Alex']])
			}
		}
		
		val registry = new Registry(domain, new VertxMessageBus(vertx.eventBus, converter))
		
		val pipeline = registry.createPipeline => [
			addService(ping)
			failHandler = [ println('PIPELINE-FAIL: ' + it) ]
		]
		
		val router = new VertxRouter(server, converter) => [
			route('/ws', pipeline)
		]
		
		router.listen(port)
		println('''Node («domain», «port»)''')
	}
}