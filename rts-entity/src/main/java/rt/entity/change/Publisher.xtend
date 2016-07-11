package rt.entity.change

import java.util.UUID
import java.util.LinkedHashMap

class Publisher {
	//listeners return true if is a concurrent modification...
	val listeners = new LinkedHashMap<String, (Change) => void>

	def void addListener(String uuid, (Change) => void listener) {
		listeners.put(uuid, listener)
	}
	
	def addListener((Change) => void listener) {
		val uuid = UUID.randomUUID.toString
		listeners.put(uuid, listener)
		return uuid
	}
	
	def void removeListener(String uuid) {
		listeners.remove(uuid)
	}
	
	def void publish(Change change) {
		val iter = listeners.values.iterator
		while (iter.hasNext) {
			change.iterator = iter
			iter.next.apply(change)
		}
	}
}