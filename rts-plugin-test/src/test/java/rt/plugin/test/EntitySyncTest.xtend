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
		
		val nikonEntity = new OtherEntity('Nikon')
		val canonEntity = new OtherEntity('Canon')
		
		val entity = new AnEntity => [
			name = 'not observed'
			onChange[ changes.add(gson.toJson(it)) ]
			
			uuid = 'ignored'
			
			//start change listening...
			name = 'Alex'
			active = true
			other = new OtherEntity('Fred')
			other.name = 'Rex'
			
			othersList.add(nikonEntity)
			othersList.add(canonEntity)
			othersMap.put('key', canonEntity)
		]
		
		canonEntity.name = 'Canon-Update-1'
		
		entity.othersList.remove(0)
		canonEntity.name = 'Canon-Update-2'
		
		//not observed
		nikonEntity.name = 'Nikon-Update'
		
		val expected = #[
			new Change(ChangeType.UPDATE, 'Alex', #['name']),
			new Change(ChangeType.UPDATE, true, #['active']),
			new Change(ChangeType.UPDATE, new OtherEntity('Fred'), #['other']),
			new Change(ChangeType.UPDATE, 'Rex', #['name', 'other']),
			new Change(ChangeType.ADD, new OtherEntity('Nikon'), #['end', 'othersList']),
			new Change(ChangeType.ADD, new OtherEntity('Canon'), #['end', 'othersList']),
			new Change(ChangeType.ADD, new OtherEntity('Canon'), #['key', 'othersMap']),
			
			new Change(ChangeType.UPDATE, 'Canon-Update-1', #['name', '1', 'othersList']),
			new Change(ChangeType.UPDATE, 'Canon-Update-1', #['name', 'key', 'othersMap']),
			
			new Change(ChangeType.REMOVE, 1, #['0', 'othersList']),
			new Change(ChangeType.UPDATE, 'Canon-Update-2', #['name', '0', 'othersList']),
			new Change(ChangeType.UPDATE, 'Canon-Update-2', #['name', 'key', 'othersMap'])
		].map[ gson.toJson(it) ]
		
		println('CHANGES:  ' + changes)
		println('EXPECTED: ' + expected)
		Assert.assertArrayEquals(changes, expected)
	}
	
}