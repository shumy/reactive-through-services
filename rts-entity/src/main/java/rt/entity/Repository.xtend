package rt.entity

import rt.entity.change.IObservable
import rt.entity.change.Change
import org.eclipse.xtend.lib.annotations.Accessors
import rt.entity.change.Publisher
import java.util.HashMap
import rt.entity.change.ChangeType
import rt.entity.sync.IEntity

class Repository<E extends IEntity> implements IObservable {
	@Accessors val String name
	@Accessors val publisher = new Publisher
	@Accessors boolean ignoreTransitive = true
	
	val cache = new HashMap<String, E>
	
	new(String name) {
		this.name = 'repo-' + name
	}
	
	override onChange((Change) => void listener) {
		return publisher.addListener(listener)
	}
	
	def void addEntity(E entity) {
		val prePath = name + ':' + entity.key.uuid
		cache.put(entity.key.uuid, entity)
		
		entity.publisher.addListener(entity.key.uuid)[ change |
			if (!ignoreTransitive || !change.tr) {
				val path = prePath + ':' + entity.key.version
				val newChange = if (IEntity.isAssignableFrom(change.value.class)) {
					val eValue = change.value as IEntity
					if (change.oper == ChangeType.REMOVE) {
						//if remove from an IEntity --> remove this listener
						change.removeListener
						cache.remove(eValue.key.uuid)
						
						eValue.removeEvent
					} else {
						new Change(change.oper, change.type, eValue.key.toString, change.path).addPath(path, false)
					}
				} else {
					change.addPath(path, false)
				}
				
				publisher.publish(newChange)
			}
		]
		
		publisher.publish(new Change(ChangeType.ADD, entity, prePath + ':' + entity.key.version))
	}
	
	def void removeEntity(String uuid) {
		val entity = cache.remove(uuid)
		if (entity != null) {
			entity.publisher.removeListener(uuid)
			publisher.publish(entity.removeEvent)
		}
	}
	
	private def removeEvent(IEntity entity) {
		return new Change(ChangeType.REMOVE, 1, name + ':' + entity.key)
	}
}