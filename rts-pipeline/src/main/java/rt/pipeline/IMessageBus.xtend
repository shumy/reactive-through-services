package rt.pipeline

import java.util.List

interface IMessageBus {
	def void publish(String address, Message msg)
	def IListener listener(String address, (Message) => void listener)
	
	public interface IListener {
		def void remove()
	}
	
	public static class Message {
		public static val String OK = 'ok'
		public static val String ERROR = 'error'
		
		// from all
		public Long id
		public String cmd
		public String client
		public String path
		
		// from request
		public List<Object> args
		public transient List<String> argsString
		
		// from response
		public Object result
		public transient String resultString
		
		public String error
	}
}