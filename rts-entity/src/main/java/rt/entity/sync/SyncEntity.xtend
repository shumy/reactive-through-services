package rt.entity.sync

import rt.entity.change.Publisher
import rt.entity.change.IObservable
import rt.entity.change.Change
import java.util.HashMap

abstract class SyncEntity implements IEntity, IObservable {
	transient val observableFields = new HashMap<String, String>
	transient protected val publisher = new Publisher
	
	override getPublisher() {
		return publisher
	}
	
	override onChange((Change) => void listener) {
		return publisher.addListener(listener)
	}
	
	protected def void observe(String field, IObservable observable) {
		//remove old observer
		publisher.removeListener(observableFields.remove(field))
		
		val uuid = publisher.addListener[ change |
			change.path.add(field)
			publisher.publish(change)
		]
		
		observableFields.put(field, uuid)
	}
}