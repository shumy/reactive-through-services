package rt.pipeline.pipe

import java.util.UUID

interface IPipeChannel {
	def PipeResource getResource()
	def PipeChannelInfo getInfo()
	def String getStatus()
	
	def void close()
	
	static class PipeChannelInfo {
		public val String uuid
		
		public String path
		
		new() {
			this.uuid = UUID.randomUUID.toString
		}
	}
}