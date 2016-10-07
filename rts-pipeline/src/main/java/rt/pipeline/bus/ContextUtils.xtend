package rt.pipeline.bus

class ContextUtils {
	static val publisher = new ThreadLocal<IPublisher>
	
	static def IPublisher getPublisher() { publisher.get }
	static def void setPublisher(IPublisher pub) { publisher.set = pub }
}