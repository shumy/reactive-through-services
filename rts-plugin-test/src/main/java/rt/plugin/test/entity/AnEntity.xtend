package rt.plugin.test.entity

import rt.entity.Entity
import java.util.List
import java.util.Map
import rt.entity.Ignore

@Entity
class AnEntity {
	@Ignore String uuid
	
	val String constant = 'not observed'
	
	OtherEntity other
	boolean active
	String text
	String name
	
	val List<OtherEntity> othersList
	val Map<String, OtherEntity> othersMap
}