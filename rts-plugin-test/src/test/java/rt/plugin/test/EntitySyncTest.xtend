package rt.plugin.test

import org.junit.Test
import rt.plugin.test.entity.AnEntity
import java.util.List
import rt.entity.change.Change
import rt.plugin.test.entity.OtherEntity
import com.google.gson.GsonBuilder
import rt.entity.change.ChangeType
import org.junit.Assert

class EntitySyncTest {
	static val gson = new GsonBuilder().create
	
	@Test
	def void observeChanges() {
		val List<String> changes = newArrayList
		
		new AnEntity => [
			name = 'not observed'
			onChange[ changes.add(gson.toJson(it)) ]
			
			//start change listening...
			name = 'Alex'
			active = true
			other = new OtherEntity('Fred')
			other.name = 'Rex'
			
			othersList.add(new OtherEntity('Nikon'))
		]
		
		val expected = #[
			new Change(ChangeType.UPDATE, 'Alex', #['name']),
			new Change(ChangeType.UPDATE, true, #['active']),
			new Change(ChangeType.UPDATE, new OtherEntity('Fred'), #['other']),
			new Change(ChangeType.UPDATE, 'Rex', #['name', 'other']),
			new Change(ChangeType.ADD, new OtherEntity('Nikon'), #['end', 'othersList'])
		]
		
		Assert.assertArrayEquals(changes, expected.map[ gson.toJson(it) ])
	}
	
}