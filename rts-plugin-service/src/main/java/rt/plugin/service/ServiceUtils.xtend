package rt.plugin.service

import org.eclipse.xtend.lib.annotations.Accessors
import rt.async.pubsub.IPublisher

class ServiceUtils {
	static val local = new ThreadLocal<ServiceUtils> {
		override protected initialValue() { new ServiceUtils }
	}
	
	static def ServiceUtils get() { local.get }
	
	static def String getTokenType() { local.get.tokenType }
	static def void setTokenType(String tokenType) { local.get.tokenType = tokenType }
	
	static def String getAuthToken() { local.get.authToken }
	static def void setAuthToken(String token) { local.get.authToken = token }
	
	static def IPublisher getPublisher() { local.get.publisher }
	static def void setPublisher(IPublisher publisher) { local.get.publisher = publisher }
	
	@Accessors var String tokenType = null
	@Accessors var String authToken = null
	
	@Accessors var IPublisher publisher = null
}