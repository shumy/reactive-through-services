package rt.vertx.server.intercept

import com.auth0.jwt.JWTVerifier
import com.auth0.jwt.pem.X509CertUtils
import rt.pipeline.IComponent
import rt.pipeline.pipe.PipeContext
import rt.plugin.service.ServiceException
import rt.plugin.service.an.UserInfo

class JwtAuthInterceptor implements IComponent {
	val JWTVerifier jwtVerifier
	
	val pubKey = '-----BEGIN CERTIFICATE-----MIIDJjCCAg6gAwIBAgIIBv0A+SV8neowDQYJKoZIhvcNAQEFBQAwNjE0MDIGA1UEAxMrZmVkZXJhdGVkLXNpZ25vbi5zeXN0ZW0uZ3NlcnZpY2VhY2NvdW50LmNvbTAeFw0xNjA4MzExMTQzMzRaFw0xNjA5MDMxMjEzMzRaMDYxNDAyBgNVBAMTK2ZlZGVyYXRlZC1zaWdub24uc3lzdGVtLmdzZXJ2aWNlYWNjb3VudC5jb20wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCodSZB3DRFZNY+EIK0TvSz4JyRd6Xvf7LxheqkwSnIrF1so8gvMNoktNVbLk8kZjNJ41jOAq7q7qXABiaI5sGR025xetMoZ5it+VYxk/fUvGoEpcQR7BLFTzLqQNx2itDxTigSXaGIpX4OeVZ/T//7xyYCX4iKDwff9Es5YnZOYquZ6qBG+nv6zcKbwk2NNt8rHTedNlAK8uvfBpWmiMIWGeDzFMRPG0laYfpoBrx8HgnA9eQDAUECWuur+C/1mxWOrG9mmmnmt9qZaP8cESAawMA5MN/EXgIhej2d5Zb2iAF/uhFBY4qtBMlRut8ESwFhWty9lytNFCRFim10MTdLAgMBAAGjODA2MAwGA1UdEwEB/wQCMAAwDgYDVR0PAQH/BAQDAgeAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMCMA0GCSqGSIb3DQEBBQUAA4IBAQAb7ghvwsmdYGJahQL4qXYc23885jZJdcUTYX+LHc0bbafHB1vUah4RkAdiXzitFqLjjxS/cp6oitO+kzU6YEebhuIRCfO+Af8gH5t94OzUGxVPFuZY7fCUllBXWf/u8O9Vn7SXNNyfJMZQmMpGU8VFuARfOyikc5y0gNrwSGKSWr+7tgdCmBJWJtFWjrpLIl/OOriCOhyqBq8n7xpANlI9Le5qV1nv///nPCLN6KoGpB5sWCs6MxAHoHTz/lYWbV4oxzuTW2MwY83Y12rnxGJgCGCCbXhK5thIoTSst1k00M/1SPIOOR2L2WkPLsbaXJ5ffEaGU0AAtgPqpgzX8dP3-----END CERTIFICATE-----'
	
	val audience = '61929327789-7an73tpqqk1rrt2veopv1brsfcoetmrj.apps.googleusercontent.com'
	val issuer = 'accounts.google.com'
	
	new() {
		val cert = X509CertUtils.parse(pubKey)
		jwtVerifier = new JWTVerifier(cert.publicKey, audience, issuer)
	}
	
	override apply(PipeContext ctx) {
		val auth = ctx.message.auth
		if (auth != null && auth.get('type') == 'jwt') {
			val token = auth.get('token')
			try {
				val jwt = jwtVerifier.verify(token)
				ctx.process(jwt.get('email') as String)
			} catch(Exception ex) {
				ctx.fail(new ServiceException(401, '''Token validation fail'''))
			}
			
			return
		}
		
		ctx.next
	}
	
