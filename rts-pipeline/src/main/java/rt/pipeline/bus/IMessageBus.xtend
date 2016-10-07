package rt.pipeline.bus

import rt.async.IPublisher

interface IMessageBus extends ISubscriber, IPublisher {
	def void publish(String address, Message msg)
	
	def void send(String address, Message msg, (Message) => void replyCallback)
	
	def void reply(Message msg)
	def void replyListener(String replyID, (Message) => void listener)
}