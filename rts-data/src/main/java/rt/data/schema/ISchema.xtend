package rt.data.schema

import java.util.List

interface ISchema {
	def List<SProperty> getProperties()
}