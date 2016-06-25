package rt.entity.sync

import rt.entity.change.Publisher
import rt.entity.change.IObservable
import rt.entity.change.Change
import java.util.HashMap
import org.eclipse.xtend.lib.annotations.Accessors
import java.util.List
import java.util.Map

abstract class EntitySync implements IEntity {
	@Accessors transient val key = new EntityKey
	@Accessors transient val publisher = new Publisher
	
	//<FieldName, ListenerUUID>
	transient val observableFields = new HashMap<String, String>
	
	override onChange((Change) => void listener) {
		return publisher.addListener(listener)
	}
	
	protected def void publish(Change change) {
		if (!change.tr) key.version++
		publisher.publish(change)
	}
	
	protected def void unobserve(String field, IObservable observable) {
		if (observable != null)
			observable.publisher.removeListener(observableFields.remove(field))
	}
	
	protected def void observe(String field, IObservable observable) {
		val transitive = IEntity.isAssignableFrom(observable.class)
		val uuid = observable.onChange[ change |
			val newChange = change.addPath(field, transitive)
			
			if (!newChange.tr) key.version++
			publisher.publish(newChange)
		]
		
		observableFields.put(field, uuid)
	}
	
	protected def <T> List<T> newList(String field) {
		val element = new EntityList<T>
		observe(field, element)
		return element
	}
	
	protected def <K, V> Map<K, V> newMap(String field) {
		val element = new EntityMap<K, V>
		observe(field, element)
		return element
	}
}