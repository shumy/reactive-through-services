package rt.vertx.server

import io.vertx.core.http.HttpServerOptions
import io.vertx.core.Vertx
import rt.pipeline.pipe.Pipeline
import org.eclipse.xtend.lib.annotations.Accessors
import rt.vertx.server.router.WsRouter
import rt.vertx.server.router.HttpRouter
import io.vertx.core.http.HttpServer

class DefaultVertxServer {
	@Accessors val HttpServer server
	@Accessors val Pipeline pipeline
	@Accessors val WsRouter wsRouter
	@Accessors val HttpRouter httpRouter
	
	new(Vertx vertx, String wsUri) {
		this.server = vertx.createHttpServer(new HttpServerOptions => [
			tcpKeepAlive = true
		])
		
		this.pipeline = new Pipeline
		this.wsRouter = new WsRouter(wsUri, server, pipeline)
		this.httpRouter = new HttpRouter(server, pipeline)
	}
	
	def void listen(int port) { server.listen(port) }
}