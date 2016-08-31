package rt.vertx.server.intercept

import com.google.gson.Gson
import io.vertx.core.http.HttpClient
import java.util.HashMap
import rt.pipeline.IComponent
import rt.pipeline.pipe.PipeContext
import io.vertx.core.Vertx
import io.vertx.core.http.HttpClientOptions

class GoogleAuthIntercept implements IComponent {
	val gson = new Gson
	val cache = new HashMap<String, AuthResponse> //TODO: how to handle token expiration, and remove on resource close?
	
	val HttpClient httpClient
	
	new(Vertx vertx) {
		val httpOptions = new HttpClientOptions => [
			ssl = true
			defaultHost = 'www.googleapis.com'
			defaultPort = 443
		]
		
		httpClient = vertx.createHttpClient(httpOptions)
	}
	
	override apply(PipeContext ctx) {
		val auth = ctx.message.auth
		if (auth != null && auth.type == 'oauth2' && auth.idp == 'google') {
			val time = System.currentTimeMillis / 1000
			
			val cResponse = cache.get(auth.token)
			if (cResponse == null) {
				httpClient.getNow('/oauth2/v1/tokeninfo?access_token=' + auth.token)[
					
					bodyHandler[
						val result = toString('UTF-8')
						
						val response = gson.fromJson(result, AuthResponse)
						if (response.error != null) {
							ctx.fail(new RuntimeException('''Token validation fail: «response.error»'''))
						} else {
							response.started_in = time
							cache.put(auth.token, response)
							ctx.process(response.email)
						}
					]
					
					exceptionHandler[
						println('GoogleAuthIntercept-Error:')
						printStackTrace
						
						ctx.fail(new RuntimeException('''Token validation fail: «message»'''))
					]
				]
			} else {
				if (cResponse.started_in + cResponse.expires_in < time)
					ctx.fail(new RuntimeException('''Token validation fail: token_expired'''))
				else
					ctx.process(cResponse.email)
			}
			
			return
		}
		
		ctx.next
	}
	
	def void process(PipeContext ctx, String user) {
		println('Auth-User: ' + user)
		//TODO: process user context
		
		ctx.next
	}
}

class AuthResponse {
	public String issued_to
	public String scope
	public String email
	public boolean verified_email
	public String access_type
	
	public long started_in
	public long expires_in //in seconds
	
	public String error
}