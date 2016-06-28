package rt.vertx.server.test

import io.vertx.ext.unit.TestContext
import io.vertx.ext.unit.junit.RunTestOnContext
import io.vertx.ext.unit.junit.VertxUnitRunner
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.Before
import org.junit.Assert
import com.google.gson.Gson
import rt.pipeline.Registry
import rt.pipeline.IMessageBus.Message
import rt.pipeline.pipe.use.ValidatorInterceptor
import rt.pipeline.IComponent
import rt.pipeline.pipe.PipeContext
import rt.vertx.server.VertxMessageBus
import rt.vertx.server.MessageConverter

@RunWith(VertxUnitRunner)
class PipelineTest {
	Gson gson
	Registry registry
	
	@Rule
	public val rule = new RunTestOnContext
	
	@Before
	def void init(TestContext ctx) {
		val converter = new MessageConverter
		val mb = new VertxMessageBus(rule.vertx.eventBus, converter)
		
		this.gson = new Gson
		this.registry = new Registry('domain', mb)
	}
	
	@Test
	def compareMessages() {
		val msg1 = new Message => [id=1L cmd='ping' client='source']
		val msg2 = new Message => [id=1L cmd='ping' client='source']
		Assert.assertEquals(gson.toJson(msg1), gson.toJson(msg2))
	}
	
	@Test(timeout = 500)
	def void validateMandatoryFields(TestContext ctx) {
		val sync = ctx.async(4)

		println('validateMandatoryFields')
		val pipeline = registry.createPipeline => [
			addInterceptor(new ValidatorInterceptor)
			failHandler = [
				sync.countDown
	
				if(sync.count == 3)
					ctx.assertEquals(it, "No mandatory field 'id'")

				if(sync.count == 2)
					ctx.assertEquals(it, "No mandatory field 'cmd'")
					
				if(sync.count == 1)
					ctx.assertEquals(it, "No mandatory field 'client'")
				
				if(sync.count == 0)
					ctx.assertEquals(it, "No mandatory field 'path'")
			]
		]
		
		val r = pipeline.createResource('uid', 'r', [ println(it) ], null)
		r.subscribe('uid')
		r.process(new Message => [])
		r.process(new Message => [id=1L])
		r.process(new Message => [id=1L cmd='ping'])
		r.process(new Message => [id=1L cmd='ping' client='source'])
	}
	
	@Test
	def void deliverMessageToService(TestContext ctx) {
		println('deliverMessageToService')
		val msg = new Message => [id=1L cmd='ping' client='source' path='srv:test']

		val srv = new IComponent {
			override getName() { return 'srv:test' }
			
			override apply(PipeContext pctx) {
				ctx.assertEquals(gson.toJson(pctx.message), gson.toJson(msg))
			}
		}
		
		val pipeline = registry.createPipeline => [
			addInterceptor(new ValidatorInterceptor)
			addService(srv)
			failHandler = [ ctx.fail(it) ]
		]
		
		val r = pipeline.createResource('uid', 'r', null, null)
		r.subscribe('uid')
		r.process(msg)
	}
	
	@Test(timeout = 500)
	def void serviceReplyToMessage(TestContext ctx) {
		val sync = ctx.async(1)
		
		println('serviceReplyToMessage')
		val msg = new Message => [id=1L cmd='ping' client='source' path='srv:test']
		val reply = new Message => [id=1L cmd='ok' client='source']

		val srv = new IComponent {
			override getName() { return 'srv:test' }
			
			override apply(PipeContext pctx) {
				ctx.assertEquals(gson.toJson(pctx.message), gson.toJson(msg))
				pctx.replyOK
			}
		}
		
		val pipeline = registry.createPipeline => [
			addInterceptor(new ValidatorInterceptor)
			addService(srv)
			failHandler = [ ctx.fail(it) ]
		]
		
		val r = pipeline.createResource('uid', 'r', [ ctx.assertEquals(gson.toJson(it), gson.toJson(reply)) sync.countDown ], null)
		r.subscribe('uid')
		r.process(msg)
	}
	
	@Test(timeout = 500)
	def void deliverMessageToSubscriptors(TestContext ctx) {
		val sync = ctx.async(2)

		println('deliverMessageToSubscriptors')
		val msg = new Message => [id=1L cmd='ping' client='source' path='target']
		
		val pipeline = registry.createPipeline => [
			addInterceptor(new ValidatorInterceptor)
			failHandler = [ ctx.fail(it) ]
		]
		
		val r1 = pipeline.createResource('uid1', 'r1', [ ctx.assertEquals(gson.toJson(it), gson.toJson(msg)) sync.countDown ], null)
		r1.subscribe('uid1')
		r1.subscribe('target')
		
		val r2 = pipeline.createResource('uid2', 'r2', [ ctx.assertEquals(gson.toJson(it), gson.toJson(msg)) sync.countDown ], null)
		r2.subscribe('uid2')
		r2.subscribe('target')
		
		val r3 = pipeline.createResource('uid3', 'r3', null, null)
		r3.subscribe('uid3')
		r3.process(msg)
	}
	
	@Test(timeout = 500)
	def void deliverMessageToMultipleConnectionsOfSameSession(TestContext ctx) {
		val sync = ctx.async(2)
		
		println('deliverMessageToMultipleConnectionsOfSameSession')
		val msg = new Message => [id=1L cmd='ping' client='source' path='uid']
		
		val pipeline = registry.createPipeline => [
			addInterceptor(new ValidatorInterceptor)
			failHandler = [ ctx.fail(it) ]
		]
		
		val r1 = pipeline.createResource('uid', 'r1', [ ctx.assertEquals(gson.toJson(it), gson.toJson(msg)) sync.countDown ], null)
		r1.subscribe('uid')
		
		val r2 = pipeline.createResource('uid', 'r2', [ ctx.assertEquals(gson.toJson(it), gson.toJson(msg)) sync.countDown ], null)
		r2.subscribe('uid')
		r2.process(msg)
	}
}