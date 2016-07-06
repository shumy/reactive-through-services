package rt.pipeline.pipe.use

import rt.pipeline.pipe.channel.IPipeChannel
import rt.pipeline.pipe.channel.IPipeChannel.PipeChannelInfo

interface ChannelInterface {
	def IPipeChannel request(PipeChannelInfo chInfo)
}