package rt.plugin.test.data

import rt.data.Data
import java.util.List
import rt.data.Default
import rt.data.Optional
import rt.data.ValidationException
import rt.data.Validation

@Data(metadata = true)
class TestData {
	val String name
	val int age
	val List<TestDataItem> items
	
	@Optional val String opt
	
	@Validation
	def void custom() {
		if (name == 'Invalid-Name')
			throw new ValidationException('Field :name is invalid!')
	}
}

@Data(metadata = true)
class TestDataItem {
	val String name
	val boolean correct
	@Default('12L') val long defVar
}