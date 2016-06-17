package rt.pipeline

import java.util.List
import java.util.Map

interface IMessageBus {
	def void publish(String address, Message msg)
	def IListener listener(String address, (Message) => void listener)
	
	public interface IListener {
		def void remove()
	}
	
	public static class Message {
		public static val String ID = 'id'
		public static val String CMD = 'cmd'
		public static val String CLIENT = 'client'
		public static val String PATH = 'path'
	
		public static val String ARGS = 'args'
		public static val String RESULT = 'result'
		
		public static val String OK = 'ok'
		public static val String ERROR = 'error'
		
		// from all
		public long id
		public String cmd
		public String client
		public String path
		
		// from request
		public List<Object> args
		
		// from response
		public Map<String, Object> result
		public String error
	}
}