package rt.ws.client

import java.nio.ByteBuffer
import java.net.URI
import org.java_websocket.client.WebSocketClient
import org.java_websocket.handshake.ServerHandshake
import org.eclipse.xtend.lib.annotations.Accessors
import rt.pipeline.pipe.IPipeChannelReceiver

class ClientPipeChannelReceiver implements IPipeChannelReceiver {
	@Accessors val PipeChannelInfo info
	@Accessors val String status
	val URI url
	
	WebSocketClient ws = null
	(byte[]) => void onReceive = null
	
	package new(ClientRouter router, PipeChannelInfo info) {
		this.info = info
		this.status = 'INIT'
		this.url = new URI(router.server + '?channel=' + info.uuid)
	}
	
	override receive((byte[]) => void onReceive) {
		this.onReceive = onReceive
	}
	
	override close() {
		ws?.close
	}
	
	def connect() {
		val channel = this
		
		println('TRY-CHANNEL-OPEN: ' + url)
		ws = new WebSocketClient(url) {
			
			override onOpen(ServerHandshake handshakedata) {
				println('CLIENT-CHANNEL-OPEN')
			}
			
			override onClose(int code, String reason, boolean remote) {
				println('CLIENT-CHANNEL-CLOSE')
				//TODO: release channel on resource?
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