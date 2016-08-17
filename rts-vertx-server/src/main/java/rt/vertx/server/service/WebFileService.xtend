package rt.vertx.server.service

import java.nio.ByteBuffer
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.Paths
import java.util.HashMap
import org.slf4j.LoggerFactory
import rt.data.Data
import rt.data.Default
import rt.pipeline.PathValidator
import rt.plugin.service.ServiceException
import rt.plugin.service.an.Public
import rt.plugin.service.an.Service

@Service(metadata = false)
@Data(metadata = false)
class WebFileService {
	static val logger = LoggerFactory.getLogger('HTTP-FILE-REQUEST')
	
	transient val cacheData = new HashMap<String, ByteBuffer>
	
	@Default('""') val String root
	@Default('false') val boolean resource
	@Default('false') val boolean cache
	
	val String folder
	
	/*@Public(notif = true)
	def void notify(HttpServerRequest req) {
		val filePath = folder + req.path.filePath
		
		logger.debug(filePath)
		req.response.sendFile(filePath, 0, Long.MAX_VALUE)[
			if (!succeeded) {
				logger.error('File not found: {}', filePath)
				req.response.statusCode = 404
				req.response.end
			}
		]
	}*/
	
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
		
		val path = inPath.replaceFirst(root, '')
		
		return if (path == '/' || path == '') {
			'/index.html'
		} else {
			if (!path.startsWith('/')) '/' + path else path
		}
	}
}