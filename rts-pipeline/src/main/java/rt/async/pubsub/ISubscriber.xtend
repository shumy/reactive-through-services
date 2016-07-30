package rt.async.pubsub

interface ISubscriber {
	def ISubscription subscribe(String address, (Message) => void listener)
}

interface ISubscription {
	def void remove()
}