package rt.plugin.test

import rt.plugin.PluginRepository
import org.junit.Test
import static extension rt.plugin.InvokerHelper.*
import java.io.File
import org.junit.Assert

class RemoteLoadTest {
	
	@Test
	def void loadLogbackAndDependencies() {
		val home = System.getProperty('user.home')
		val local = '''«home»«File.separator».m2«File.separator»repository'''
		
		val repo = new PluginRepository(local) => [
			plugins += 'rt.syncher:rts-plugin-test:0.1.0'
			resolve
		]

		val iHello = repo.instanceOf('rt.plugin.test.HelloWorld')
		val result = iHello.invoke('hello', 'Alex')
		Assert.assertEquals(result, 'Hello Alex')
	}
}