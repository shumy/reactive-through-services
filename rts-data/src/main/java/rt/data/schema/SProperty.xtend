package rt.data.schema

class SProperty {
	public val SType type
	public val String name
	public val Boolean opt
	public val Object defv
	
	new(String name, SType type) { this(name, type, null, null) }
	new(String name, SType type, Boolean isOptional, Object defaultValue) {
		this.name = name
		this.type = type
		this.opt = isOptional
		this.defv = defaultValue
	}
}