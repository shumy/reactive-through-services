export class MessageBus {
  listeners = new Map<string, Set<Listener>>()
  private replyListeners = new Map<string, (msg: IMessage) => void>()

  publish(address: string, msg: IMessage) {
		if (!msg.typ) msg.typ = TYP.PUBLISH
    let addressListeners = this.listeners.get(address)
    if (addressListeners)
		  addressListeners.forEach(_ => _.send(msg))
  }

  send(address: string, msg: IMessage, replyCallback: (msg: IMessage) => void) {
    let replyID = msg.clt + '+' + msg.id
    this.replyListener(replyID, replyCallback)

	  msg.typ = TYP.SEND
    let addressListeners = this.listeners.get(address)
    if (addressListeners)
		  addressListeners.forEach(_ => _.send(msg))
		
    setTimeout(_ => {
      let replyTimeoutMsg: IMessage = { id: msg.id, clt: msg.clt, cmd: TYP.CMD_ERROR, res: 'Timeout for ' + msg.path + '->' + msg.cmd }
      this.reply(replyTimeoutMsg)
    }, 3000)
  }

  reply(msg: IMessage) {
    let replyID = msg.clt + '+' + msg.id

    let rOKBackAddress = replyID + '/reply-ok'
    let replyOKBackFun = this.replyListeners.get(rOKBackAddress)
    this.replyListeners.delete(rOKBackAddress)

    let rERRORBackAddress = replyID + '/reply-error'
		let replyERRORBackFun = this.replyListeners.get(rERRORBackAddress)
    this.replyListeners.delete(rERRORBackAddress)
		
		//process backward replies. In case of internal components need the information
		if (msg.cmd == TYP.CMD_OK) {
      if (replyOKBackFun) replyOKBackFun(msg)
		} else {
      if (replyERRORBackFun) replyERRORBackFun(msg)
		}
		
    let replyFun = this.replyListeners.get(replyID)
    if (replyFun) {
      this.replyListeners.delete(replyID)
      replyFun(msg)
    }
  }

  replyListener(replyID: string, listener: (msg: IMessage) => void) {
    this.replyListeners.set(replyID, listener)
  }

  listener(address: string, callback: (msg: IMessage) => void) {
    let holder = this.listeners.get(address)
    if (!holder) {
      holder = new Set<Listener>()
      this.listeners.set(address, holder)
    }

    let rtsListener = new Listener(this, address, callback)
    holder.add(rtsListener)

    return rtsListener
  }
}

export class Listener {
  constructor(private parent: MessageBus, private address: string, private callback: (msg: IMessage) => void) { }

  send(msg: IMessage) {
    this.callback(msg)
  }

  remove() {
    let holder = this.parent.listeners.get(this.address)
    if (holder)
      holder.delete(this)
  }
}

export interface IMessage {
  id?: number
  typ?: string
  clt?: string
  cmd?: string
  path?: string

  args?: any[]
  res?: any
}

export class TYP {
  static PUBLISH = 'pub'
  static SEND = 'snd'
  static REPLY = 'rpl'

  static CMD_OK = 'ok'
  static CMD_ERROR = 'err'
  static CMD_TIMEOUT = 'tout'
}