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
	
	override applyChange(Change change) {
		val entityKey = change.path.pop
		val splits = entityKey.split(':', 2)
		
		val uuid = splits.get(0)
		val version = Long.parseLong(splits.get(1))
		
		val entity = cache.get(uuid)
		if (entity == null)
			throw new RuntimeException('Entity non existent: ' + uuid)
		
		if (entity.key.version != version + 1)
			throw new RuntimeException('Version out of sync: ' + entity.key)
		
		if (change.path.size > 0) {
			entity.applyChange(change)
			return
		}
		
		switch change.oper {
			case ChangeType.ADD: addEntityWithoutPublish(change.value as E)
			case ChangeType.REMOVE: removeEntityWithoutPublish(uuid)
			default: throw new RuntimeException('Unsupported change operation for the Repository: ' + change.oper)
		}
	}
	
	def void addEntity(E entity) {
		entity.addEntityWithoutPublish
		publisher.publish(new Change(ChangeType.ADD, entity, entity.key.toString))
	}
	
	def void removeEntity(String uuid) {
		val E entity = removeEntityWithoutPublish(uuid)
		if (entity != null)
			publisher.publish(removeEvent(entity))
	}
	
	private def void addEntityWithoutPublish(E entity) {
		cache.put(entity.key.uuid, entity)
		
		entity.publisher.addListener(entity.key.uuid)[ change |
			if (!ignoreTransitive || !change.tr) {
				val newChange = if (IEntity.isAssignableFrom(change.value.class)) {
					val eValue = change.value as IEntity
					new Change(change.oper, change.type, eValue.key.toString, change.path).pushPath(entity.key.toString, false)
				} else {
					if (change.oper == ChangeType.REMOVE && change.path.head == 'this') {
						//if remove from an IEntity --> remove this listener
						change.removeListener
						val e = cache.remove(change.value)
						
						removeEvent(e)
					} else {
						change.pushPath(entity.key.toString, false)
					}
				}
				
				publisher.publish(newChange)
			}
		]
	}
	
	def E removeEntityWithoutPublish(String uuid) {
		val entity = cache.remove(uuid)
		if (entity != null) {
			entity.publisher.removeListener(uuid)
			return entity
		}
		
		return null
	}
	
	private def removeEvent(IEntity entity) {
		return new Change(ChangeType.REMOVE, 1, entity.key.toString)
	}
}