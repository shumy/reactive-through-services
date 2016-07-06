package rt.pipeline.pipe.channel

interface IChannelBuffer {
	def void error(String message)
	def void onError((String) => void onError)
	
	def void close()
}