package rt.pipeline.pipe.channel

import java.util.UUID
import rt.pipeline.pipe.PipeResource
import org.eclipse.xtend.lib.annotations.Accessors

interface IPipeChannel {
	def PipeResource getResource()
	def PipeChannelInfo getInfo()
	def String getStatus()
	def ChannelBuffer getBuffer()
	
	def void close()
	
	static class PipeChannelInfo {
		enum Type { SENDER, RECEIVER }
		
		@Accessors val String uuid
		
		@Accessors(PUBLIC_GETTER) Type type
		@Accessors String path
		
		new(Type type) {
			this.type = type
			this.uuid = UUID.randomUUID.toString
		}
		
		def PipeChannelInfo invertType() {
			type = if (type == Type.SENDER) Type.RECEIVER else Type.SENDER
			return this
		}
	}
}