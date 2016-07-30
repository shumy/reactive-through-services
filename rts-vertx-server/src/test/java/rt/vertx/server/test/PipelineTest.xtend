package rt.vertx.server.test

import com.google.gson.Gson
import io.vertx.ext.unit.TestContext
import io.vertx.ext.unit.junit.RunTestOnContext
import io.vertx.ext.unit.junit.VertxUnitRunner
import org.junit.Assert
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import rt.async.pubsub.Message
import rt.pipeline.DefaultMessageBus
import rt.pipeline.IComponent
import rt.pipeline.pipe.Pipeline
import rt.pipeline.pipe.use.ValidatorInterceptor

@RunWith(VertxUnitRunner)
class PipelineTest {
	val Gson gson = new Gson
	
	@Rule
	public val rule = new RunTestOnContext
	
	@Test
	def void compareMessages() {
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
					ctx.assertEquals(message, "No mandatory field 'id'")

				if(sync.count == 2)
					ctx.assertEquals(message, "No mandatory field 'cmd'")
					
				if(sync.count == 1)
					ctx.assertEquals(message, "No mandatory field 'client'")
				
				if(sync.count == 0)
					ctx.assertEquals(message, "No mandatory field 'path'")
			]
		]
		
		pipeline.createResource('uid') => [
			sendCallback = [ println(it) ]
			subscribe('uid')
			process(new Message => [])
			process(new Message => [id=1L])
			process(new Message => [id=1L cmd='ping'])
			process(new Message => [id=1L cmd='ping' clt='source'])
		]
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
		
		pipeline.createResource('uid') => [
			subscribe('uid')
			process(msg)	
		]
	}
	
	@Test(timeout = 500)
	def void serviceReplyToMessage(TestContext ctx) {
		val sync = ctx.async(1)
		
		println('serviceReplyToMessage')
		val msg = new Message => [id=1L cmd='ping' clt='source' path='srv:test']
		val reply = new Message => [id=1L typ='rpl' cmd='ok' clt='source']

		val IComponent srv = [ pctx |
			ctx.assertEquals(gson.toJson(pctx.message), gson.toJson(msg))
			pctx.replyOK
		]
		
		val pipeline = new Pipeline(new DefaultMessageBus) => [
			addInterceptor(new ValidatorInterceptor)
			addService('test', srv)
			failHandler = [ ctx.fail(it) ]
		]
		
		pipeline.createResource('uid') => [
			sendCallback = [ ctx.assertEquals(gson.toJson(it), gson.toJson(reply)) sync.countDown ]
			subscribe('uid')
			process(msg)
		]
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
		
		pipeline.createResource('uid1') => [
			sendCallback = [ ctx.assertEquals(gson.toJson(it), gson.toJson(msg)) sync.countDown ]
			subscribe('uid1')
			subscribe('target')
		]
		
		pipeline.createResource('uid2') => [
			sendCallback = [ ctx.assertEquals(gson.toJson(it), gson.toJson(msg)) sync.countDown ]
			subscribe('uid2')
			subscribe('target')
		]
		
		pipeline.createResource('uid3') => [
			subscribe('uid3')
			process(msg)
		]
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
		
		pipeline.createResource('uid') => [
			sendCallback = [ ctx.assertEquals(gson.toJson(it), gson.toJson(msg)) sync.countDown ]
			subscribe('uid')
		]
		
		pipeline.createResource('uid') => [
			sendCallback = [ ctx.assertEquals(gson.toJson(it), gson.toJson(msg)) sync.countDown ]
			subscribe('uid')
			process(msg)
		]
	}
}