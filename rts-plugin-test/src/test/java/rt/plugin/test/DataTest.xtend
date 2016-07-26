package rt.plugin.test

import com.google.gson.GsonBuilder
import org.junit.Assert
import org.junit.Test
import rt.plugin.test.data.TestData
import rt.plugin.test.data.TestDataItem
import rt.data.ValidationException

import static extension rt.plugin.test.data.TestData.*
import static extension rt.plugin.test.data.TestDataItem.*

class DataTest {
	static val gson = new GsonBuilder().create
	
	@Test
	def void dataSerialize() {
		val t = TestData => [
			name = 'Alex'
			age = 35
			
			items = #[
				TestDataItem => [ name = 'item-a' correct = true ],
				TestDataItem => [ name = 'item-b' correct = false defVar = 30L ]
			]
			
			itemMap = #{
				'first' -> (TestDataItem => [ name = 'item-a' correct = true ])
			}
		]
		
		Assert.assertEquals(gson.toJson(t), '{"name":"Alex","age":35,"items":[{"name":"item-a","correct":true,"defVar":12},{"name":"item-b","correct":false,"defVar":30}],"itemMap":{"first":{"name":"item-a","correct":true,"defVar":12}}}')
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
			TestData => [
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
			TestData => [
				name = 'Invalid-Name'
				age = 35
				items = #[
					TestDataItem => [ name = 'item-a' correct = true ],
					TestDataItem => [ name = 'item-b' correct = false defVar = 30L ]
				]
			]
		} catch(ValidationException ex) {
			Assert.assertEquals(ex.message, 'Field :name is invalid!')
			return
		}
		
		Assert.fail
	}
	
	@Test
	def void dataSchema() {
		val t = TestData => [
			name = 'Alex'
			age = 35
			
			items = #[
				TestDataItem => [ name = 'item-a' correct = true ],
				TestDataItem => [ name = 'item-b' correct = false defVar = 30L ]
			]
			
			itemMap = #{
				'first' -> (TestDataItem => [ name = 'item-a' correct = true ])
			}
		]
		
		Assert.assertEquals(gson.toJson(t.properties), '[{"type":{"typ":"str"},"name":"name","opt":false},{"type":{"typ":"int"},"name":"age","opt":false},{"type":{"typ":"lst","typArgs":["TestDataItem"]},"name":"items","opt":false},{"type":{"typ":"map","typArgs":["str","TestDataItem"]},"name":"itemMap","opt":true},{"type":{"typ":"str"},"name":"opt","opt":true},{"type":{"typ":"TestDataItem"},"name":"item","opt":true}]')
		Assert.assertEquals(gson.toJson(t.items.get(0).properties), '[{"type":{"typ":"str"},"name":"name","opt":false},{"type":{"typ":"bol"},"name":"correct","opt":false},{"type":{"typ":"lng"},"name":"defVar","opt":false,"defv":12}]')
		
	}
	
}