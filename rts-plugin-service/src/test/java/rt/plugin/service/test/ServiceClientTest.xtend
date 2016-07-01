package rt.plugin.service.test

import org.junit.Test
import rt.plugin.service.ServiceClient
import rt.pipeline.IMessageBus.Message
import rt.pipeline.DefaultMessageBus

class ServiceClientTest {
	
	@Test
	def void verifyCall() {
		val mb = new DefaultMessageBus
		mb.listener('clt:address')[ msg |
			val reply = switch msg.cmd {
				case 'hello': new Message => [id=msg.id clt=msg.clt cmd='ok']
				case 'sum':   new Message => [id=msg.id clt=msg.clt cmd='ok' result=13.4]
				case 'error': new Message => [id=msg.id clt=msg.clt cmd='error' result='Error message!']
			}
			
			mb.publish(reply.clt + '+' + reply.id, reply)
		]
		
		val srvClient = new ServiceClient(mb, 'srv:address', 'clt:address')
		val srvProxy = srvClient.create('test', SrvInterface)
		
		srvProxy.hello('Alex').then[
			println('REPLY-OK')
		]

		srvProxy.sum(2, 3L, 3.4f, 5.0).then[
			println('REPLY-OK: ' + it)
		]
		
		srvProxy.error.then([ println('REPLY-OK!') ], [ println('REPLY-ERROR: ' + it) ])
	}
}