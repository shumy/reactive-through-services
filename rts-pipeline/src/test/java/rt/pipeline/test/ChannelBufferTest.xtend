package rt.pipeline.test

import java.nio.ByteBuffer
import java.util.Arrays
import org.junit.Assert
import org.junit.Test
import rt.pipeline.pipe.channel.ReceiveBuffer
import rt.pipeline.pipe.channel.ReceiveBuffer.ChannelPump
import rt.pipeline.pipe.channel.SendBuffer
import java.io.File
import java.nio.channels.FileChannel
import java.nio.file.StandardOpenOption
import java.nio.file.Paths

class ChannelBufferTest {
	
	@Test
	def void dataTransfer() {
		val text = 'Just a string test!'
		
		val sb = new StringBuilder
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
	
	@Test
	def void readFileAndTransfer() {
		val sb = new StringBuilder
		val pump = new ChannelPump
		
		new ReceiveBuffer(pump) => [
			onBegin[ sb.append('begin: ' + it + ' ') ]
				it >> [
					val textByte = Arrays.copyOf(array, limit)
					sb.append(new String(textByte))
				]
			onEnd[ sb.append(' end') ]
		]
		
		new SendBuffer([ pump.pushSignal(it) ], [ pump.pushData(it) ]) => [
			sendFile('./test.txt', 5)
		]
		
		Assert.assertEquals(sb.toString, 'begin: ./test.txt Just a string test! end')
	}
	
	@Test
	def void readFileTransferAndWrite() {
		val text = 'Just a string test!'
		
		val file = new File('./result.txt')
		file.delete
		
		val sb = new StringBuilder
		val pump = new ChannelPump
		
		new ReceiveBuffer(pump) => [
			onBegin[ sb.append('begin: ' + it + ' ') ]
				writeToFile('./result.txt')
				it >> [ //should not write in here, because of the writeToFile
					val textByte = Arrays.copyOf(array, limit)
					sb.append(new String(textByte))
				]
			onEnd[ sb.append(' end') ]
		]
		
		new SendBuffer([ pump.pushSignal(it) ], [ pump.pushData(it) ]) => [
			sendFile('./test.txt', 5)
		]
		
		Assert.assertEquals(sb.toString, 'begin: ./test.txt  end')
		
		//assert that file content is ok
		val fileBuffer = ByteBuffer.allocate(19)
		val fileChannel = FileChannel.open(Paths.get('./result.txt'), StandardOpenOption.READ)
		fileChannel.read(fileBuffer)
		Assert.assertEquals(new String(fileBuffer.array), text)
		
		file.delete
	}
}