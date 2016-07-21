package rt.plugin.test

import com.google.gson.GsonBuilder
import org.junit.Assert
import org.junit.Test
import rt.plugin.test.data.TestData
import rt.plugin.test.data.TestDataItem
import rt.data.ValidationException

class DataTest {
	static val gson = new GsonBuilder().create
	
	@Test
	def void dataSerialize() {
		val t = TestData.B => [
			name = 'Alex'
			age = 35
			items = #[
				TestDataItem.B => [ name = 'item-a' correct = true ],
				TestDataItem.B => [ name = 'item-b' correct = false defVar = 30L ]
			]
		]
		
		Assert.assertEquals(gson.toJson(t), '{"name":"Alex","age":35,"items":[{"name":"item-a","correct":true,"defVar":12},{"name":"item-b","correct":false,"defVar":30}]}')
	}
	
	@Test
	def void dataDeserialize() {
		val json = '{"name":"Alex","age":35,"items":[{"name":"item-a","correct":true,"defVar":12},{"name":"item-b","correct":false,"defVar":30}]}'
		val t = gson.fromJson(json, TestData)
		
		Assert.assertEquals(t.name, 'Alex')
		Assert.assertEquals(t.age, 35)
		
			val itemA = t.items.get(0)
			Assert.assertEquals(itemA.name, 'item-a')
			Assert.assertEquals(itemA.correct, true)
			Assert.assertEquals(itemA.defVar, 12)
		
			val itemB = t.items.get(1)
			Assert.assertEquals(itemB.name, 'item-b')
			Assert.assertEquals(itemB.correct, false)
			Assert.assertEquals(itemB.defVar, 30)
	}
	
	@Test
	def void mandatoryValidation() {
		try {
			TestData.B => [
				name = 'Alex'
				age = 35
			]
		} catch(ValidationException ex) {
			Assert.assertEquals(ex.message, 'Field :items is mandatory!')
			return
		}
		
		Assert.fail
	}
	
	@Test
	def void customValidation() {
		try {
			TestData.B => [
				name = 'Invalid-Name'
				age = 35
				items = #[
					TestDataItem.B => [ name = 'item-a' correct = true ],
					TestDataItem.B => [ name = 'item-b' correct = false defVar = 30L ]
				]
			]
		} catch(ValidationException ex) {
			Assert.assertEquals(ex.message, 'Field :name is invalid!')
			return
		}
		
		Assert.fail
	}
	
}