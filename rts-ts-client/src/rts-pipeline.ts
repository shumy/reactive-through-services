import { MessageBus, Listener, IMessage, TYP } from './rts-messagebus'

export class Pipeline {
  private _failHandler: (String) => void = null

  private interceptors: ((ctx: PipeContext) => void)[] = []
  private services = new Map<string, (ctx: PipeContext) => void>()

  constructor(public mb: MessageBus = new MessageBus) { }

  failHandler(callback: (error: String) => void) {
    this._failHandler = callback
  }

  process(resource: PipeResource, msg: IMessage, onContextCreated?: (ctx: PipeContext) => void) {
    let ctx = new PipeContext(this, resource, msg, new Iterator(this.interceptors))
    if (onContextCreated) onContextCreated(ctx)
    ctx.next()
  }

  createResource(client: string, sendCallback: (msg: IMessage) => void, closeCallback: () => void) {
		  return new PipeResource(this, client, sendCallback, closeCallback)
  }

  fail(error: string) {
		  if (this._failHandler != null)
      this._failHandler(error)
  }

  addInterceptor(interceptor: (ctx: PipeContext) => void) {
		  this.interceptors.push(interceptor)
  }

  getComponent(path: string) {
		  return this.services.get(path)
  }

  getService(address: string) {
		  return this.services.get('srv:' + address)
  }

  addService(address: string, service: (ctx: PipeContext) => void) {
    this.services.set('srv:' + address, service)
  }

  removeService(address: string) {
    this.services.delete('srv:' + address)
  }
}

export class PipeResource {
  subscriptions = new Map<string, Listener>()

  constructor(private pipeline: Pipeline, private client: string, private sendCallback: (msg: IMessage) => void, private closeCallback: () => void) {
    console.log('RESOURCE-CREATE ', this.client)
  }

  process(msg: IMessage, onContextCreated?: (ctx: PipeContext) => void) {
    this.pipeline.process(this, msg, onContextCreated)
  }

  send(msg: IMessage) {
    this.sendCallback(msg)
  }

  subscribe(address: string) {
    if (this.subscriptions.has(address))
      return false

    console.log('RESOURCE-SUBSCRIBE ', address)
    let listener = this.pipeline.mb.listener(address, this.sendCallback)

    this.subscriptions.set(address, listener)
    return true
  }

  unsubscribe(address: string) {
    let listener = this.subscriptions.get(address)
    if (listener) {
      console.log('RESOURCE-UNSUBSCRIBE ', address)
      this.subscriptions.delete(address)
      listener.remove()
    }
  }

  release() {
    console.log('RESOURCE-RELEASE ', this.client)
    let subs = this.subscriptions.forEach(_ => _.remove())
    this.subscriptions.clear()
  }

  disconnect() {
    this.closeCallback()
  }
}

export class PipeContext {
  private objects = new Map<string, Object>()
  private inFail: boolean = false

  get bus() { return this.pipeline.mb }

  setObject(type: string, instance: Object) { this.objects.set(type, instance) }
  getObject(type: string) { return this.objects.get(type) }

  constructor(private pipeline: Pipeline, public resource: PipeResource, public message: IMessage, private iter: Iterator<(ctx: PipeContext) => void>) { }

  deliver() {
    if (!this.inFail) {
      try {
        if (this.message.typ === TYP.REPLY)
          this.deliverReply()
        else
          this.deliverRequest()
      } catch (error) {
        console.error(error)
        if (this.message.typ !== TYP.PUBLISH) this.fail(error)
      }
    }
  }

  next() {
    if (!this.inFail) {
      if (this.iter.hasNext) {
        try {
          this.iter.next().apply(this)
        } catch (error) {
          console.error(error)
          this.fail(error)
        }
      } else {
        this.deliver()
      }
    }
  }

  send(msg: IMessage) {
    if (!this.inFail) {
      this.resource.send(msg)
    }
  }

  fail(error: string) {
    if (!this.inFail) {
      this.replyError(error)
      this.pipeline.fail(error)
      this.inFail = true
    }
  }

  reply(replyMsg: IMessage) {
    if (!this.inFail) {
      replyMsg.id = this.message.id
      replyMsg.clt = this.message.clt
      replyMsg.typ = TYP.REPLY

      this.resource.send(replyMsg)
    }
  }

	replyOK() {
		if (!this.inFail) {
      let replyMsg: IMessage = { cmd: TYP.CMD_OK }
			this.reply(replyMsg)
		}
	}
	
  replyResultOK(result: any) {
    if (!this.inFail) {
      let replyMsg: IMessage = { cmd: TYP.CMD_OK, res: result }
      this.reply(replyMsg)
    }
  }

  replyError(error: string) {
    if (!this.inFail) {
      let replyMsg: IMessage = { cmd: TYP.CMD_ERROR, res: error }
      this.reply(replyMsg)
    }
  }

  disconnect() {
    this.resource.disconnect()
  }

  private deliverRequest() {
    let srv = this.pipeline.getComponent(this.message.path)
    if (srv) {
      console.log('DELIVER(' + this.message.path + ')')
      srv(this)
    } else {
      console.log('PUBLISH(' + this.message.path + ')')
      this.pipeline.mb.publish(this.message.path, this.message)
    }
  }

  private deliverReply() {
		console.log('DELIVER-REPLY(' + this.message.clt + ', ' + this.message.id + ')')
		this.pipeline.mb.reply(this.message)
  }
}

export class Iterator<T> {
  private index: number = -1

  constructor(private array: T[]) { }

  get hasNext(): boolean {
    return this.index < this.array.length - 1
  }

  next(): T {
    this.index++
    return this.array[this.index]
  }
}