package rt.plugin.service

import rt.pipeline.IMessageBus
import java.util.UUID
import java.lang.reflect.Proxy

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
	
	def <T> T create(String srvName, Class<T> srvInterface) {
		val srvPath = 'srv:' + srvName
		val srvProxy = Proxy.newProxyInstance(srvInterface.classLoader, #[srvInterface])[ proxy, srvMeth, srvArgs |
			return new ServicePoint(this, srvPath, srvMeth.name, srvArgs.toList, srvMeth.returnType).promise
		]
		
		return srvProxy as T
	}
	

}