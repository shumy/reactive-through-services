package rt.plugin.test.entity

import rt.entity.Entity

@Entity
class OtherEntity {
	String name
	
	new(String name) {
		this.name = name
	}
}