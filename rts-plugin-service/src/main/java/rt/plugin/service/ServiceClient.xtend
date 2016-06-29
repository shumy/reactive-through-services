package rt.plugin.service

import rt.pipeline.IMessageBus
import java.util.UUID
import java.lang.reflect.Proxy
import rt.pipeline.IMessageBus.Message

class ServiceClient {
	package val IMessageBus bus
	package val String address
	
	package val String uuid 		//just a random reply point
	package var long msgID = 0		//increment for every new message
	
	new(IMessageBus bus, String address) {
		this.bus = bus
		this.address = address
		
		this.uuid = UUID.randomUUID.toString
	}
	
	new(IMessageBus bus) {
		this(bus, bus.defaultAddress)
	}
	
	def <T> T create(String srvName, Class<T> srvInterface) {
		val srvPath = 'srv:' + srvName
		val srvProxy = Proxy.newProxyInstance(srvInterface.classLoader, #[srvInterface])[ proxy, srvMeth, srvArgs |
			val PromiseResult<Object> result = [ resolve, reject |
				msgID++
				val replyID = '''«uuid»+«msgID»'''
				val sendMsg = new Message => [id=msgID clt=uuid path=srvPath cmd=srvMeth.name args=srvArgs]
				
				bus.listener(replyID)[ replyMsg |
					if (replyMsg.cmd == Message.OK) {
						val anPublic = srvMeth.getAnnotation(Public)
						if (anPublic == null)
							throw new RuntimeException('@Public annotation with return type is mandatory for a ServiceProxy!')
						
						resolve.apply(replyMsg.result(anPublic.retType))
					} else {
						reject.apply(replyMsg.result(String))
					}
				]
				
				//TODO: how to implement timeout?
				bus.publish(address, sendMsg)
			] 
			
			return result.promise
		]
		
		return srvProxy as T
	}
	

}