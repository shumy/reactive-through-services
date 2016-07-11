package rt.entity.sync

import java.util.HashMap
import rt.entity.change.IObservable
import rt.entity.change.Publisher
import org.eclipse.xtend.lib.annotations.Accessors
import rt.entity.change.Change
import java.util.Map
import rt.entity.change.ChangeType

class EntityMap<K, V> extends HashMap<K, V> implements IObservable {
	@Accessors transient val publisher = new Publisher
	
	//<Key, ListenerUUID>
	transient val listeners = new HashMap<Object, String>
	
	override onChange((Change) => void listener) {
		return publisher.addListener(listener)
	}
	
	override V put(K key, V element) {
		key.unobserve
		key.observe(element)
		
		val change = new Change(ChangeType.ADD, element, key)
		publisher.publish(change)
		return super.put(key, element)
	}
	
	override V remove(Object key) {
		key.unobserve
		
		val change = new Change(ChangeType.REMOVE, 1, key)
		publisher.publish(change)
		return super.remove(key)
	}
	
	override putAll(Map<? extends K, ? extends V> m) {
		for (key: m.keySet) put(key, m.get(key))
	}
	
	override clear() {
		for (key: listeners.keySet) key.unobserve
		
		val change = new Change(ChangeType.CLEAR, this.size, 'all')
		publisher.publish(change)
		super.clear
	}
	
	//TODO: other methods (clone, replace, ...)
	
	private def void unobserve(Object key) {
		val element = this.get(key)
		if (element != null && IObservable.isAssignableFrom(element.class)) {
			val observable = element as IObservable
			val uuid = listeners.remove(key)
			
			observable.publisher.removeListener(uuid)
		}
	}
	
	private def void observe(Object key, V element) {
		if (element != null && IObservable.isAssignableFrom(element.class)) {
			val observable = element as IObservable
			val isTransitive = IEntity.isAssignableFrom(element.class)
			val uuid = observable.onChange [ change |
				//if remove from an IEntity --> remove this listener
				if (change.oper == ChangeType.REMOVE && isTransitive) {
					change.removeListener
					
					super.remove(key)
					val newChange = new Change(ChangeType.REMOVE, 1, key)
					publisher.publish(newChange)
				} else {
					publisher.publish(change.addPath(key, isTransitive))
				}
			]
			
			listeners.put(key, uuid)
		}
	}
}