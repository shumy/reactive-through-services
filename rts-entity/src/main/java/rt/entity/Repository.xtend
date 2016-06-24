package rt.entity

import rt.entity.change.IObservable
import rt.entity.change.Change
import org.eclipse.xtend.lib.annotations.Accessors
import rt.entity.change.Publisher
import java.util.HashMap
import rt.entity.change.ChangeType
import rt.entity.sync.EntitySync

class Repository<T extends EntitySync> implements IObservable {
	@Accessors val String name
	@Accessors val publisher = new Publisher
	
	val cache = new HashMap<String, T>
	
	new(String name) {
		this.name = name
	}
	
	override onChange((Change)=>void listener) {
		return publisher.addListener(listener)
	}
	
	def addEntity(T entity) {
		val uuid = entity.onChange[ change |
			publisher.publish(change.addPath(name))
		]
		
		cache.put(uuid, entity)
		
		publisher.publish(new Change(ChangeType.ADD, uuid, name))
		return uuid
	}
	
	def void removeEntity(String uuid) {
		val entity = cache.remove(uuid)
		entity.publisher.removeListener(uuid)
		
		publisher.publish(new Change(ChangeType.REMOVE, uuid, name))
	}
}