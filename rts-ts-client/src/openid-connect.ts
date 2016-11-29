declare const Cookies

export class OIDC {
  static discover(url: string): Promise<OIDCIssuer> {
    return get(url + '.well-known/openid-configuration', 3000)
      .then(res => new OIDCIssuer(res))
  }
}

export class OIDCIssuer {
  constructor(public discover: DiscoverResponse) {}

  createClient(clientId: string): OIDCClient {
    return new OIDCClient(this, clientId)
  }
}

export class OIDCClient {
  private redirectUri: string

  private authEndpoint: string
  private userInfoEndpoint: string
  private endSessionEndpoint: string
  private revocationEndpoint: string

  authHeader: string
  authInfo: AuthInfoResponse

  constructor(private issuer: OIDCIssuer, private clientId: string) {
    this.redirectUri = window.location.protocol + '//' + window.location.host + '/'

    this.authEndpoint = issuer.discover.authorization_endpoint + '?scope=email+openid&response_type=token+id_token&nonce=' + this.genNonce() + '&redirect_uri=' + this.redirectUri + '&client_id=' + clientId
    this.userInfoEndpoint = issuer.discover.userinfo_endpoint
    this.endSessionEndpoint = issuer.discover.end_session_endpoint
    this.revocationEndpoint = issuer.discover.revocation_endpoint

    //load from cookies...
    let authCookie = Cookies.get(clientId)
    if (authCookie) {
      let parsedCookie = JSON.parse(authCookie)
      if (parsedCookie.access_token) {
        this.authInfo = parsedCookie
        this.setAuthHeader()
      }
    }
  }

  login(): Promise<AuthInfoResponse> {
    return this.idpRequest(this.authEndpoint).then(hash => {
      console.log('Logged in...')
      this.authInfo = parseHash(hash)
      Cookies.set(this.clientId, JSON.stringify(this.authInfo))
      this.setAuthHeader()
      return this.authInfo
    })
  }

  logout(): void {
    let id_token = this.authInfo.id_token
    this.clear()

    if (this.endSessionEndpoint) {
      let logoutURL = this.endSessionEndpoint + '?id_token_hint=' + id_token + '&post_logout_redirect_uri=' + this.redirectUri
      this.idpRequest(logoutURL).then(_ => console.log('Logged out...'))  
    }
  }

  userInfo(): Promise<UserInfoResponse> {
    return get(this.userInfoEndpoint, 3000, { 'Authorization': this.authHeader })
  }

  private genNonce() {
    let text = ''
    let possible = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
    for( var i=0; i < 5; i++ )
      text += possible.charAt(Math.floor(Math.random() * possible.length))
    return text
  }

  private clear() {
    Cookies.remove(this.clientId)
    delete this.authHeader
    delete this.authInfo
  }

  private idpRequest(url: string) {
    let x = screen.width/2 - 700/2;
    let y = screen.height/2 - 450/2;

    return new Promise<string>((resolve, reject) => {
      console.log('IDP Request: ', url)
      let authWin = window.open(url, 'OAuth2', 'width=800, height=500, left=' + x + ',top=' + y)
      let intervalId = setInterval(_ => {
        if (!authWin) {
          clearInterval(intervalId)
          reject('Request not completed!')
        }

        try {
          if (authWin.location.hostname === window.location.hostname) {
            clearInterval(intervalId)
            let hash = authWin.location.hash
            authWin.close()
            resolve(hash)
          }
        } catch(error) {
          /*ignore error, this means that login/logout is not ready*/
        }
      })
    })
  }

  private setAuthHeader() {
    this.authHeader = this.authInfo.token_type + ' ' + this.authInfo.access_token
  }
}

export interface DiscoverResponse {
 issuer: string
 
 authorization_endpoint: string
 end_session_endpoint: string
 revocation_endpoint: string

 token_endpoint: string
 userinfo_endpoint: string
 
 jwks_uri: string
}

export interface AuthInfoResponse {
  access_token: string
  expires_in: string
  id_token: string
  token_type: string
}

export interface UserInfoResponse {
  email: string
  email_verified: boolean
  name: string
  picture: string
}

function get(url: string, timeout: number, headers?: {}): Promise<any> {
  return new Promise<any>((resolve, reject) => {
    let xhr = new XMLHttpRequest()
    xhr.ontimeout = _ => reject('Timeout error for request: ' + url)

    xhr.onloadend = _ => {
      if (xhr.readyState === 4) {
          if (xhr.status === 200)
            resolve(JSON.parse(xhr.response))
          else
            reject(xhr.statusText)
      }
    }
    
    xhr.open('GET', url, true)
    xhr.timeout = timeout

    if (headers)
      Object.keys(headers).forEach(key => xhr.setRequestHeader(key, headers[key]))
    
    xhr.send(null)
  })
}

function parseHash(hash: string) {
  let parts = hash.substring(1).split('&')
  let hashMap = {}
  parts.forEach(kv => {
    let tuple = kv.split('=')
    hashMap[tuple[0]] = tuple[1]
  })

  return hashMap as AuthInfoResponse
}