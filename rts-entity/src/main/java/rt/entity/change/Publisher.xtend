package rt.entity.change

import java.util.UUID
import java.util.LinkedHashMap

class Publisher {
	val listeners = new LinkedHashMap<String, (Change) => void>
	
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