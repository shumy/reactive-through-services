package rt.plugin.test

import rt.plugin.PluginRepository
import org.junit.Test
import java.io.File
import org.junit.Assert
import rt.pipeline.IComponent
import static extension rt.plugin.InvokerHelper.*
import org.junit.BeforeClass
import rt.plugin.PluginArtifact

class PluginLoaderTest {
	static var PluginRepository repo
	static var PluginArtifact plugin
	
	@BeforeClass
	def static void init() {
		val home = System.getProperty('user.home')
		val local = '''«home»«File.separator».m2«File.separator»repository'''
		
		repo = new PluginRepository(local) => [
			plugins += 'rts.core:rts-plugin-test:0.3.0'
			resolve
		]
		
		plugin = repo.plugins.artifact('rts.core:rts-plugin-test:0.3.0')
	}
	
	@Test
	def void containsServices() {
		val expected = #['rt.plugin.test.srv.AnnotatedService', 'rt.plugin.test.srv.OtherService']
		val services = plugin.config.entries.map[ if (type == 'srv') ref ].toList
		services.forEach[
			Assert.assertTrue(expected.contains(it))
		]
	}
	
	@Test
	def void isServiceInstance() {
		val srv = plugin.newInstanceFromEntry(IComponent, 'srv', 'rt.plugin.test.srv.AnnotatedService')
		Assert.assertNotNull(srv)
	}
	
	@Test
	def void invokeMethod() {
		val iHello = repo.instanceOf('rt.plugin.test.HelloWorld')
		val result = iHello.invoke('hello', 'Alex')
		Assert.assertEquals(result, 'Hello Alex')
	}
	
}