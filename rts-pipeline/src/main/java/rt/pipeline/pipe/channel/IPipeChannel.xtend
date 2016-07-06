package rt.pipeline.pipe.channel

import java.util.UUID
import rt.pipeline.pipe.PipeResource

interface IPipeChannel {
	def PipeResource getResource()
	def PipeChannelInfo getInfo()
	def String getStatus()
	def IChannelBuffer getBuffer()
	
	def void close()
	
	static class PipeChannelInfo {
		enum Type { SENDER, RECEIVER }
		
		public val Type type
		public val String uuid
		
		public String path
		
		new(Type type) {
			this.type = type
			this.uuid = UUID.randomUUID.toString
		}
	}
}