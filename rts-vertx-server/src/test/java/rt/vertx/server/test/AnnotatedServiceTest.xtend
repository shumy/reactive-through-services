package rt.vertx.server.test

import com.google.gson.Gson
import io.vertx.ext.unit.TestContext
import io.vertx.ext.unit.junit.RunTestOnContext
import io.vertx.ext.unit.junit.VertxUnitRunner
import java.io.File
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import rt.async.pubsub.Message
import rt.pipeline.DefaultMessageBus
import rt.pipeline.IComponent
import rt.pipeline.pipe.Pipeline
import rt.pipeline.pipe.use.ValidatorInterceptor
import rt.plugin.PluginRepository

@RunWith(VertxUnitRunner)
class AnnotatedServiceTest {
	val Gson gson = new Gson
	Pipeline pipeline
	
	@Rule
	public val rule = new RunTestOnContext
	
	@Before
	def void init(TestContext ctx) {
		val home = System.getProperty('user.home')
		val local = '''«home»«File.separator».m2«File.separator»repository'''
		
		val repo = new PluginRepository(local) => [
			plugins += 'rts.core:rts-plugin-test:0.2.0'
			resolve
		]
		
		val plugin = repo.plugins.artifact('rts.core:rts-plugin-test:0.2.0')
		val srv = plugin.newInstanceFromEntry(IComponent, 'srv', 'rt.plugin.test.srv.AnnotatedService')
		
		val bus = new DefaultMessageBus
		
		pipeline = new Pipeline(bus) => [
			addInterceptor(new ValidatorInterceptor)
			addService('test', srv)
			failHandler = [ ctx.fail(it) ]
		]
	}
	
	@Test(timeout = 1000)
	def void serviceHelloCall(TestContext ctx) {
		val sync = ctx.async(1)

		println('serviceHelloCall')
		val msg = new Message => [id=1L cmd='hello' clt='source' path='srv:test' args=#['Micael', 'Pedrosa']]
		val reply = new Message => [id=1L typ='rpl' cmd='ok' clt='source' result='Hello Micael Pedrosa!']
		
		pipeline.createResource('uid') => [
			sendCallback = [ ctx.assertEquals(gson.toJson(it), gson.toJson(reply)) sync.countDown ]
			subscribe('uid')
			process(msg)
		]
	}
	
	@Test(timeout = 1000)
	def void serviceSumCall(TestContext ctx) {
		val sync = ctx.async(1)

		println('serviceSumCall')
		val msg = new Message => [id=1L cmd='sum' clt='source' path='srv:test' args=#[1, 2L, 1.5f, 2.5]]
		val reply = new Message => [id=1L typ='rpl' cmd='ok' clt='source' result=7.0]
		
		pipeline.createResource('uid') => [
			sendCallback = [ ctx.assertEquals(gson.toJson(it), gson.toJson(reply)) sync.countDown ]
			subscribe('uid')
			process(msg)
		]
	}
	
	@Test(timeout = 1000)
	def void serviceAlexBrothersCall(TestContext ctx) {
		val sync = ctx.async(1)

		println('serviceAlexBrothersCall')
		val msg = new Message => [id=1L cmd='alexBrothers' clt='source' path='srv:test' args=#[#{'name'->'Alex', 'age'->35}]]
		val reply = new Message => [id=1L typ='rpl' cmd='ok' clt='source' result=#{'name'->'Alex', 'age'->35, 'brothers'->#['Jorge', 'Mary']}]
		
		pipeline.createResource('uid') => [
			sendCallback = [ ctx.assertEquals(gson.toJson(it), gson.toJson(reply)) sync.countDown ]
			subscribe('uid')
			process(msg)
		]
	}
}