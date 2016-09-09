import { Observable, Subscriber } from 'rxjs/Rx';
import { ClientRouter } from './rts-client-service';
import { RemoteObservable, Repository, EventProcessor, CmdType, ReqType } from './rts-remotes';

export * from './rts-remotes';

function pCreate(proxy: any, srv: any) {
  return (remote: any, req: ReqType) => {
    if (req === 'connect') {
      proxy.subscribe(remote.address)
        .then(_ => remote.connected = true)
        .catch(error => {
          remote.connected = false
          console.error('Failed connect on address: ' + remote.address, error)
        })
    } else if (req === 'complete') {
      //complete is invoked by the server, no need to unsubscribe
      srv.delete(remote.address)
    } else if(req === 'disconnect') {
      proxy.unsubscribe(remote.address)
      srv.delete(remote.address)
    } else if (req === 'init') {
      proxy.init(remote.address)
        .then(initData => {
          remote.process('ev:nxt', { oper: 'init', data: initData })
        })
        .catch(error => {
          remote.process('ev:err', error)
          console.error('Failed init on address: ' + remote.address, error)
        })
    }
  }
}

//--------------------------------------------------------------------------------------
//*******EventsService*******
//--------------------------------------------------------------------------------------
interface Event {
  address: string
  data?: any
}

export class EventsService {
  private processors = new Map<string, EventProcessor>()

  constructor(private router: ClientRouter) {
    router.pipeline.addService('events', (ctx) => {
      let event = ctx.message.res as Event
      let processor = this.processors.get(event.address)
      if (processor)
        processor.process(ctx.message.cmd as CmdType, event.data)
    })
  }

  add(address: string, processor: EventProcessor) {
    this.processors.set(address, processor)
  }

  remove(address: string) {
    this.processors.delete(address)
  }
}

//--------------------------------------------------------------------------------------
//*******SubscriberService*******
//--------------------------------------------------------------------------------------
export class SubscriberService {
  private proxy: SubscriberProxy
  observers = new Map<string, RemoteObservable>()

  constructor(private router: ClientRouter, private evtSrv: EventsService) {
    this.proxy = router.createProxy('subscriber') as SubscriberProxy
  }

  get(address: string): RemoteObservable {
    return this.observers.get(address)
  }

  create(address: string): RemoteObservable {
    let ro = new RemoteObservable(address, pCreate(this.proxy, this))

    this.evtSrv.add(address, ro)
    this.observers.set(address, ro)
    return ro
  }

  delete(address: string) {
    this.observers.delete(address)
    this.evtSrv.remove(address)
  }
}

interface SubscriberProxy {
  subscribe(address: string): Promise<void>
  unsubscribe(address: string): Promise<void>
}

//--------------------------------------------------------------------------------------
//*******RepositoryService*******
//--------------------------------------------------------------------------------------
export class RepositoryService {
  private proxy: RepositoryProxy
  repos = new Map<string, Repository>()

  constructor(private router: ClientRouter, private evtSrv: EventsService) {
    this.proxy = router.createProxy('repository') as RepositoryProxy
  }

  list(): Promise<string[]> {
    return this.proxy.list()
  }

  get(address: string): Repository {
    return this.repos.get(address)
  }

  create(address: string): Repository {
    let repo = new Repository(address, pCreate(this.proxy, this))

    this.evtSrv.add(address, repo)
    this.repos.set(address, repo)
    return repo
  }

  delete(address: string) {
    this.repos.delete(address)
    this.evtSrv.remove(address)
  }
}

interface RepositoryProxy extends SubscriberProxy {
  list(): Promise<string[]>
  init(address: string): Promise<any[]>
}