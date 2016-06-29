package rt.vertx.server.test

import io.vertx.ext.unit.junit.VertxUnitRunner
import org.junit.runner.RunWith
import org.junit.Rule
import io.vertx.ext.unit.junit.RunTestOnContext
import org.junit.Before
import io.vertx.ext.unit.TestContext
import org.junit.Test
import java.io.File
import com.google.gson.Gson
import rt.plugin.PluginRepository
import rt.pipeline.pipe.Pipeline
import rt.pipeline.pipe.use.ValidatorInterceptor
import rt.pipeline.IMessageBus.Message
import rt.pipeline.IComponent
import rt.pipeline.DefaultMessageBus

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
			addService(srv)
			failHandler = [ ctx.fail(it) ]
		]
	}
	
	@Test(timeout = 1000)
	def void serviceHelloCall(TestContext ctx) {
		val sync = ctx.async(1)

		println('serviceHelloCall')
		val msg = new Message => [id=1L cmd='hello' clt='source' path='srv:test' args=#['Micael', 'Pedrosa']]
		val reply = new Message => [id=1L cmd='ok' clt='source' result='Hello Micael Pedrosa!']
		
		val r = pipeline.createResource('uid', 'r', [ ctx.assertEquals(gson.toJson(it), gson.toJson(reply)) sync.countDown ], null)
		r.subscribe('uid')
		r.process(msg)
	}
	
	@Test(timeout = 1000)
	def void serviceSumCall(TestContext ctx) {
		val sync = ctx.async(1)

		println('serviceSumCall')
		val msg = new Message => [id=1L cmd='sum' clt='source' path='srv:test' args=#[1, 2L, 1.5f, 2.5]]
		val reply = new Message => [id=1L cmd='ok' clt='source' result=7.0]
		
		val r = pipeline.createResource('uid', 'r', [ ctx.assertEquals(gson.toJson(it), gson.toJson(reply)) sync.countDown ], null)
		r.subscribe('uid')
		r.process(msg)
	}
	
	@Test(timeout = 1000)
	def void serviceAlexBrothersCall(TestContext ctx) {
		val sync = ctx.async(1)

		println('serviceAlexBrothersCall')
		val msg = new Message => [id=1L cmd='alexBrothers' clt='source' path='srv:test' args=#[#{'name'->'Alex', 'age'->35}]]
		val reply = new Message => [id=1L cmd='ok' clt='source' result=#{'name'->'Alex', 'age'->35, 'brothers'->#['Jorge', 'Mary']}]
		
		val r = pipeline.createResource('uid', 'r', [ ctx.assertEquals(gson.toJson(it), gson.toJson(reply)) sync.countDown ], null)
		r.subscribe('uid')
		r.process(msg)
	}
}