package rt.utils.interceptor

import org.slf4j.LoggerFactory
import rt.data.Data
import rt.pipeline.IComponent
import rt.pipeline.pipe.PipeContext
import rt.plugin.service.ServiceException

@Data(metadata = false)
class AccessControlInterceptor implements IComponent {
	transient static val logger = LoggerFactory.getLogger(AccessControlInterceptor)
	
	override apply(PipeContext ctx) {
		val user = ctx.object(UserInfo)
		val groups = if (user !== null) user.groups else null
		
		if (!ctx.isAuthorized(ctx.message, groups)) {
			logger.error('Authorization failed on {} for user {}', ctx.message.path, user?.name)
			ctx.fail(new ServiceException(401, 'Unauthorized user!'))
			return
		}
		
		ctx.next
	}
}