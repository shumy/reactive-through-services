package rt.vertx.server.web.service

import java.util.List
import rt.data.Data
import rt.data.Default
import rt.data.Optional
import rt.data.Validation
import rt.data.ValidationException
import rt.pipeline.pipe.Pipeline
import rt.plugin.service.ServiceException
import rt.plugin.service.an.Public
import rt.plugin.service.an.Service
import rt.plugin.service.descriptor.DMethod
import rt.plugin.service.descriptor.IDescriptor

@Service(metadata = false)
@Data(metadata = false)
class DescriptorService {
	val Pipeline pipeline
	
	@Default('false') val boolean autoDetect 
	@Optional val List<String> services
	
	transient var List<String> _services
	
	@Validation
	def construct() {
		if (!autoDetect && services == null)
			throw new ValidationException('Service config are not optional with auto detection off!')
		
		if (autoDetect)
			_services = pipeline.componentPaths.map[ replaceAll('srv:', '') ].filter[ pipeline.getService(it) instanceof IDescriptor ].toList
		else
			_services = services
	}
	
	@Public
	def List<String> specs() { _services }
	
	@Public
	def Spec srvSpec(String srvName) {
		if (!_services.contains(srvName))
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