package rt.plugin.service

import java.util.List
import rt.pipeline.IMessageBus.Message

class ServicePoint<T> extends PromiseResult<T> {
	val ServiceClient parent
	val String srvPath
	val String srvCmd
	val List<Object> srvArgs
	val Class<T> retType
	
	package new(ServiceClient parent, String srvPath, String srvCmd, List<Object> srvArgs, Class<T> retType) {
		this.parent = parent
		this.srvPath = srvPath
		this.srvCmd = srvCmd
		this.srvArgs = srvArgs
		this.retType = retType
	}
	
	override void invoke((T) => void resolve, (RuntimeException) => void reject) {
		parent.msgID++
		val clientID = '''«parent.uuid»+«parent.msgID»'''
		val sendMsg = new Message => [id=parent.msgID client=clientID path=srvPath cmd=srvCmd args=srvArgs]
		
		parent.bus.listener(clientID)[ replyMsg |
			println('ServicePoint-Reply')
			resolve.apply(replyMsg.result(retType))
		]
		
		//TODO: how to implement timeout?
		
		parent.bus.publish(parent.address, sendMsg)
	}
}