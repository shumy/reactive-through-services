package rt.utils.service

import rt.data.Data
import rt.plugin.service.ServiceException
import rt.plugin.service.an.Context
import rt.plugin.service.an.Public
import rt.plugin.service.an.Service
import rt.utils.interceptor.UserInfo

@Service
@Data(metadata = false)
class UsersService {
	//val IDataRepository<UserInfo> users
	
	@Public
	@Context(name = 'user', type = UserInfo)
	def UserInfo me() {
		if (user === null)
			throw new ServiceException(404, '''Invalid token or user!''')
			
		return user
	}
}