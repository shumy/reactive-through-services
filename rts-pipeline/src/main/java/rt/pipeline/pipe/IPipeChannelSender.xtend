package rt.pipeline.pipe

interface IPipeChannelSender extends IPipeChannel {
	def void send(byte[] data)
}