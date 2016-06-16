package rt.plugin.test

import rt.plugin.PluginRepository
import org.junit.Test
import org.slf4j.Logger
import org.slf4j.LoggerFactory

class RemoteLoadTest {
	
	@Test
	def void loadLogbackAndDependencies() {
		val repo = new PluginRepository('target/local-repo') => [
			plugins += 'org.slf4j:slf4j-api:1.7.21'
		]
		
		repo.resolve
		
		val factory = repo.load('org.slf4j.LoggerFactory')
		val method = factory.getMethod('getLogger', String)
		
		val nLogger = LoggerFactory.getLogger('NORMAL-LOGGER')
		nLogger.info('Just a log {}', 'Test')
		
		val pLogger = method.invoke(factory, 'PLUGIN-LOGGER') as Logger
		pLogger.info('Just a log {}', 'Test')
	}
}