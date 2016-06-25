package rt.entity.change

import java.util.UUID
import java.util.LinkedHashMap

class Publisher {
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
		listeners.values.forEach[ apply(change) ]
	}
}