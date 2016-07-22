package rt.plugin.service.descriptor

import rt.data.schema.SType
import java.util.List
import rt.data.schema.SProperty

class DMethod {
	public val String name
	public val SType retType
	public val List<SProperty> params
	
	new(String name, SType returnType, List<SProperty> params) {
		this.name = name
		this.retType = returnType
		this.params = params
	}
}