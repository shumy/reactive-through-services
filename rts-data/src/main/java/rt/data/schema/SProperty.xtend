package rt.data.schema

class SProperty {
	public val SType type
	public val String name
	public val boolean opt
	
	public val Object defaultValue
	
	new(String name, SType type, boolean isOptional, Object defaultValue) {
		this.name = name
		this.type = type
		this.opt = isOptional
		
		this.defaultValue = defaultValue
	}
	
}