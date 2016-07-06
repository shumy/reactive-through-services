package rt.pipeline.test

import org.junit.Test
import rt.pipeline.pipe.channel.SendBuffer
import rt.pipeline.pipe.channel.ReceiveBuffer
import rt.pipeline.pipe.channel.ReceiveBuffer.ChannelPump
import java.nio.ByteBuffer
import org.junit.Assert

class ChannelBufferTest {
	
	@Test
	def void dataTransfer() {
		val sb = new StringBuilder
		
		val text = 'Just a string test!'
		val pump = new ChannelPump
		
		new ReceiveBuffer(pump) => [
			onBegin[ sb.append('begin: ' + it + ' ') ]
				it >> [ sb.append(new String(array)) ]
			onEnd[ sb.append(' end') ]
		]
		
		val buffer = ByteBuffer.wrap(text.getBytes('UTF-8'))
		new SendBuffer([ pump.pushSignal(it) ], [ pump.pushData(it) ]) => [
			begin('signal')
				it << buffer
			end
		]
		
		Assert.assertEquals(sb.toString, 'begin: signal Just a string test! end')
	}
}