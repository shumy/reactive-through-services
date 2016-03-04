package rt.node

import io.vertx.spi.cluster.hazelcast.HazelcastClusterManager
import io.vertx.core.VertxOptions
import io.vertx.core.AbstractVerticle
import io.vertx.core.http.HttpServerOptions
import rt.node.pipeline.use.ValidatorInterceptor

import static io.vertx.core.Vertx.*

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
		val server = vertx.createHttpServer(new HttpServerOptions => [
			tcpKeepAlive = true
		])

		val registry = new Registry(domain, vertx)
		
		val pipeline = registry.createPipeline => [
			addInterceptor(new ValidatorInterceptor)
			failHandler = [ println("PIPELINE-FAIL: " + it) ]
		]
		
		val router = new Router(server) => [
			route("/ws", pipeline)
		]
		
		router.listen(port)
		println('''Node («domain», «port»)''')
	}
}