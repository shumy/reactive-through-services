package rt.entity.change

import java.util.List
import java.util.LinkedList

enum ChangeType {
	UPDATE, ADD, REMOVE, CLEAR
}

class Change {
	public static val PATH_SEPARATOR = '.'
	
	public val ChangeType oper
	public val String type
	public val Object value
	
	val List<Object> path
	
	new(ChangeType oper, Object value, List<Object> path) {
		this.oper = oper
		this.type = if (oper == ChangeType.UPDATE || oper == ChangeType.ADD) value.class.simpleName else null
		this.value = value
		
		this.path = new LinkedList<Object>
		this.path.addAll(path)
	}
	
	new(ChangeType oper, Object value, Object path) {
		this(oper, value, #[ path ])
	}
	
	def Change addPath(Object path) {
		val newChange = new Change(this.oper, this.value, this.path)
		newChange.path.add(path)
		
		return newChange
	}
}