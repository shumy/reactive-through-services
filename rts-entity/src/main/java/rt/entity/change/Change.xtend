package rt.entity.change

import java.util.List
import java.util.LinkedList

enum ChangeType {
	UPDATE, ADD, REMOVE, CLEAR
}

class Change {
	public static val PATH_SEPARATOR = '.'
	
	public val ChangeType oper
	var String type
	public val Object value
	
	val List<Object> path
	
	new(ChangeType oper, Object value, List<Object> path) {
		this.oper = oper
		this.value = value
		this.path = path
	
		if (oper == ChangeType.UPDATE || oper == ChangeType.ADD)
			this.type = value.class.simpleName
	}
	
	new(ChangeType oper, Object value, Object path) {
		this(oper, value, new LinkedList<Object>)
		this.path.add(path)
	}
	
	def Change addPath(Object path) {
		val newChange = new Change(this.oper, this.value, this.path)
		newChange.path.add(path)
		
		return newChange
	}
}