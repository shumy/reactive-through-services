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
	
	/*
	override applyChange(Change change) {
		change.path
	}*/
	
	def void addEntity(E entity) {
		cache.put(entity.key.uuid, entity)
		
		entity.publisher.addListener(entity.key.uuid)[ change |
			if (!ignoreTransitive || !change.tr) {
				val newChange = if (IEntity.isAssignableFrom(change.value.class)) {
					val eValue = change.value as IEntity
					new Change(change.oper, change.type, eValue.key.toString, change.path).addPath(entity.key.toString, false)
				} else {
					if (change.oper == ChangeType.REMOVE && change.path.head == 'this') {
						//if remove from an IEntity --> remove this listener
						change.removeListener
						val e = cache.remove(change.value)
						
						removeEvent(e)
					} else {
						change.addPath(entity.key.toString, false)
					}
				}
				
				publisher.publish(newChange)
			}
		]
		
		publisher.publish(new Change(ChangeType.ADD, entity, entity.key.toString))
	}
	
	def void removeEntity(String uuid) {
		val entity = cache.remove(uuid)
		if (entity != null) {
			entity.publisher.removeListener(uuid)
			publisher.publish(removeEvent(entity))
		}
	}
	
	private def removeEvent(IEntity entity) {
		return new Change(ChangeType.REMOVE, 1, entity.key.toString)
	}
	
	private def void applyUpdate(Change change) {
		
	}
	
	private def void applyAdd(Change change) {
		
	}
	
	private def void applyRemove(Change change) {
		
	}
	
	private def void applyClear(Change change) {
		
	}
}