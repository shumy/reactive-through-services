package rt.async.pubsub

import java.util.List

public class Message {
	//message types...
	public static val String PUBLISH = 'pub'
	public static val String SEND = 'snd'
	public static val String REPLY = 'rpl'
	
	//reply command types...
	public static val String CMD_OK = 'ok'
	public static val String CMD_ERROR = 'err'
	public static val String CMD_TIMEOUT = 'tout'
	
	// from all
	public Long id
	public String typ
	public String cmd
	public String clt
	public String path
	
	public Auth auth
	
	// from request
	transient (Class<?>[]) => List<Object> argsConverter = null
	List<Object> args = null
	
	// from response
	transient (Class<?>) => Object resultConverter = null
	Object res = null
	
	new() {}
	new((Class<?>[]) => List<Object> argsConverter, (Class<?>) => Object resultConverter) {
		this.argsConverter = argsConverter
		this.resultConverter = resultConverter
	}
	
	def replyID() { '''«clt»+«id»'''.toString }
	
	def void setArgs(List<Object> args) { this.args = args }
	def List<Object> args(Class<?> ...types) {
		if (args == null)
			args = argsConverter?.apply(types)
		return args
	}
	
	def void setResult(Object value) { this.res = value }
	def <T> T result(Class<T> type) {
		if (res == null)
			res = resultConverter?.apply(type)
		return res as T
	}
}

public class Auth {
	public val String type
	public val String token
	public val String idp
	
	new(String type, String token, String idp) {
		this.type = type
		this.token = token
		this.idp = idp
	}
}
