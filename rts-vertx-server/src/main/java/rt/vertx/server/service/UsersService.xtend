package rt.vertx.server.service

import rt.data.Data
import rt.pipeline.UserInfo
import rt.plugin.service.an.Context
import rt.plugin.service.an.Public
import rt.plugin.service.an.Service

@Service
@Data(metadata = false)
class UsersService {
	//val IDataRepository<UserInfo> users
	
	@Public
	@Context(name = 'user', type = UserInfo)
	def UserInfo me() { return user }
}