package rt.vertx.server.service

import java.util.HashMap
import java.util.List
import java.util.Map
import rt.data.Data
import rt.data.Default
import rt.data.Optional
import rt.data.Validation
import rt.data.ValidationException
import rt.data.schema.SProperty
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
	@Optional var List<String> services
	
	@Validation
	def construct() {
		if (!autoDetect && services === null)
			throw new ValidationException('Service config are not optional with auto detection off!')
		
		if (autoDetect)
			services = pipeline.componentPaths.map[ replaceAll('srv:', '') ].filter[ pipeline.getService(it) instanceof IDescriptor ].toList
	}
	
	@Public
	def List<String> specs() { services }
	
	@Public
	def Spec srvSpec(String srvName) {
		if (!services.contains(srvName))
			throw new ServiceException(404, 'Service spec not found!')
			
		val desc = pipeline.getService(srvName) as IDescriptor
		
		val allSchemas = new HashMap<String, List<SProperty>>
		desc.methods.forEach[
			allSchemas.putAll(retType.allSchemas)
			params.forEach[ allSchemas.putAll(type.allSchemas) ]
		]
		
		return Spec.B => [
			srv = srvName
			meths = desc.methods
			schemas = allSchemas
		]
	}
}

@Data(metadata = false)
class Spec {
	val String srv
	val List<DMethod> meths
	val Map<String, List<SProperty>> schemas 
}