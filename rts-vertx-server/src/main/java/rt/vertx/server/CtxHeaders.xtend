package rt.vertx.server

import java.util.HashMap
import org.eclipse.xtend.lib.annotations.Accessors

class CtxHeaders {
	@Accessors val headers = new HashMap<String, String>
	
	def get(String key) {
		return headers.get(key)
	}
	
	def void add(String key, String value) {
		headers.put(key, value)
	}
	
	def void remove(String key) {
		headers.remove(key)
	}
	
	def void printAll() {
		headers.forEach[key, value | println('  ' + key + ': ' + value) ]
	}
}