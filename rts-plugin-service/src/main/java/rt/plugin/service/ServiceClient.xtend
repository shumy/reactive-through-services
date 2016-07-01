package rt.plugin.service

import rt.pipeline.IMessageBus
import java.lang.reflect.Proxy
import rt.pipeline.IMessageBus.Message
import java.util.concurrent.atomic.AtomicLong
import rt.plugin.service.an.Public

class ServiceClient {
	private static val clientSeq = new AtomicLong(0L)
	
	package val IMessageBus bus
	package val String server
	
	package val String uuid
	package var long msgID = 0		//increment for every new message
	
	new(IMessageBus bus, String server, String client) {
		this.bus = bus
		this.server = server
		
		this.uuid = ServiceClient.clientSeq.addAndGet(1) + ':' + client
	}
	
	def <T> T create(String srvName, Class<T> srvInterface) {
		val srvPath = 'srv:' + srvName
		val srvProxy = Proxy.newProxyInstance(srvInterface.classLoader, #[srvInterface])[ proxy, srvMeth, srvArgs |
			val PromiseResult<Object> result = [ resolve, reject |
				msgID++
				val sendMsg = new Message => [id=msgID clt=uuid path=srvPath cmd=srvMeth.name args=srvArgs]
				
				bus.send(server, sendMsg)[ replyMsg |
					if (replyMsg.cmd == Message.OK) {
						val anPublic = srvMeth.getAnnotation(Public)
						if (anPublic == null)
							throw new RuntimeException('@Public annotation with return type is mandatory for a ServiceProxy!')
						
						resolve.apply(replyMsg.result(anPublic.retType))
					} else {
						reject.apply(replyMsg.result(String))
					}
				]
			] 
			
			return result.promise
		]
		
		return srvProxy as T
	}
}