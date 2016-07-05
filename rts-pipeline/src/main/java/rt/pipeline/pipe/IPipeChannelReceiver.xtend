package rt.pipeline.pipe

interface IPipeChannelReceiver extends IPipeChannel {
	def void receive((byte[]) => void onReceive)
}