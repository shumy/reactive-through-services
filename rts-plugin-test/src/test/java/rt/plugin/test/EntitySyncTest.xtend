package rt.plugin.test

import org.junit.Test
import rt.plugin.test.entity.AnEntity
import java.util.List
import rt.entity.change.Change
import rt.plugin.test.entity.OtherEntity
import com.google.gson.GsonBuilder
import rt.entity.change.ChangeType
import org.junit.Assert
import rt.entity.sync.EntityList
import rt.entity.Repository

class EntitySyncTest {
	static val gson = new GsonBuilder().create
	
	@Test
	def void observeChanges() {
		val List<String> changes = newArrayList
		val List<String> repoChanges = newArrayList
		
		val repo = new Repository<AnEntity>('AnEntity')
		repo.onChange[ repoChanges.add(gson.toJson(it)) ]
		
		val nikonEntity = new OtherEntity('Nikon')
		val canonEntity = new OtherEntity('Canon')
		val fredEntity = new OtherEntity('Fred')
		
		val entity = new AnEntity => [
			name = 'not observed'
			repo.addEntity(it)
			onChange[ changes.add(gson.toJson(it)) ]
			
			uuid = 'ignored'
			
			//start change listening...
			name = 'Alex'
			active = true
			other = fredEntity
			other.name = 'Rex'
			
			othersList.add(nikonEntity)
			othersList.add(canonEntity)
			othersMap.put('key', canonEntity)
		]
		
		var String entityUUID = 'repo-AnEntity:' + entity.key.uuid
		
		canonEntity.name = 'Canon-Update-1'
		
		entity.othersList.remove(0)
		canonEntity.name = 'Canon-Update-2'
		
		//not observed, because it was removed from othersList
		nikonEntity.name = 'Nikon-Update'
		
		//not transitive
		val eList = new EntityList<String>
		entity.textList.add(eList)
		eList.add('text')
		
		entity.remove
		
		//these change are not detected because listeners where removed
		entity.remove 
		repo.removeEntity(entity.key.uuid)
		
		val expected = #[
			new Change(ChangeType.UPDATE, 'Alex', #['name']),
			new Change(ChangeType.UPDATE, true, #['active']),
			new Change(ChangeType.UPDATE, new OtherEntity('Fred'), #['other']),
			new Change(ChangeType.UPDATE, 'Rex', #['name']).addPath('other', true),
			new Change(ChangeType.ADD, new OtherEntity('Nikon'), #['end', 'othersList']),
			new Change(ChangeType.ADD, new OtherEntity('Canon'), #['end', 'othersList']),
			new Change(ChangeType.ADD, new OtherEntity('Canon'), #['key', 'othersMap']),
			
			new Change(ChangeType.UPDATE, 'Canon-Update-1', #['name', '1']).addPath('othersList', true),
			new Change(ChangeType.UPDATE, 'Canon-Update-1', #['name', 'key']).addPath('othersMap', true),
			
			new Change(ChangeType.REMOVE, 1, #['0', 'othersList']),
			new Change(ChangeType.UPDATE, 'Canon-Update-2', #['name', '0']).addPath('othersList', true),
			new Change(ChangeType.UPDATE, 'Canon-Update-2', #['name', 'key']).addPath('othersMap', true),
			
			new Change(ChangeType.ADD, new EntityList, #['end', 'textList']),
			new Change(ChangeType.ADD, 'text', #['end', '0', 'textList'])
		].map[ gson.toJson(it) ]
		
		println('CHANGES:  ' + changes)
		println('EXPECTED: ' + expected)
		//Assert.assertArrayEquals(changes, expected)
		
		val repoExpected = #[
			new Change(ChangeType.ADD, new AnEntity => [name='not observed'], #[entityUUID + ':' + 2]),
			new Change(ChangeType.UPDATE, 'Alex', #['name', entityUUID + ':' + 3]),
			new Change(ChangeType.UPDATE, true, #['active', entityUUID + ':' + 4]),
			new Change(ChangeType.UPDATE, fredEntity.class.canonicalName, fredEntity.key.uuid + ':' + 1, #['other', entityUUID + ':' + 5]),
			
			new Change(ChangeType.ADD, nikonEntity.class.canonicalName, nikonEntity.key.uuid + ':' + 1, #['end', 'othersList', entityUUID + ':' + 6]),
			new Change(ChangeType.ADD, canonEntity.class.canonicalName, canonEntity.key.uuid + ':' + 1, #['end', 'othersList', entityUUID + ':' + 7]),
			new Change(ChangeType.ADD, canonEntity.class.canonicalName, canonEntity.key.uuid + ':' + 1, #['key', 'othersMap', entityUUID + ':' + 8]),
			
			new Change(ChangeType.REMOVE, 1, #['0', 'othersList', entityUUID + ':' + 9]),
			
			new Change(ChangeType.ADD, new EntityList, #['end', 'textList', entityUUID + ':' + 10]),
			new Change(ChangeType.ADD, 'text', #['end', '0', 'textList', entityUUID + ':' + 11]),
			
			new Change(ChangeType.REMOVE, 1, #[entityUUID + ':' + 11])
		].map[ gson.toJson(it) ]
		
		println('REPO-CHANGES:  ' + repoChanges)
		println('REPO-EXPECTED: ' + repoExpected)
		Assert.assertArrayEquals(repoChanges, repoExpected)
	}
	
}