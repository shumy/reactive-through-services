package rt.vertx.server.web.service

import java.util.List
import rt.data.Data
import rt.pipeline.pipe.Pipeline
import rt.plugin.service.ServiceException
import rt.plugin.service.an.Public
import rt.plugin.service.an.Service
import rt.plugin.service.descriptor.DMethod
import rt.plugin.service.descriptor.IDescriptor

@Service
@Data(metadata = false)
class SpecsService {
	val Pipeline pipeline
	val List<String> services
	
	@Public
	def List<String> specs() { services }
	
	@Public
	def Spec srvSpec(String srvName) {
		if (!services.contains(srvName))
			throw new ServiceException(404, 'Service spec not found!')
			
		val desc = pipeline.getService(srvName) as IDescriptor
		Spec.B => [ srv = srvName methods = desc.methods ]
	}
}

@Data(metadata = false)
class Spec {
	val String srv
	val List<DMethod> methods
}