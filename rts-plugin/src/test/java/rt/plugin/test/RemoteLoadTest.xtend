package rt.plugin.test

import rt.plugin.PluginRepository
//import org.junit.Test

class RemoteLoadTest {
	
	//@Test
	def void loadLogbackAndDependencies() {
		val repo = new PluginRepository('target/local-repo') => [
			plugins += 'ch.qos.logback:logback-classic:1.1.7'
		]
		
		repo.resolve
	}
}