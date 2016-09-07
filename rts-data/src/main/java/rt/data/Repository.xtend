package rt.data

import java.util.HashMap
import java.util.List
import java.util.Map
import org.eclipse.xtend.lib.annotations.Accessors

interface IDataRepository<D> {
	def Map<String, D> data()
	def List<D> list()
	
	def D get(String id)
	def void add(String id, D data)
	def D remove(String id)
}

class Repository<D> implements IDataRepository<D> {
	@Accessors var (Change) => void onChange
	
	val Map<String, D> table
	
	new() { this(new HashMap<String, D>) }
	new(Map<String, D> table) {
		this.table = table
	}
	
	override data() { table }
	
	override list() { table.values.toList }
	
	override get(String id) {
		return table.get(id)
	}
	
	override add(String id, D data) {
		table.put(id, data)
		onChange?.apply(new Change(Change.Operation.ADD, id, data))
	}
	
	override remove(String id) {
		val value = table.remove(id)
		if (value != null && onChange != null)
			onChange.apply(new Change(Change.Operation.REM, id, null))
		
		return value
	}
}

class Change {
	enum Operation { ADD, REM }
	
	public val String id
	public val String oper
	public val Object data
	
	new(Operation oper, String id, Object data) {
		this.id = id
		this.oper = oper.name.toLowerCase
		this.data = data
	}
}