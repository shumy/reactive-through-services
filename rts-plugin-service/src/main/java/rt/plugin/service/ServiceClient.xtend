package rt.plugin.service

import rt.pipeline.IMessageBus
import java.lang.reflect.Proxy
import rt.pipeline.IMessageBus.Message
import java.util.concurrent.atomic.AtomicLong
import rt.plugin.service.an.Public
import rt.pipeline.promise.PromiseResult
import rt.pipeline.pipe.use.ChannelInterface
import rt.plugin.service.an.ServiceProxy

class ServiceClient {
	static val clientSeq = new AtomicLong(0L)
	
	val IMessageBus bus
	val String server
	
	val String uuid
	var long msgID = 0		//increment for every new message
	
	new(IMessageBus bus, String server, String client) {
		this.bus = bus
		this.server = server
		
		this.uuid = ServiceClient.clientSeq.addAndGet(1) + ':' + client
	}
	
	def <T> T create(String srvPath, Class<T> srvProxyInterface) {
		val anProxy = srvProxyInterface.getAnnotation(ServiceProxy)
		
		//TODO: need to remove this hack, replace by interface redirects...
		
		val address = if (anProxy != null && anProxy.value == ChannelInterface) server + '/ch:req' else server
		
		val srvProxy = Proxy.newProxyInstance(srvProxyInterface.classLoader, #[srvProxyInterface])[ proxy, srvMeth, srvArgs |
			val PromiseResult<Object> result = [ resolve, reject |
				msgID++
				val sendMsg = new Message => [id=msgID clt=uuid path=srvPath cmd=srvMeth.name args=srvArgs]
				
				bus.send(address, sendMsg)[ replyMsg |
					if (replyMsg.cmd == Message.CMD_OK) {
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