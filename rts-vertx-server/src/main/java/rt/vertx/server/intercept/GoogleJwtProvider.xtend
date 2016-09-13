package rt.vertx.server.intercept

import com.google.gson.Gson
import io.vertx.core.Vertx
import io.vertx.core.http.HttpClientOptions
import java.util.Map
import org.eclipse.xtend.lib.annotations.Accessors
import org.slf4j.LoggerFactory

class GoogleJwtProvider implements JwtProvider {
	static val logger = LoggerFactory.getLogger(GoogleJwtProvider)
	
	@Accessors val issuer = 'https://accounts.google.com'
	@Accessors val String audience
	
	val gson = new Gson()
	var Map<String, String> pubKeys = null
	
	//Public certs available at: https://www.googleapis.com/oauth2/v1/certs
	new(Vertx vertx, String audience) {
		this.audience = audience
		
		val httpOptions = new HttpClientOptions => [
			defaultHost = 'www.googleapis.com'
			defaultPort = 443
			ssl = true
		]
		
		val httpClient = vertx.createHttpClient(httpOptions)
		logger.info('Loading google public certs...')
		httpClient.getNow('/oauth2/v1/certs')[ resp |
			if (resp.statusCode != 200) {
				logger.error('Fail to load google public certs: {}', resp.statusMessage)
				throw new RuntimeException('Fail to load google public certs!')
			}
			
			resp.bodyHandler[
				val body = new String(bytes, 'UTF8')
				pubKeys = gson.fromJson(body, Map)
			]
		]
	}
	
	override getPubKey(String kid) { pubKeys.get(kid) }
}