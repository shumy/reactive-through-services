package rt.vertx.server.web

import io.vertx.core.Handler
import io.vertx.core.http.HttpServerRequest
import org.slf4j.LoggerFactory
import java.io.File
import org.eclipse.xtend.lib.annotations.Accessors
import rt.plugin.service.Service
import rt.plugin.service.Public

@Service('http-uploader')
class FileUploaderService {
	static val logger = LoggerFactory.getLogger('HTTP-UPLOADER')
	
	@Accessors val String path
	@Accessors val Handler<HttpServerRequest> handler
	
	new(String path) {
		this.path = path
		
		val folder = new File(path)
		if (!folder.exists) folder.mkdirs
		
		handler = [ req | 
			req.expectMultipart = true
			req.uploadHandler[upload |
				logger.info('UPLOADING {}', upload.filename)
				
				//protect against filesystem attacks
				if (upload.filename.contains('..')) {
					logger.info('ERROR {}', 'Filename not accepted!')
					req.response.statusCode = 500
					req.response.end = 'Filename not accepted!'
					return
				}
				
				val filePath = path + '/' + upload.filename
				req.response.chunked = true
				
				upload.exceptionHandler[
					logger.info('ERROR {}', message)
					
					req.response.statusCode = 500
					req.response.end = 'Failed: ' + message
				]
				
				upload.endHandler[
					logger.info('SAVED {}', filePath)
					req.response.end ='Success'
				]
				
				upload.streamToFileSystem(filePath)
			]
		]
	}
	
	@Public
	def list(String inPath) {
		if (path.contains('..'))
			throw new RuntimeException('Path not accepted!')
		
		val folder = new File(path + inPath)
		return folder.list.toList
	}
}
