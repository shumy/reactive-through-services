package rt.vertx.server.service

import io.vertx.core.http.HttpServerRequest
import java.io.File
import java.util.List
import org.slf4j.LoggerFactory
import rt.data.Data
import rt.data.Default
import rt.data.Optional
import rt.data.Validation
import rt.pipeline.PathValidator
import rt.plugin.service.ServiceException
import rt.plugin.service.an.Context
import rt.plugin.service.an.Public
import rt.plugin.service.an.Service
import rt.utils.interceptor.UserInfo

@Service
@Data(metadata = false)
class FolderManagerService {
	static val logger = LoggerFactory.getLogger(FolderManagerService)
	
	val String folder
	@Default('false') val boolean isHomeManager
	
	@Validation
	def construct() {
		val fFolder = new File(folder)
		if (!fFolder.exists) fFolder.mkdirs
	}
	
	@Public(notif = true)
	@Context(name = 'user', type = UserInfo)
	def void download(HttpServerRequest req, String filename) {
		req.endHandler[
			logger.debug('DOWNLOADING {}', filename)
			
			//protect against filesystem attacks
			if (!PathValidator.isValid(filename)) {
				logger.error('Filename not accepted: {}', filename)
				req.response.statusCode = 403
				req.response.end = 'Filename not accepted!'
				return
			}
			
			val filePath = user.theFolder + '/' + filename
			
			req.response => [
				putHeader('Content-Type', 'application/octet-stream')
				sendFile(filePath)
			]
		]
	}

	@Public(notif = true)
	@Context(name = 'user', type = UserInfo)
	def void upload(HttpServerRequest req) {
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
			
			val filePath = user.theFolder + '/' + upload.filename
			req.response.chunked = true
			
			upload.exceptionHandler[
				logger.error('{}', message)
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
	@Context(name = 'user', type = UserInfo)
	def List<FileInfo> list(String inPath) {
		//protect against filesystem attacks
		if (!PathValidator.isValid(inPath))
			throw new RuntimeException('Path not accepted: ' + inPath)
		
		var folderPath = if (inPath == '*') user.theFolder else user.theFolder + '/' + inPath.replaceAll('>', '/')
		
		logger.debug('List folder {}', folderPath)
		
		val files = new File(folderPath).listFiles
		if (files === null) {
			logger.error('Folder not found {}', folderPath)
			throw new ServiceException(404, 'Folder not found')
		}
		
		return files.map[ file |
			FileInfo.B => [
				name = file.name
				isDir = file.directory
				if (!isDir) {
					val splits = file.name.split('\\.')
					if (splits.length > 1)
						type = splits.get(splits.length - 1)
						
					size = file.length
				}
			]
		]
	}
	
	private def String theFolder(UserInfo user) {
		val theFolder = if (!isHomeManager) folder else folder + '/' + user.name
		val fFolder = new File(theFolder)
		if (!fFolder.exists) fFolder.mkdirs
		
		return theFolder
	}
}

@Data
class FileInfo {
	val String name
	val Boolean isDir
	
	@Optional val String type
	@Optional val Long size
}