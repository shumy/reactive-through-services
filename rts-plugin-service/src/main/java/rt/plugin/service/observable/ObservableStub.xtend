package rt.plugin.service.observable

import java.util.ArrayList
import rt.async.observable.ObservableResult
import rt.pipeline.IResource
import rt.pipeline.IResourceProvider
import rt.pipeline.bus.Message

class ObservableStub<T> extends ObservableResult<T> {
	private val Class<T> retType
	private val String address
	
	private val IResource resource
	private val data = new ArrayList<Entry>
	
	private var boolean isReady = false
	private var boolean isEnded = false
	
	new(IResourceProvider resourceProvider, Class<T> retType, String address) {
		this.retType = retType
		this.address = address
		this.resource = resourceProvider.resource
		
		resource.subscribe(address, [
			if (cmd == Message.CMD_OK) {
				this.processNext(result(retType))
			} else if (cmd == Message.CMD_COMPLETE) {
				this.processComplete()
			} else if (cmd === Message.CMD_ERROR) {
				this.processError(result(Throwable))
			}
		])
		
		this.onCancel[
			resource.unsubscribe(address)
			resource.send(new Message => [
				clt = resource.client
				typ = Message.PUBLISH
				cmd = Message.CMD_CANCEL
				path = address
			])
		]
		
		this.onRequest[ n |
			resource.send(new Message => [
				clt = resource.client
				typ = Message.PUBLISH
				cmd = Message.CMD_REQUEST
				path = address
				result = n
			])
		]
	}
	
	override invoke(ObservableResult<T> sub) {
		this.isReady = true
		
		if (data.size !== 0) {
			data.forEach[
				if (isValue === true) {
					next(value as T)
				} else {
					resource.unsubscribe(address)
					reject(value as Throwable)
				}
			]
		}

		if (isEnded) {
			complete
			resource.unsubscribe(address)
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
			resource.unsubscribe(address)
			complete
		} else
			isEnded = true
	}
	
	private def processError(Throwable error) {
		if (isReady) {
			resource.unsubscribe(address)
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