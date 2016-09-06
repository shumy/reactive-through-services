package rt.data

import java.util.HashMap
import java.util.List
import java.util.Map
import org.eclipse.xtend.lib.annotations.Accessors

interface IDataRepository<D> {
	def List<D> list()
	
	def D get(String id)
	def void put(String id, D data)
	def void remove(String id)
}

class DataRepository<D> implements IDataRepository<D> {
	@Accessors var (Change) => void onChange
	
	val Map<String, D> table
	
	new() { this(new HashMap<String, D>) }
	new(Map<String, D> table) {
		this.table = table
	}
	
	override list() { table.values.toList }
	
	override get(String id) {
		return table.get(id)
	}
	
	override put(String id, D data) {
		table.put(id, data)
		onChange?.apply(new Change(Change.Operation.PUT, data))
	}
	
	override remove(String id) {
		val value = table.remove(id)
		if (value != null && onChange != null)
			onChange.apply(new Change(Change.Operation.REMOVE, id))
	}
}

class Change {
	enum Operation { PUT, REMOVE }
	
	public val Operation oper
	public val Object data
	
	new(Operation oper, Object data) {
		this.oper = oper
		this.data = data
	}
}