package rt.plugin.test.entity

import rt.entity.Entity

@Entity
class AnEntity {
	val constant = 'not observed'

	OtherEntity other
	boolean active
	String text
	String name
}