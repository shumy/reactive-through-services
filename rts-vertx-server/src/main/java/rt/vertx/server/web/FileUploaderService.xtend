package rt.vertx.server.web

import io.vertx.core.http.HttpServerRequest
import org.slf4j.LoggerFactory
import java.io.File
import rt.plugin.service.an.Service
import rt.plugin.service.an.Public
import static extension rt.vertx.server.URIParserHelper.*
import java.util.List

@Service
class FileUploaderService {
	static val logger = LoggerFactory.getLogger('HTTP-FILE-UPLOADER')
	
	val String path
	
	new(String path) {
		this.path = path
		
		val folder = new File(path)
		if (!folder.exists) folder.mkdirs
	}
	
	@Public(notif = true)
	def void get(HttpServerRequest req) {
		req.expectMultipart = true
		req.uploadHandler[upload |
			logger.debug('UPLOADING {}', upload.filename)
			
			//protect against filesystem attacks
			if (!upload.filename.validPath) {
				logger.error('Filename not accepted: {}', upload.filename)
				req.response.statusCode = 403
				req.response.end = 'Filename not accepted!'
				return
			}
			
			val filePath = path + '/' + upload.filename
			req.response.chunked = true
			
			upload.exceptionHandler[
				logger.error('ERROR {}', message)
				req.response.statusCode = 500
				req.response.end = 'Failed: ' + message
			]
			
			upload.endHandler[
				logger.info('SAVED {}', filePath)
				req.response.end = 'Success'
			]
			
			upload.streamToFileSystem(filePath)
		]
	}
	
	@Public
	def List<String> list(String inPath) {
		//protect against filesystem attacks
		if (!path.validPath)
			throw new RuntimeException('Path not accepted: ' + inPath)
		
		val folder = new File(path + inPath)
		return folder.list.toList
	}
}
