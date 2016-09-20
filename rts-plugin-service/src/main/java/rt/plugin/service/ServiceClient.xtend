package rt.plugin.service

import java.lang.reflect.Proxy
import java.util.HashMap
import java.util.Map
import java.util.concurrent.atomic.AtomicLong
import org.slf4j.LoggerFactory
import rt.async.AsyncUtils
import rt.async.observable.ObservableResult
import rt.async.promise.PromiseResult
import rt.async.pubsub.IMessageBus
import rt.async.pubsub.ISubscription
import rt.async.pubsub.Message
import rt.plugin.service.an.Public
import java.util.ArrayList

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
		if (ServiceUtils.tokenType !== null) {
			if (sendMsg.headers === null)
				sendMsg.headers = new HashMap<String, String>
			
			sendMsg.headers.put('auth', ServiceUtils.tokenType)
			sendMsg.headers.put('token', ServiceUtils.authToken)
		}
		
		if (anPublic.notif)
			bus.publish(address, sendMsg)
		else
			bus.send(address, sendMsg)[ replyMsg |
				logger.debug('REPLY id:{} clt:{} cmd:{}', replyMsg.id, replyMsg.clt, replyMsg.cmd)
				if (replyMsg.cmd == Message.CMD_OK) {
					result.resolve(replyMsg.result(anPublic.retType))
				} else if (replyMsg.cmd == Message.CMD_OBSERVABLE) {
					result.resolve(new RemoteObservable(bus, anPublic.retType, replyMsg.result(String)).observe)
				} else {
					val error = replyMsg.result(RuntimeException)
					result.reject(error)
				}
			]
	}
}

class RemoteObservable<T> extends ObservableResult<T> {
	private val IMessageBus bus
	private val Class<T> retType
	private val String address
	
	private val data = new ArrayList<Entry>
	private val ISubscription listener
	
	private var boolean isReady = false
	private var boolean isEnded = false
	
	new(IMessageBus bus, Class<T> retType, String address) {
		this.bus = bus
		this.retType = retType
		this.address = address
		
		//TODO: timeout for responses? -> remove listener...
		this.listener = bus.subscribe(address, [
			if (cmd == Message.CMD_OK) {
				this.processNext(result(retType))
			} else if (cmd == Message.CMD_COMPLETE) {
				this.processComplete()
			} else if (cmd === Message.CMD_ERROR) {
				this.processError(result(Throwable))
			}
		])
	}
	
	override invoke(ObservableResult<T> sub) {
		this.isReady = true
		
		if (data.size !== 0) {
			data.forEach[
				if (isValue === true) {
					next(value as T)
				} else {
					listener.remove
					reject(value as Throwable)
				}
			]
		}

		if (isEnded) {
			complete
			listener.remove
		}
	}
	
	private def processNext(T item) {
		if (isReady)
			next(item)
		else
			this.data.add(new Entry(true, item))
	}
	
	private def processComplete() {
		if (isReady) {
			listener.remove
			complete
		} else
			isEnded = true
	}
	
	private def processError(Throwable error) {
		if (isReady) {
			listener.remove
			reject(error)
		} else
			this.data.add(new Entry(false, error))
	}
	
	static class Entry {
		val boolean isValue
		val Object value
		
		new(boolean isValue, Object value) {
			this.isValue = isValue
			this.value = value
		}
	}
}
