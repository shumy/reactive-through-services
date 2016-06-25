package rt.entity.sync

import org.eclipse.xtend.lib.annotations.Accessors
import java.util.UUID

class EntityKey {
	@Accessors val String uuid
	@Accessors(PUBLIC_GETTER) package long version
	
	new() {
		this.uuid = UUID.randomUUID.toString
		this.version = 1
	}
	
	override toString() {
		return uuid + ':' + version
	}
	
}