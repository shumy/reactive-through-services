package rt.ws.client

import java.nio.ByteBuffer
import java.net.URI
import org.java_websocket.client.WebSocketClient
import org.java_websocket.handshake.ServerHandshake
import org.eclipse.xtend.lib.annotations.Accessors
import rt.pipeline.pipe.IPipeChannelReceiver
import rt.pipeline.pipe.PipeResource

class ClientPipeChannelReceiver implements IPipeChannelReceiver {
	@Accessors val PipeResource resource
	@Accessors val PipeChannelInfo info
	@Accessors val String status
	
	val URI url
	
	WebSocketClient ws = null
	(byte[]) => void onReceive = null
	
	package new(PipeResource resource, PipeChannelInfo info, String client) {
		this.resource = resource
		this.info = info
		this.status = 'INIT'
		
		this.url = new URI(resource.client + '?client=' + client + '&channel=' + info.uuid)
	}
	
	override receive((byte[]) => void onReceive) {
		this.onReceive = onReceive
	}
	
	override close() { ws?.close }
	
	def connect() {
		val channel = this
		
		println('TRY-CHANNEL-OPEN: ' + url)
		ws = new WebSocketClient(url) {
			
			override onOpen(ServerHandshake handshakedata) {
				println('CLIENT-CHANNEL-OPEN')
			}
			
			override onClose(int code, String reason, boolean remote) {
				println('CLIENT-CHANNEL-CLOSE')
				resource.removeChannel(info.uuid)
			}
			
			override onError(Exception ex) {
				ex.printStackTrace
			}
			
			override onMessage(String textMsg) {
				println('CHANNEL-RECEIVED: ' + textMsg)
			}
			
			override onMessage(ByteBuffer byteMsg) {
				println('CHANNEL-RECEIVED-BINARY')
				channel.onReceive?.apply(byteMsg.array)
			}
		}
		
		ws.connect
	}
}