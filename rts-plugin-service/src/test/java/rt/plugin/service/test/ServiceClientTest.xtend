package rt.plugin.service.test

import org.junit.Test
import rt.plugin.service.ServiceClient
import rt.pipeline.IMessageBus.Message

class ServiceClientTest {
	
	@Test
	def void verifyCall() {
		val cnv = new MessageConverter
		
		val mb = new MessageBus
		mb.listener('clt:address')[ msg |
			println('CALL: ' + cnv.toJson(msg))
			mb.publish(msg.client, new Message => [id=msg.id client=msg.client result='ok'])
		]
		
		val srvClient = new ServiceClient(mb, 'clt:address')
		val srvProxy = srvClient.create('test', SrvInterface)
		
		srvProxy.hello('Alex').then[
			//println('REPLY: ' + cnv.toJson(it))
		]
	}
}