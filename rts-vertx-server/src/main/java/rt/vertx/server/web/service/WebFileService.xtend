package rt.vertx.server.web.service

import io.vertx.core.http.HttpServerRequest
import java.nio.ByteBuffer
import java.nio.file.Files
import java.nio.file.Paths
import org.slf4j.LoggerFactory
import rt.pipeline.PathValidator
import rt.plugin.service.an.Public
import rt.plugin.service.an.Service
import rt.plugin.service.ServiceException
import rt.data.Data
import rt.data.Default
import java.nio.file.Path

@Service(metadata = false)
@Data(metadata = false)
class WebFileService {
	static val logger = LoggerFactory.getLogger('HTTP-FILE-REQUEST')
	
	@Default('""') val String root
	@Default('false') val boolean resource
	val String folder
	
	@Public(notif = true)
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
	}
	
	@Public
	def ByteBuffer file(String path) {
		val filePath = folder + path.filePath
		
		var Path urlPath = null
		if (resource) {
			val uri = this.class.getResource(filePath).toURI
			urlPath = Paths.get(uri)
		} else {
			urlPath = Paths.get(filePath)
		}
		
		val cntBytes = Files.readAllBytes(urlPath)
		val content = ByteBuffer.wrap(cntBytes) => [
			limit(cntBytes.length)
		]
		
		//TODO: cache content?
		return content
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