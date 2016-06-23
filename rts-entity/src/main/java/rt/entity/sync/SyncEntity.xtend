package rt.entity.sync

import rt.entity.change.Publisher
import rt.entity.change.IObservable
import rt.entity.change.Change

abstract class SyncEntity implements IEntity, IObservable {
	transient protected val publisher = new Publisher
	
	override onChange((Change) => void listener) {
		publisher.addListener(listener)
	}
}