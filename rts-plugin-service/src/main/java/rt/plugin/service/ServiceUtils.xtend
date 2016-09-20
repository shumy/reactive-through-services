package rt.plugin.service

import org.eclipse.xtend.lib.annotations.Accessors

class ServiceUtils {
	static val local = new ThreadLocal<ServiceUtils> {
		override protected initialValue() { new ServiceUtils }
	}
	
	static def ServiceUtils get() { local.get }
	
	static def String getTokenType() { local.get.tokenType }
	static def void setTokenType(String tokenType) { local.get.tokenType = tokenType }
	
	static def String getAuthToken() { local.get.authToken }
	static def void setAuthToken(String token) { local.get.authToken = token }
	
	@Accessors var String tokenType = null
	@Accessors var String authToken = null
}