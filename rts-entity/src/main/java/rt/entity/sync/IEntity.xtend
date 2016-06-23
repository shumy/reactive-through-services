package rt.entity.sync

import java.util.List

interface IEntity {
	def List<String> getFields()
	
	def Object getValue(String field)
	def void setValue(String field, Object value)
	
	//def void applyChange(Change change)
}