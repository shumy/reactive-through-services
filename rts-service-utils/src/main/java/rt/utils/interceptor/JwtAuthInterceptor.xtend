package rt.utils.interceptor

import java.util.List
import org.jose4j.jwk.HttpsJwks
import org.jose4j.jwt.consumer.JwtConsumer
import org.jose4j.jwt.consumer.JwtConsumerBuilder
import org.jose4j.keys.resolvers.HttpsJwksVerificationKeyResolver
import org.slf4j.LoggerFactory
import rt.data.Data
import rt.pipeline.IComponent
import rt.pipeline.UserInfo
import rt.pipeline.pipe.PipeContext
import rt.plugin.service.CtxHeaders
import rt.data.Validation

@Data(metadata = false)
class JwtAuthInterceptor implements IComponent {
	transient static val logger = LoggerFactory.getLogger(JwtAuthInterceptor)
	transient var JwtConsumer jwtConsumer
	
	val String jwksUrl
	val String issuer
	val String audience
	
	@Validation
	def void constructor() {
		val httpsJkws = new HttpsJwks(jwksUrl)
		val httpsJwksKeyResolver = new HttpsJwksVerificationKeyResolver(httpsJkws)
		
		jwtConsumer = new JwtConsumerBuilder()
			.setRequireExpirationTime // the JWT must have an expiration time
			.setMaxFutureValidityInMinutes(300) // but the  expiration time can't be too crazy
			.setAllowedClockSkewInSeconds(30) // allow some leeway in validating time based claims to account for clock skew
			.setRequireSubject() // the JWT must have a subject claim
			.setExpectedIssuer(issuer) // whom the JWT needs to have been issued by
			.setExpectedAudience(audience) // to whom the JWT is intended for
			.setVerificationKeyResolver(httpsJwksKeyResolver)
			.build // create the JwtConsumer instance
	}
	
	override apply(PipeContext ctx) {
		/* opens a back-door after user is logged out!
		val userInfo = ctx.resource.object(UserInfo)
		if (userInfo != null) {
			ctx.object(UserInfo, userInfo)
			ctx.next
			return
		}*/
		
		val jwt = ctx.getAuthToken
		if (jwt != null) {
			try {
				val jwtClaims = jwtConsumer.processToClaims(jwt)
				logger.info('JWT validation succeeded: {}', jwtClaims)
				
				val email = jwtClaims.claimsMap.get('email') as String
				val groups = jwtClaims.claimsMap.get('groups') as List<String>
				
				ctx.process(email, groups)
				return
			} catch(Exception ex) {
				//access control in not evaluated here, the interceptor should always succeed.
				logger.warn('JWT validation failed: {} ', jwt)
			}
		}
		
		ctx.next
	}
	
	def getAuthToken(PipeContext ctx) {
		val headers = ctx.object(CtxHeaders)
		
		val token = headers.get('token')
		if (token !== null)
			return token
		
		val cookie = headers.get('cookie')
		if (cookie === null)
			return null
		
		val cEntries = cookie.split(';')
		for(entry: cEntries) {
			val keyValue = entry.trim.split('=')
			
			if (keyValue.get(0) == 'Authorization')
				return keyValue.get(1)
		}
		
		return null;
	}
	
	def void process(PipeContext ctx, String user, List<String> groups) {
		val userInfo = new UserInfo(user, groups)
		ctx.resource.object(UserInfo, userInfo)
		ctx.object(UserInfo, userInfo)
		
		ctx.next
	}
}