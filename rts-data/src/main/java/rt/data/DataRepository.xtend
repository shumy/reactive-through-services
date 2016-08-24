package rt.data

import java.util.HashMap

class DataRepository<D> {
	val table = new HashMap<String, D>
	val (Change) => void onChange
	
	new((Change) => void onChange) {
		this.onChange = onChange
	}
	
	def list() { table.values.toList }
	
	def void put(String id, D data) {
		onChange.apply(new Change(Change.Operation.PUT, data))
	}
	
	def void remove(String id) {
		val value = table.remove(id)
		if (value != null)
			onChange.apply(new Change(Change.Operation.REMOVE, id))
	}
}

class Change {
	enum Operation { PUT, REMOVE }
	
	public val String oper
	public val Object data
	
	new(Operation oper, Object data) {
		this.oper = oper.name.toLowerCase
		this.data = data
	}
}