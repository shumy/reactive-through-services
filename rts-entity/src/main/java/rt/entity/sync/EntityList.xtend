package rt.entity.sync

import java.util.ArrayList
import rt.entity.change.IObservable
import rt.entity.change.Publisher
import org.eclipse.xtend.lib.annotations.Accessors
import rt.entity.change.Change
import java.util.Collection
import rt.entity.change.ChangeType
import java.util.HashMap

class EntityList<T> extends ArrayList<T> implements IObservable {
	@Accessors transient val publisher = new Publisher
	
	//<IObservable, ListenerUUID>
	transient val listeners = new HashMap<IObservable, String>

	override onChange((Change) => void listener) {
		return publisher.addListener(listener)
	}
	
	override T set(int index, T element) {
		val oldElement = super.get(index)
		oldElement.unobserve
		element.observe

		val change = new Change(ChangeType.UPDATE, element, index.toString)
		publisher.publish(change)
		return super.set(index, element)
	}
	
	override boolean add(T element) {
		element.observe
		
		val change = new Change(ChangeType.ADD, element, 'end')
		publisher.publish(change)
		return super.add(element)
	}
	
	override void add(int index, T element) {
		element.observe
		
		val change = new Change(ChangeType.ADD, element, index.toString)
		publisher.publish(change)
		super.add(index, element)
	}
	
	override T remove(int index) {
		val element = super.remove(index)
		element.unobserve
		
		val change = new Change(ChangeType.REMOVE, 1, index.toString)
		publisher.publish(change)
		return element
	}
	
	override boolean remove(Object element) {
		val index = super.indexOf(element)
		super.remove(index)
		element.unobserve

		val change = new Change(ChangeType.REMOVE, 1, index.toString)
		publisher.publish(change)		
		return true
	}
	
	override void clear() {
		for (element: this) element.unobserve
		
		val change = new Change(ChangeType.CLEAR, this.size, 'all')
		publisher.publish(change)
		super.clear
	}
	
	override boolean addAll(Collection<? extends T> c) {
		for(item: c) add(item)
		return true
	}
	
	override boolean removeAll(Collection<?> c) {
		for(item: c) remove(item)
		return true
	}
	
	//TODO: other methods (...)
	
	private def void unobserve(Object element) {
		if (element != null && IObservable.isAssignableFrom(element.class)) {
			val observable = element as IObservable
			val uuid = listeners.remove(element)
			
			observable.publisher.removeListener(uuid)
		}
	}
	
	private def void observe(Object element) {
		if (element != null && IObservable.isAssignableFrom(element.class)) {
			val observable = element as IObservable
			val transitive = IEntity.isAssignableFrom(element.class)
			val uuid = observable.onChange [ change |
				//TODO: needs some perfomance optimizations
				val path = element.indexOf.toString
				publisher.publish(change.addPath(path, transitive))
			]
			
			listeners.put(observable, uuid)
		}
	}
}