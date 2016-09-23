package rt.utils.service

import java.nio.ByteBuffer
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.Paths
import java.util.HashMap
import java.util.Map
import org.slf4j.LoggerFactory
import rt.data.Data
import rt.data.Default
import rt.data.Optional
import rt.pipeline.PathValidator
import rt.plugin.service.ServiceException
import rt.plugin.service.an.Public
import rt.plugin.service.an.Service
import rt.data.Validation

@Service(metadata = false)
@Data(metadata = false)
class WebFileService {
	static val logger = LoggerFactory.getLogger('HTTP-FILE-REQUEST')
	
	transient val cacheData = new HashMap<String, ByteBuffer>
	
	@Default('false') val boolean resource
	@Default('false') val boolean cache
	@Default('"/index.html"') val String index
	
	@Optional var Map<String, String> replace
	
	val String folder
	
	@Validation
	def void constructor() {
		replace = replace?:#{}
	}
	
	@Public
	def ByteBuffer file(String path) {
		val filePath = folder + path.filePath
		
		logger.debug(filePath)
		var Path urlPath = null
		if (resource) {
			val uri = this.class.getResource(filePath).toURI
			urlPath = Paths.get(uri)
		} else {
			urlPath = Paths.get(filePath)
		}
		
		if (cache) {
			var content = cacheData.get(path)
			if (content == null) {
				content = urlPath.read
				cacheData.put(path, content)
			}
			
			return content
		} else {
			return urlPath.read
		}
	}
	
	private def read(Path urlPath) {
		try {
			val cntBytes = Files.readAllBytes(urlPath)
			return ByteBuffer.wrap(cntBytes) => [
				limit(cntBytes.length)
			]
		} catch(Exception ex) {
			throw new ServiceException(404, 'File not found: ' + urlPath)
		}
	}
	
	private def filePath(String inPath) {
		//protect against filesystem attacks
		if (!PathValidator.isValid(inPath))
			throw new ServiceException(403, 'Request path not accepted!')
		
		val path = if (!inPath.startsWith('/')) '/' + inPath.redirect else inPath.redirect
		return if (path == '/') index else path 
	}
	
	private def redirect(String uri) {
		for (key: replace.keySet) {
			if (uri.startsWith(key)) {
				val value = replace.get(key)
				val redirect = uri.replaceFirst(key, value)
				
				logger.info('Redirect: {} -> {}', uri, redirect)
				return redirect
			}
		}
		
		return uri
	}
}