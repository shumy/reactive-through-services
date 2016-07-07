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
import rt.pipeline.AsyncUtils

class ChannelBufferTest {
	val outPump = new ChannelPump
	val inPump = new ChannelPump
	
	@Test
	def void dataTransfer() {
		val text = 'Just a string test!'
		
		val sb = new StringBuilder
		
		new ReceiveBuffer(outPump, inPump) => [
			onBegin[ sb.append('begin: ' + it + ' ') ]
				it >> [ sb.append(new String(array)) ]
			onEnd[ sb.append(' end') ]
		]
		
		val buffer = ByteBuffer.wrap(text.getBytes('UTF-8'))
		new SendBuffer(outPump, inPump) => [
			begin('signal')
				it << buffer
			end
		]
		
		Assert.assertEquals(sb.toString, 'begin: signal Just a string test! end')
	}
	
	@Test
	def void readFileAndTransfer() {
		AsyncUtils.setDefault
		val sb = new StringBuilder
		
		new ReceiveBuffer(outPump, inPump) => [
			onBegin[ sb.append('begin: ' + it + ' ') ]
				it >> [
					val textByte = Arrays.copyOf(array, limit)
					sb.append(new String(textByte))
				]
			onEnd[ sb.append(' end') ]
		]
		
		new SendBuffer(outPump, inPump) => [
			sendFile('./test.txt', 5).then[ sb.append(' OK') ]
		]
		
		AsyncUtils.timer(500)[
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
		
		new ReceiveBuffer(outPump, inPump) => [
			onBegin[ sb.append('begin: ' + it + ' ') ]
				writeToFile('./result.txt')
				it >> [ //should not write in here, because of the writeToFile
					val textByte = Arrays.copyOf(array, limit)
					sb.append(new String(textByte))
				]
			onEnd[ sb.append(' end') ]
		]
		
		new SendBuffer(outPump, inPump) => [
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