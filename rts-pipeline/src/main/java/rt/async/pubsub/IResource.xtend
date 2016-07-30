package rt.async.pubsub

interface IResource {
	def void subscribe(String address)
	def void unsubscribe(String address)
	def void disconnect()
}