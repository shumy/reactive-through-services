package rt.pipeline.pipe.use

import rt.pipeline.pipe.IPipeChannel.PipeChannelInfo
import rt.pipeline.pipe.IPipeChannelSender

interface ChannelInterface {
	def IPipeChannelSender requestChannel(PipeChannelInfo chInfo)
}