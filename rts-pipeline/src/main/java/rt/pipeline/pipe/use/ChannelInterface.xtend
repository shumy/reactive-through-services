package rt.pipeline.pipe.use

import rt.pipeline.pipe.IPipeChannel.PipeChannelInfo
import rt.pipeline.pipe.IPipeChannelSender

interface ChannelInterface {
	def IPipeChannelSender request(PipeChannelInfo chInfo)
}