package rt.data.schema

class SProperty {
	public val String type
	public val String name
	public val boolean isOptional
	
	public val Object defaultValue
	
	new(String type, String name, boolean isOptional, Object defaultValue) {
		this.type = type
		this.name = name
		this.isOptional = isOptional
		
		this.defaultValue = defaultValue
	}
}