package rt.entity.sync

import rt.entity.change.Publisher
import rt.entity.change.IObservable
import rt.entity.change.Change
import java.util.HashMap
import org.eclipse.xtend.lib.annotations.Accessors
import java.util.List
import java.util.Map

abstract class EntitySync implements IEntity, IObservable {
	@Accessors transient protected val publisher = new Publisher
	
	//<FieldName, ListenerUUID>
	transient val observableFields = new HashMap<String, String>
	
	override onChange((Change) => void listener) {
		return publisher.addListener(listener)
	}
	
	protected def void unobserve(String field, IObservable observable) {
		if (observable != null)
			observable.publisher.removeListener(observableFields.remove(field))
	}
	
	protected def void observe(String field, IObservable observable) {
		val uuid = observable.onChange[ change |
			publisher.publish(change.addPath(field))
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