package rt.vertx.server.intercept

import com.auth0.jwt.JWTVerifier
import com.auth0.jwt.pem.X509CertUtils
import com.google.gson.Gson
import java.util.Base64
import rt.data.Data
import rt.data.IDataRepository
import rt.pipeline.IComponent
import rt.pipeline.UserInfo
import rt.pipeline.pipe.PipeContext
import rt.plugin.service.CtxHeaders
import rt.plugin.service.ServiceException

interface JwtProvider {
	def String getPubKey(String kid)
	def String getAudience()
	def String getIssuer()
}

@Data(metadata = false)
class JwtAuthInterceptor implements IComponent {
	transient val gson = new Gson
	
	val JwtProvider provider
	val IDataRepository<UserInfo> users
	
	override apply(PipeContext ctx) {
		val userInfo = ctx.resource.object(UserInfo)
		if (userInfo != null) {
			println('Auth-User: ' + userInfo.name)
			ctx.object(UserInfo, userInfo)
			ctx.next
			return
		}
		
		val headers = ctx.object(CtxHeaders)
		if (headers != null && headers.get('auth') == 'jwt') {
			try {
				val token = headers.get('token')
				
				val header = getHeader(token)
				val pubKey = provider.getPubKey(header.kid)
				val cert = X509CertUtils.parse(pubKey)
				
				val jwtVerifier = new JWTVerifier(cert.publicKey, provider.audience, provider.issuer)
				val jwt = jwtVerifier.verify(token)
				
				ctx.process(jwt.get('email') as String)
			} catch(Exception ex) {
				ex.printStackTrace
				ctx.fail(new ServiceException(401, '''Token validation fail'''))
			}
			
			return
		}
		
		ctx.next
	}
	
	def void process(PipeContext ctx, String user) {
		println('Auth-User: ' + user)

		val userInfo = users.get(user)
		if (userInfo != null) {
			ctx.resource.object(UserInfo, userInfo)
			ctx.object(UserInfo, userInfo)
		}
		
		ctx.next
	}
	
	
	
	private def getHeader(String token) {
		val splits = token.split('\\.')
		val header = new String(Base64.decoder.decode(splits.get(0)), 'UTF-8')
		
		return gson.fromJson(header, TokenHeader)
	}
}

@Data
class TokenHeader {
	val String alg
	val String kid
}