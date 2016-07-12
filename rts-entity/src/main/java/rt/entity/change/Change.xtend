package rt.entity.change

import java.util.List
import org.eclipse.xtend.lib.annotations.Accessors
import java.util.Iterator
import java.util.Stack

enum ChangeType {
	UPDATE, ADD, REMOVE, CLEAR
}

class Change {
	static val typeConversions = #{
		String -> 'string',
		Boolean -> 'bool',
		Integer -> 'int',
		Long -> 'long',
		Float -> 'float',
		Double -> 'double'
	}
	
	public static val PATH_SEPARATOR = '.'
	
	@Accessors(PUBLIC_GETTER) transient boolean tr = false //is transitive? Change from an internal IEntity
	@Accessors(PUBLIC_SETTER) transient Iterator<(Change) => void> iterator = null
	
	@Accessors val ChangeType oper
	@Accessors val String type
	@Accessors val Object value
	@Accessors val Stack<String> path
	
	new(ChangeType oper, String type, Object value, List<String> path) {
		this.oper = oper
		this.type = type
		this.value = value
		this.path = new Stack<String>
		
		path.forEach[ this.path.push(it) ]
	}
	
	new(ChangeType oper, Object value, List<String> path) {
		this(
			oper,
			createType(oper, value.class),
			value,
			path
		)
	}
	
	new(ChangeType oper, Object value, String path) {
		this(oper, value, #[ path ])
	}
	
	def void removeListener() { iterator.remove }
	
	def Change pushPath(String path, boolean transitive) {
		val newChange = new Change(this.oper, this.type, this.value, this.path)
		newChange.path.push(path)
		newChange.tr = this.tr || transitive
		
		return newChange
	}
	
	static def String createType(ChangeType oper, Class<?> clazz) {
		if (oper == ChangeType.UPDATE || oper == ChangeType.ADD)
			return typeConversions.get(clazz) ?: clazz.canonicalName
		
		return null
	}
}