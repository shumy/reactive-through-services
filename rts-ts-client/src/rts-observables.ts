import { Observable, Subscriber } from 'rxjs/Rx';
import { PipeResource } from './rts-pipeline'
import { MessageBus, Subscription, IMessage, TYP } from './rts-messagebus'

export class RTSObservable extends Observable<any> {
  private data = []
  private isComplete = false

  private sub: Subscriber<any>

  constructor(private resource: PipeResource, private address: string) {
    super(sub => {
      this.sub = sub
      
      if (this.data.length !== 0) {
        this.data.forEach(entry => {
          if (entry[0] === true) {
            this.sub.next(entry[1])
          } else {
            this.sub.error(entry[1])
            this.resource.unsubscribe(this.address)
          }
        })
      }

      if (this.isComplete) {
        this.sub.complete()
        this.resource.unsubscribe(this.address)
      }
    })
    
    resource.subscribe(address, msg => {
      if (msg.cmd === TYP.CMD_OK) {
        this.processNext(msg.res)
      } else if (msg.cmd === TYP.CMD_COMPLETE) {
        this.processComplete()
      } else if (msg.cmd === TYP.CMD_ERROR) {
        this.processError(msg.res)
      }
    })
  }

  cancel() {
    this.resource.unsubscribe(this.address)
    this.resource.send({
      clt: this.resource.client,
			typ: TYP.PUBLISH,
			cmd: TYP.CMD_CANCEL,
			path: this.address
    })
  }

  request(n: number) {
    this.resource.send({
      clt: this.resource.client,
			typ: TYP.PUBLISH,
			cmd: TYP.CMD_REQUEST,
			path: this.address,
			res: n
    })
  }

  private processNext(item: any) {
    if (this.sub)
      this.sub.next(item)
    else
      this.data.push([true, item])
  }

  private processComplete() {
    if (this.sub) {
      this.sub.complete()
      this.resource.unsubscribe(this.address)
    } else {
      this.isComplete = true
    }
  }

  private processError(error: any) {
    if (this.sub) {
      this.sub.error(error)
      this.resource.unsubscribe(this.address)
    } else
      this.data.push([false, error])
  }
}