package rt.vertx.server.web.service

import io.vertx.core.http.HttpServerRequest
import java.io.File
import java.util.List
import org.slf4j.LoggerFactory
import rt.pipeline.PathValidator
import rt.plugin.service.an.Public
import rt.plugin.service.an.Service
import rt.data.Validation
import rt.data.Data

@Service(metadata = false)
@Data(metadata = false)
class FileUploaderService {
	static val logger = LoggerFactory.getLogger('HTTP-FILE-UPLOADER')
	
	val String folder
	
	@Validation
	def construct() {
		val fFolder = new File(folder)
		if (!fFolder.exists) fFolder.mkdirs
	}
	
	@Public(notif = true)
	def void notify(HttpServerRequest req) {
		req.expectMultipart = true
		req.uploadHandler[upload |
			logger.debug('UPLOADING {}', upload.filename)
			
			//protect against filesystem attacks
			if (!PathValidator.isValid(upload.filename)) {
				logger.error('Filename not accepted: {}', upload.filename)
				req.response.statusCode = 403
				req.response.end = 'Filename not accepted!'
				return
			}
			
			val filePath = folder + '/' + upload.filename
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
		if (!PathValidator.isValid(folder))
			throw new RuntimeException('Path not accepted: ' + inPath)
		
		val folder = new File(folder + inPath)
		return folder.list.toList
	}
}
