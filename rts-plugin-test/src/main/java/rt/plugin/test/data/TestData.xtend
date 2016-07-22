package rt.plugin.test.data

import rt.data.Data
import java.util.List
import rt.data.Default
import rt.data.Optional
import rt.data.ValidationException
import rt.data.Validation
import java.util.Map

@Data
class TestData {
	val String name
	val int age
	val List< TestDataItem	> items
	
	@Optional val Map< String, TestDataItem> itemMap
	@Optional val String opt
	
	@Optional val TestDataItem item
	
	@Validation
	def void custom() {
		if (name == 'Invalid-Name')
			throw new ValidationException('Field :name is invalid!')
	}
}

@Data
class TestDataItem {
	val String name
	val boolean correct
	
	@Default('12L') val long defVar
}