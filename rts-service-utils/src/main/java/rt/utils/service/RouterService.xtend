package rt.utils.service

import rt.data.Data
import rt.plugin.service.an.Service
import rt.plugin.service.Router
import rt.plugin.service.an.Public
import java.util.List

@Service(metadata = false)
@Data(metadata = false)
class RouterService {
	val Router router
	
	@Public
	def List<Route> routes() {
		router.restRoutes.map[ r |
			val rPath = new StringBuilder()
			r.routePaths.forEach[ rPath.append('/') rPath.append(toString) ]
			
			Route.B => [
				wMeth = r.wMethod.name.toLowerCase
				path = rPath.toString
				srv = r.srvAddress
				meth = r.srvMethod
				pMaps = r.paramMaps
			]
		]
	}
}

@Data(metadata = false)
class Route {
	val String wMeth
	val String path
	val String srv
	val String meth
	val List<String> pMaps
}