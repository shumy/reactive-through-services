package rt.data.schema

import java.util.List
import java.util.HashMap

class SType {
	public transient val Class<?> cTyp
	public transient val List<Class<?>> cTypArgs
	
	public val String typ
	public val List<String> typArgs
	
	new(Class<?> cTyp, List<Class<?>> cTypArgs) {
		this.cTyp = cTyp
		this.cTypArgs = cTypArgs
		
		this.typ = cTyp.simpleName.native
		this.typArgs = if (cTypArgs.length != 0) cTypArgs.map[ simpleName.native ] else null
	}
	
	def getAllSchemas() {
		val schemas = new HashMap<String, List<SProperty>>
		
		if (ISchema.isAssignableFrom(cTyp))
			schemas.put(cTyp.simpleName, cTyp.getDeclaredField('properties').get(cTyp) as List<SProperty>)
		
		cTypArgs.forEach[
			if (ISchema.isAssignableFrom(it))
				schemas.put(simpleName, getDeclaredField('properties').get(it) as List<SProperty>)
		]
		
		return schemas
	}
	
	static def from(Class<?> type, Class<?>... typeArguments) {
		return new SType(type, typeArguments.toList)
	}
	
	private static def getNative(String inType) {
		val type = inType.replaceAll('\\s+','')
		
		switch type {
			case 'Void': 		'void'
			case 'String':		'str'
			case 'Boolean':		'bol'
			case 'Integer':		'int'
			case 'Long':		'lng'
			case 'Float':		'flt'
			case 'Double':		'dbl'
			//TODO: cases for dates ?
			
			default: {
				if (type.startsWith('List')) return 	'lst'
				if (type.startsWith('Set')) return 		'set'
				if (type.startsWith('Map')) return 		'map'
				
				return type
			}
		}
	}
}