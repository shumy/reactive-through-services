package rt.pipeline

import rt.pipeline.bus.Message

interface IResourceProvider {
	def IResource getResource()
}

interface IResource {
	def String getClient()
	
	def void subscribe(String address)
	def void subscribe(String address, (Message)=>void listener)
	
	def void unsubscribe(String address)
	
	def void send(Message msg)
	
	def void disconnect()
}