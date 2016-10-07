package rt.async

interface IPublisher {
	def void publish(String address, String cmd, Object result)
	def void publish(String address, String service, String cmd, Object result)
}