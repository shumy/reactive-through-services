package rt.vertx.server

import io.vertx.core.Vertx
import io.vertx.core.http.HttpServer
import io.vertx.core.http.HttpServerOptions
import org.eclipse.xtend.lib.annotations.Accessors
import rt.pipeline.pipe.Pipeline
import rt.vertx.server.web.WebRouter
import rt.vertx.server.ws.WsRouter

class DefaultVertxServer {
	@Accessors val HttpServer server
	@Accessors val Pipeline pipeline
	@Accessors val WsRouter wsRouter
	@Accessors val WebRouter webRouter
	
	new(Vertx vertx, String wsUri) {
		this.server = vertx.createHttpServer(new HttpServerOptions => [
			tcpKeepAlive = true
		])
		
		this.pipeline = new Pipeline
		this.wsRouter = new WsRouter(wsUri, server, pipeline)
		this.webRouter = new WebRouter(server, pipeline)
	}
	
	def void listen(int port) { server.listen(port) }
}