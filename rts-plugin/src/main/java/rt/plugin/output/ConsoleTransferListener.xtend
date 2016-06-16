package rt.plugin.output

import org.eclipse.aether.transfer.AbstractTransferListener
import org.eclipse.aether.transfer.TransferResource
import java.util.concurrent.ConcurrentHashMap
import org.eclipse.aether.transfer.TransferEvent
import java.util.Locale
import java.text.DecimalFormatSymbols
import java.text.DecimalFormat
import org.eclipse.aether.transfer.MetadataNotFoundException

class ConsoleTransferListener extends AbstractTransferListener {
	int lastLength
	val downloads = new ConcurrentHashMap<TransferResource, Long>

	override void transferSucceeded(TransferEvent event) {
		transferCompleted(event)

		val resource = event.resource
		val contentLength = event.transferredBytes
		
		if (contentLength >= 0) {
			val len = if (contentLength >= 1024) toKB(contentLength) + ' KB' else contentLength + ' B'

			var throughput = ''
			val duration = System.currentTimeMillis - resource.transferStartTime
			if (duration > 0) {
				val bytes = contentLength - resource.resumeOffset
				val format = new DecimalFormat('0.0', new DecimalFormatSymbols(Locale.ENGLISH))
				val kbPerSec = (bytes / 1024.0) / (duration / 1000.0)
				throughput = ' at ' + format.format(kbPerSec) + ' KB/sec'
			}

			println('''Downloaded: «resource.repositoryUrl»«resource.resourceName» («len + throughput»)''')
		}
	}

	override void transferFailed(TransferEvent event) {
		transferCompleted(event)

		if (!(event.exception instanceof MetadataNotFoundException)) {
			event.exception.printStackTrace
		}
	}
	
	override def void transferCorrupted(TransferEvent event) {
		event.exception.printStackTrace
	}

	private def void transferCompleted(TransferEvent event) {
		downloads.remove(event.resource)

		val buffer = new StringBuilder(64)
		pad(buffer, lastLength)
		buffer.append('\r')
		print(buffer)
	}

	private def void pad(StringBuilder buffer, int inSpaces) {
		var spaces = inSpaces
		val block = '                                        '
		while (spaces > 0) {
			val n = Math.min(spaces, block.length)
			buffer.append(block, 0, n)
			spaces -= n
		}
	}
	
	private def long toKB(long bytes) {
		return (bytes + 1023) / 1024
	}
}