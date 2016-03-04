package rt.node.test

import io.vertx.ext.unit.TestContext
import io.vertx.ext.unit.junit.RunTestOnContext
import io.vertx.ext.unit.junit.VertxUnitRunner
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.Before
import rt.node.pipeline.use.ValidatorInterceptor
import rt.node.Registry

import rt.node.IComponent
import rt.node.pipeline.PipeContext
import io.vertx.core.json.JsonObject

@RunWith(VertxUnitRunner)
class PipelineTest {
	Registry registry
	
	@Rule
	public val rule = new RunTestOnContext
	
	@Before
	def void init(TestContext ctx) {
		this.registry = new Registry("domain", rule.vertx)
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
		
		val r = pipeline.createResource("uid", "r", [ println(it) ], null)
		r.process(new JsonObject('{}'))
		r.process(new JsonObject('{"id":1}'))
		r.process(new JsonObject('{"id":1,"cmd":"ping"}'))
		r.process(new JsonObject('{"id":1,"cmd":"ping","client":"source"}'))
	}
	
	@Test
	def void deliverMessageToService(TestContext ctx) {
		println('deliverMessageToService')
		val msg = new JsonObject('{"id":1,"cmd":"ping","client":"source","path":"srv:test"}')

		val srv = new IComponent {
			override getName() { return "srv:test" }
			
			override apply(PipeContext pctx) {
				ctx.assertEquals(pctx.message.json, msg)
			}
		}
		
		val pipeline = registry.createPipeline => [
			addInterceptor(new ValidatorInterceptor)
			addService(srv)
			failHandler = [ ctx.fail(it) ]
		]
		
		val r = pipeline.createResource("uid", "r", null, null)
		r.process(msg)
	}
	
	@Test(timeout = 500)
	def void serviceReplyToMessage(TestContext ctx) {
		val sync = ctx.async(1)
		
		println('serviceReplyToMessage')
		val msg = new JsonObject('{"id":1,"cmd":"ping","client":"source","path":"srv:test"}')
		val reply = new JsonObject('{"id":1,"cmd":"ok","client":"source"}')

		val srv = new IComponent {
			override getName() { return "srv:test" }
			
			override apply(PipeContext pctx) {
				ctx.assertEquals(pctx.message.json, msg)
				pctx.replyOK
			}
		}
		
		val pipeline = registry.createPipeline => [
			addInterceptor(new ValidatorInterceptor)
			addService(srv)
			failHandler = [ ctx.fail(it) ]
		]
		
		val r = pipeline.createResource("uid", "r", [ ctx.assertEquals(it, reply) sync.countDown ], null)
		r.process(msg)
	}
	
	@Test(timeout = 500)
	def void deliverMessageToSubscriptors(TestContext ctx) {
		val sync = ctx.async(2)

		println('deliverMessageToSubscriptors')
		val msg = new JsonObject('{"id":1,"cmd":"ping","client":"source","path":"target"}')
		
		val pipeline = registry.createPipeline => [
			addInterceptor(new ValidatorInterceptor)
			failHandler = [ ctx.fail(it) ]
		]
		
		val r1 = pipeline.createResource("uid1", "r1", [ ctx.assertEquals(it, msg) sync.countDown ], null)
		r1.subscribe("target")
		
		val r2 = pipeline.createResource("uid2", "r2", [ ctx.assertEquals(it, msg) sync.countDown ], null)
		r2.subscribe("target")
		
		val r3 = pipeline.createResource("uid3", "r3", null, null)
		r3.process(msg)
	}
	
	@Test(timeout = 500)
	def void deliverMessageToMultipleConnectionsOfSameSession(TestContext ctx) {
		val sync = ctx.async(2)
		
		println('deliverMessageToMultipleConnectionsOfSameSession')
		val msg = new JsonObject('{"id":1,"cmd":"ping","client":"source","path":"uid"}')
		
		val pipeline = registry.createPipeline => [
			addInterceptor(new ValidatorInterceptor)
			failHandler = [ ctx.fail(it) ]
		]
		
		pipeline.createResource("uid", "r1", [ ctx.assertEquals(it, msg) sync.countDown ], null)
		val r2 = pipeline.createResource("uid", "r2", [ ctx.assertEquals(it, msg) sync.countDown ], null)
		r2.process(msg)
	}
}