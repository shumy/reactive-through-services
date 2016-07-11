package rt.entity.sync

import java.util.List
import rt.entity.change.IObservable

interface IEntity extends IObservable {
	def EntityKey getKey()
	def List<String> getFields()
	
	def Object getValue(String field)
	def void setValue(String field, Object value)
	
	def void remove()
}