package rt.vertx.server.test

import io.vertx.ext.unit.TestContext
import io.vertx.ext.unit.junit.RunTestOnContext
import io.vertx.ext.unit.junit.VertxUnitRunner
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.Assert
import com.google.gson.Gson
import rt.pipeline.IMessageBus.Message
import rt.pipeline.pipe.use.ValidatorInterceptor
import rt.pipeline.IComponent
import rt.pipeline.DefaultMessageBus
import rt.pipeline.pipe.Pipeline

@RunWith(VertxUnitRunner)
class PipelineTest {
	val Gson gson = new Gson
	
	@Rule
	public val rule = new RunTestOnContext
	
	@Test
	def compareMessages() {
		val msg1 = new Message => [id=1L cmd='ping' clt='source']
		val msg2 = new Message => [id=1L cmd='ping' clt='source']
		Assert.assertEquals(gson.toJson(msg1), gson.toJson(msg2))
	}
	
	@Test(timeout = 500)
	def void validateMandatoryFields(TestContext ctx) {
		val sync = ctx.async(4)

		println('validateMandatoryFields')
		val pipeline = new Pipeline(new DefaultMessageBus) => [
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
		
		val r = pipeline.createResource('uid', [ println(it) ], null)
		r.subscribe('uid')
		r.process(new Message => [])
		r.process(new Message => [id=1L])
		r.process(new Message => [id=1L cmd='ping'])
		r.process(new Message => [id=1L cmd='ping' clt='source'])
	}
	
	@Test
	def void deliverMessageToService(TestContext ctx) {
		println('deliverMessageToService')
		val msg = new Message => [id=1L cmd='ping' clt='source' path='srv:test']

		val IComponent srv = [ pctx |
			ctx.assertEquals(gson.toJson(pctx.message), gson.toJson(msg))
		]
		
		val pipeline = new Pipeline(new DefaultMessageBus) => [
			addInterceptor(new ValidatorInterceptor)
			addService('test', srv)
			failHandler = [ ctx.fail(it) ]
		]
		
		val r = pipeline.createResource('uid', null, null)
		r.subscribe('uid')
		r.process(msg)
	}
	
	@Test(timeout = 500)
	def void serviceReplyToMessage(TestContext ctx) {
		val sync = ctx.async(1)
		
		println('serviceReplyToMessage')
		val msg = new Message => [id=1L cmd='ping' clt='source' path='srv:test']
		val reply = new Message => [id=1L cmd='ok' clt='source']

		val IComponent srv = [ pctx |
			ctx.assertEquals(gson.toJson(pctx.message), gson.toJson(msg))
			pctx.replyOK
		]
		
		val pipeline = new Pipeline(new DefaultMessageBus) => [
			addInterceptor(new ValidatorInterceptor)
			addService('test', srv)
			failHandler = [ ctx.fail(it) ]
		]
		
		val r = pipeline.createResource('uid', [ ctx.assertEquals(gson.toJson(it), gson.toJson(reply)) sync.countDown ], null)
		r.subscribe('uid')
		r.process(msg)
	}
	
	@Test(timeout = 500)
	def void deliverMessageToSubscriptors(TestContext ctx) {
		val sync = ctx.async(2)

		println('deliverMessageToSubscriptors')
		val msg = new Message => [id=1L cmd='ping' clt='source' path='target']
		
		val pipeline = new Pipeline(new DefaultMessageBus) => [
			addInterceptor(new ValidatorInterceptor)
			failHandler = [ ctx.fail(it) ]
		]
		
		val r1 = pipeline.createResource('uid1', [ ctx.assertEquals(gson.toJson(it), gson.toJson(msg)) sync.countDown ], null)
		r1.subscribe('uid1')
		r1.subscribe('target')
		
		val r2 = pipeline.createResource('uid2', [ ctx.assertEquals(gson.toJson(it), gson.toJson(msg)) sync.countDown ], null)
		r2.subscribe('uid2')
		r2.subscribe('target')
		
		val r3 = pipeline.createResource('uid3', null, null)
		r3.subscribe('uid3')
		r3.process(msg)
	}
	
	@Test(timeout = 500)
	def void deliverMessageToMultipleConnectionsOfSameSession(TestContext ctx) {
		val sync = ctx.async(2)
		
		println('deliverMessageToMultipleConnectionsOfSameSession')
		val msg = new Message => [id=1L cmd='ping' clt='source' path='uid']
		
		val pipeline = new Pipeline(new DefaultMessageBus) => [
			addInterceptor(new ValidatorInterceptor)
			failHandler = [ ctx.fail(it) ]
		]
		
		val r1 = pipeline.createResource('uid', [ ctx.assertEquals(gson.toJson(it), gson.toJson(msg)) sync.countDown ], null)
		r1.subscribe('uid')
		
		val r2 = pipeline.createResource('uid', [ ctx.assertEquals(gson.toJson(it), gson.toJson(msg)) sync.countDown ], null)
		r2.subscribe('uid')
		r2.process(msg)
	}
}