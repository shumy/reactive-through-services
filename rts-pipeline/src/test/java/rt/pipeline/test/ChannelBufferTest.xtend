package rt.pipeline.test

import java.io.File
import java.nio.ByteBuffer
import java.nio.channels.FileChannel
import java.nio.file.Paths
import java.nio.file.StandardOpenOption
import java.util.Arrays
import org.junit.Assert
import org.junit.Test
import rt.pipeline.pipe.channel.ChannelPump
import rt.pipeline.pipe.channel.ReceiveBuffer
import rt.pipeline.pipe.channel.SendBuffer
import rt.pipeline.promise.AsyncUtils

class ChannelBufferTest {
	val outPump = new ChannelPump
	val inPump = new ChannelPump
	
	@Test
	def void dataTransfer() {
		AsyncUtils.setDefault
		val text = 'Just a string test!'
		
		val sb = new StringBuilder
		val receiver = new ReceiveBuffer(outPump, inPump)
		val sender = new SendBuffer(outPump, inPump)
		
		receiver => [
			onBegin[
				sb.append('begin: ' + it + ' ')
				receiver >> [ sb.append(new String(array)) ]
			]
			onEnd[ sb.append(' end') ]
		]
		
		val buffer = ByteBuffer.wrap(text.getBytes('UTF-8'))
		sender => [
			begin('signal')[
				it << buffer
				end
			]
		]
		
		Assert.assertEquals(sb.toString, 'begin: signal Just a string test! end')
	}
	
	@Test
	def void readFileAndTransfer() {
		AsyncUtils.setDefault
		val sb = new StringBuilder
		val receiver = new ReceiveBuffer(outPump, inPump)
		val sender = new SendBuffer(outPump, inPump)
		
		receiver => [
			onBegin[
				sb.append('begin: ' + it + ' ')
				receiver >> [
					val textByte = Arrays.copyOf(array, limit)
					sb.append(new String(textByte))
				]
			]
			onEnd[ sb.append(' end') ]
		]
		
		sender => [
			sendFile('./test.txt', 5).then[ sb.append(' OK') ]
		]
		
		AsyncUtils.timer(500)[
			println(sb.toString)
			Assert.assertEquals(sb.toString, 'begin: ./test.txt Just a string test! end OK')
		]
	}
	
	@Test
	def void readFileTransferAndWrite() {
		AsyncUtils.setDefault
		val text = 'Just a string test!'
		
		val file = new File('./result.txt')
		file.delete
		
		val sb = new StringBuilder
		val receiver = new ReceiveBuffer(outPump, inPump)
		val sender = new SendBuffer(outPump, inPump)
		
		receiver => [
			onBegin[
				sb.append('begin: ' + it + ' ')
				receiver.writeToFile('./result.txt')
				receiver >> [ //should not write in here, because of the writeToFile
					val textByte = Arrays.copyOf(array, limit)
					sb.append(new String(textByte))
				]
			]
			onEnd[ sb.append(' end') ]
		]
		
		sender => [
			sendFile('./test.txt', 5).then[ sb.append(' OK')]
		]
		
		AsyncUtils.timer(500)[
			Assert.assertEquals(sb.toString, 'begin: ./test.txt  end OK')
			
			//assert that file content is ok
			val fileBuffer = ByteBuffer.allocate(19)
			val fileChannel = FileChannel.open(Paths.get('./result.txt'), StandardOpenOption.READ)
			fileChannel.read(fileBuffer)
			Assert.assertEquals(new String(fileBuffer.array), text)
			
			file.delete
		]
	}
}