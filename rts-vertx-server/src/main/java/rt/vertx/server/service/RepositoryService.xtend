package rt.vertx.server.service

import java.util.ArrayList
import java.util.HashMap
import java.util.List
import java.util.Map
import rt.async.pubsub.IPublisher
import rt.async.pubsub.IResource
import rt.data.Data
import rt.data.Optional
import rt.data.Repository
import rt.data.Validation
import rt.plugin.service.ServiceException
import rt.plugin.service.ServiceUtils
import rt.plugin.service.an.Context
import rt.plugin.service.an.Public
import rt.plugin.service.an.Service

@Service
@Data(metadata = false)
class RepositoryService {
	transient val dataRepos = new HashMap<String, Repository<?>>
	transient var IPublisher publisher
	
	@Optional var List<String> repos
	
	@Validation
	def void constructor() {
		publisher = ServiceUtils.publisher
		
		if (repos === null)
			repos = new ArrayList<String>
		
		repos.forEach[ createDataRepo ]
	}
	
	@Public
	@Context(name = 'resource', type = IResource)
	def void subscribe(String address) {
		if (!repos.contains(address))
			throw new ServiceException(404, 'Repository not found!')
		
		resource.subscribe(address)
	}
	
	@Public
	@Context(name = 'resource', type = IResource)
	def void unsubscribe(String address) {
		if (!repos.contains(address))
			throw new ServiceException(404, 'Repository not found!')
		
		resource.unsubscribe(address)
	}
	
	@Public
	def List<String> list() { repos }
	
	@Public
	def Map<String, Object> init(String address) { getRepo(address).data }
	
	
	def <T> Repository<T> getRepo(String address) {
		if (!repos.contains(address))
			throw new ServiceException(404, 'Repository not found!')
			
		dataRepos.get(address) as Repository<T>
	}
	
	def create(String... addresses) {
		addresses.forEach[ repos.add(it) createDataRepo ]
	}
	
	def delete(String adr) {
		repos.remove(adr)
		dataRepos.remove(adr)
	}
	
	private def void createDataRepo(String adr) {
		val ro = RemoteSubscriber.B => [ address = adr publisher = this.publisher ]
		val repo = new Repository<Object>
		repo.onChange = ro.link
		
		dataRepos.put(adr, repo)
	}
}