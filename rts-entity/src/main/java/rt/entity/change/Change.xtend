package rt.entity.change

import java.util.List
import java.util.LinkedList
import org.eclipse.xtend.lib.annotations.Accessors

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
	
	@Accessors val ChangeType oper
	@Accessors val String type
	@Accessors val Object value
	
	@Accessors val List<Object> path
	
	new(ChangeType oper, String type, Object value, List<Object> path) {
		this.oper = oper
		this.type = type
		this.value = value
		this.path = path
	}
	
	new(ChangeType oper, Object value, List<Object> path) {
		this(
			oper,
			createType(oper, value.class),
			value,
			path
		)
	}
	
	new(ChangeType oper, Object value, Object path) {
		this(oper, value, #[ path ])
	}
	
	def Change addPath(Object path, boolean transitive) {
		val newChange = new Change(this.oper, this.type, this.value, new LinkedList<Object>)
		newChange.path.addAll(this.path)
		newChange.path.add(path)
		newChange.tr = this.tr || transitive
		
		return newChange
	}
	
	static def String createType(ChangeType oper, Class<?> clazz) {
		if (oper == ChangeType.UPDATE || oper == ChangeType.ADD)
			return typeConversions.get(clazz) ?: clazz.canonicalName
		
		return null
	}
}