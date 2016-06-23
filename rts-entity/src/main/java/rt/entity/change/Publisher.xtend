package rt.entity.change

import java.util.HashMap
import java.util.UUID

class Publisher {
	val listeners = new HashMap<String, (Change) => void>
	
	def addListener((Change) => void listener) {
		val uuid = UUID.randomUUID.toString
		listeners.put(uuid, listener)
		return uuid
	}
	
	def removeListener(String uuid) {
		listeners.remove(uuid)
	}
	
	def void publish(Change change) {
		listeners.values.forEach[ apply(change) ]
	} 
}