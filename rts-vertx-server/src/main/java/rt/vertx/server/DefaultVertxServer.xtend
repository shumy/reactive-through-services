package rt.vertx.server

import io.vertx.core.Vertx
import io.vertx.core.http.HttpServer
import io.vertx.core.http.HttpServerOptions
import org.eclipse.xtend.lib.annotations.Accessors
import rt.async.AsyncUtils
import rt.pipeline.DefaultMessageConverter
import rt.pipeline.pipe.Pipeline
import rt.vertx.server.web.WebRouter
import rt.vertx.server.ws.WsRouter
import rt.async.pubsub.IMessageBus

class DefaultVertxServer {
	@Accessors val HttpServer server
	@Accessors val Pipeline pipeline
	@Accessors val WsRouter wsRouter
	@Accessors val WebRouter webRouter
	
	@Accessors val converter = new DefaultMessageConverter
	
	def IMessageBus getMb() { return pipeline.mb }
	
	package val Vertx vertx
	
	new(Vertx vertx, String wsBaseRoute, String webBaseRoute) {
		this.vertx = vertx
		
		this.server = vertx.createHttpServer(new HttpServerOptions => [
			tcpKeepAlive = true
		])
		
		this.pipeline = new Pipeline
		this.wsRouter = new WsRouter(this, wsBaseRoute)
		this.webRouter = new WebRouter(this, webBaseRoute)
	}
	
	def void listen(int port) {
		AsyncUtils.set(new VertxAsyncUtils(vertx))
		server.listen(port)
	}
}