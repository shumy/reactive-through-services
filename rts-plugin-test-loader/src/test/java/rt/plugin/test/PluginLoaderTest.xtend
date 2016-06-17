package rt.plugin.test

import rt.plugin.PluginRepository
import org.junit.Test
import java.io.File
import org.junit.Assert
import rt.pipeline.IComponent
import static extension rt.plugin.InvokerHelper.*

class PluginLoaderTest {
	
	@Test
	def void loadLogbackAndDependencies() {
		val home = System.getProperty('user.home')
		val local = '''«home»«File.separator».m2«File.separator»repository'''
		
		val repo = new PluginRepository(local) => [
			plugins += 'rt.syncher:rts-plugin-test:0.2.0'
			resolve
		]

		val plugin = repo.plugins.artifact('rt.syncher:rts-plugin-test:0.2.0')
		val srv = plugin.newInstanceFromEntry(IComponent, 'srv', 'rt.plugin.test.srv.AnnotatedService')
		Assert.assertEquals(srv.name, 'srv:test')

		val iHello = repo.instanceOf('rt.plugin.test.HelloWorld')
		val result = iHello.invoke('hello', 'Alex')
		Assert.assertEquals(result, 'Hello Alex')
	}
}