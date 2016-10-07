package rt.pipeline.bus

interface ISubscriber {
	def ISubscription subscribe(String address, (Message) => void listener)
	
	def void addObserver(String address, IObserver observer)
}

interface ISubscription {
	def String getAddress()
	def void remove()
}

interface IObserver {
	def void onCreate(String address)
	def void onDestroy(String address)
}