	def void process(PipeContext ctx, String user) {
		println('Auth-User: ' + user)

		//TODO: get UserInfo from a DB or other service
		ctx.object(UserInfo, new UserInfo(user, #['admin']))
		ctx.next
	}
}

/*
class JwtAuthInterceptor implements IComponent {
	val gson = new Gson
	val cache = new HashMap<String, AuthResponse>
	
	val HttpClient httpClient
	val JWTVerifier jwtVerifier
	
	val clientID = '61929327789-7an73tpqqk1rrt2veopv1brsfcoetmrj.apps.googleusercontent.com'
	val pubKey = '-----BEGIN CERTIFICATE-----MIIDJjCCAg6gAwIBAgIIBv0A+SV8neowDQYJKoZIhvcNAQEFBQAwNjE0MDIGA1UEAxMrZmVkZXJhdGVkLXNpZ25vbi5zeXN0ZW0uZ3NlcnZpY2VhY2NvdW50LmNvbTAeFw0xNjA4MzExMTQzMzRaFw0xNjA5MDMxMjEzMzRaMDYxNDAyBgNVBAMTK2ZlZGVyYXRlZC1zaWdub24uc3lzdGVtLmdzZXJ2aWNlYWNjb3VudC5jb20wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCodSZB3DRFZNY+EIK0TvSz4JyRd6Xvf7LxheqkwSnIrF1so8gvMNoktNVbLk8kZjNJ41jOAq7q7qXABiaI5sGR025xetMoZ5it+VYxk/fUvGoEpcQR7BLFTzLqQNx2itDxTigSXaGIpX4OeVZ/T//7xyYCX4iKDwff9Es5YnZOYquZ6qBG+nv6zcKbwk2NNt8rHTedNlAK8uvfBpWmiMIWGeDzFMRPG0laYfpoBrx8HgnA9eQDAUECWuur+C/1mxWOrG9mmmnmt9qZaP8cESAawMA5MN/EXgIhej2d5Zb2iAF/uhFBY4qtBMlRut8ESwFhWty9lytNFCRFim10MTdLAgMBAAGjODA2MAwGA1UdEwEB/wQCMAAwDgYDVR0PAQH/BAQDAgeAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMCMA0GCSqGSIb3DQEBBQUAA4IBAQAb7ghvwsmdYGJahQL4qXYc23885jZJdcUTYX+LHc0bbafHB1vUah4RkAdiXzitFqLjjxS/cp6oitO+kzU6YEebhuIRCfO+Af8gH5t94OzUGxVPFuZY7fCUllBXWf/u8O9Vn7SXNNyfJMZQmMpGU8VFuARfOyikc5y0gNrwSGKSWr+7tgdCmBJWJtFWjrpLIl/OOriCOhyqBq8n7xpANlI9Le5qV1nv///nPCLN6KoGpB5sWCs6MxAHoHTz/lYWbV4oxzuTW2MwY83Y12rnxGJgCGCCbXhK5thIoTSst1k00M/1SPIOOR2L2WkPLsbaXJ5ffEaGU0AAtgPqpgzX8dP3-----END CERTIFICATE-----'
	val issuer = 'accounts.google.com'
	
	new(Vertx vertx) {
		val httpOptions = new HttpClientOptions => [
			ssl = true
			defaultHost = 'www.googleapis.com'
			defaultPort = 443
		]
		
		httpClient = vertx.createHttpClient(httpOptions)
		
		val cert = X509CertUtils.parse(pubKey)
		jwtVerifier = new JWTVerifier(cert.publicKey)
	}
	
	override apply(PipeContext ctx) {
		val auth = ctx.message.auth
		if (auth != null && auth.get('type') == 'jwt' && auth.get('idp') == 'google') {
			val token = auth.get('token')
			
			val id_token = auth.get('id_token')
			val jwt = jwtVerifier.verify(id_token)
			jwt.keySet.forEach[ key |
				println('''(«key», «jwt.get(key)»)''')
			]
			
			val cResponse = cache.get(auth.get('token'))
			if (cResponse == null) {
				httpClient.getNow('/oauth2/v1/tokeninfo?access_token=' + token)[
					if (statusCode != 200) {
						ctx.fail(new ServiceException(statusCode, '''Token validation fail: «it.statusMessage»'''))
						return
					}
					
					bodyHandler[
						val response = gson.fromJson(toString('UTF-8'), AuthResponse)
						if (response.error != null) {
							ctx.fail(new ServiceException(401, '''Token validation fail: «response.error»'''))
						} else {
							cache.put(token, response)
							AsyncUtils.timer(response.expires_in * 1000)[
								println('Token-Expired: ' + token)
								cache.remove(token)
							]
							
							ctx.process(response.email)
						}
					]
					
					exceptionHandler[
						printStackTrace
						ctx.fail(new ServiceException(401, '''Token validation fail: «message»'''))
					]
				]
			} else {
				ctx.process(cResponse.email)
			}
			
			return
		}
		
		ctx.next
	}
	
	def void process(PipeContext ctx, String user) {
		println('Auth-User: ' + user)

		//TODO: get UserInfo from a DB or other service
		ctx.object(UserInfo, new UserInfo(user, #['admin']))
		ctx.next
	}
}

class AuthResponse {
	public String issued_to
	public String scope
	public String email
	public boolean verified_email
	public String access_type
	
	public long expires_in //in seconds
	
	public String error
}
*/

/*
	(iss, accounts.google.com)
	(at_hash, rm0s7NrTspQWqmzuSIRZXQ)
	(aud, 61929327789-7an73tpqqk1rrt2veopv1brsfcoetmrj.apps.googleusercontent.com)
	(sub, 106540162364589320349)
	(email_verified, true)
	(azp, 61929327789-7an73tpqqk1rrt2veopv1brsfcoetmrj.apps.googleusercontent.com)
	(email, micaelpedrosa@gmail.com)
	(iat, 1472744373)
	(exp, 1472747973)
 */