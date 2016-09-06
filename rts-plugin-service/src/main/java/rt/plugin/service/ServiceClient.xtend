package rt.plugin.service

import java.lang.reflect.Proxy
import java.util.Map
import java.util.concurrent.atomic.AtomicLong
import org.slf4j.LoggerFactory
import rt.async.AsyncUtils
import rt.async.promise.PromiseResult
import rt.async.pubsub.IMessageBus
import rt.async.pubsub.Message
import rt.plugin.service.an.Public

class ServiceClient {
	static val logger = LoggerFactory.getLogger('PROXY')
	static val clientSeq = new AtomicLong(0L)
	
	val IMessageBus bus
	val String server
	val Map<String, String> redirects
	
	val String uuid
	val AtomicLong msgID = new AtomicLong(1)		//increment for every new message
	
	new(IMessageBus bus, String server, String client, Map<String, String> redirects) {
		this.bus = bus
		this.server = server
		this.redirects = redirects
		
		this.uuid = ServiceClient.clientSeq.addAndGet(1) + ':' + client
	}
	
	def <T> T create(String srvPath, Class<T> srvProxyInterface) {
		val address = redirects.get(srvPath) ?: server
		
		val srvProxy = Proxy.newProxyInstance(srvProxyInterface.classLoader, #[srvProxyInterface])[ proxy, srvMeth, srvArgs |
			val anPublic = srvMeth.getAnnotation(Public)
			if (anPublic == null)
				throw new RuntimeException('@Public annotation with return type is mandatory for a ServiceProxy! In method: ' + srvMeth.name)
			
			val PromiseResult<Object> result = [
				val sendMsg = new Message => [id=msgID.andIncrement clt=uuid path=srvPath cmd=srvMeth.name args=srvArgs]
				logger.debug('SEND id:{} clt:{} path:{} cmd:{}', sendMsg.id, sendMsg.clt, sendMsg.path, sendMsg.cmd)
				
				//protect against multi thread...
				if (AsyncUtils.worker)
					AsyncUtils.schedule[ send(address, sendMsg, it, anPublic) ]
				else
					send(address, sendMsg, it, anPublic)
			]
			return result.promise
		]
		
		return srvProxy as T
	}
	
	private def send(String address, Message sendMsg, PromiseResult<Object> result, Public anPublic) {
		if (anPublic.notif)
			bus.publish(address, sendMsg)
		else
			bus.send(address, sendMsg)[ replyMsg |
				logger.debug('REPLY id:{} clt:{} cmd:{}', replyMsg.id, replyMsg.clt, replyMsg.cmd)
				if (replyMsg.cmd == Message.CMD_OK) {
					result.resolve(replyMsg.result(anPublic.retType))
				} else {
					val error = replyMsg.result(RuntimeException)
					result.reject(error)
				}
			]
	}
}