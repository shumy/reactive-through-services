package rt.plugin.service

import org.eclipse.xtend.lib.annotations.Accessors

class ServiceException extends RuntimeException {
	@Accessors val int httpCode
	
	new(int httpCode, String message) {
		super(message)
		this.httpCode = httpCode
	}
}