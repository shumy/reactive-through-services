package rt.plugin.service.an

import java.lang.annotation.Target
import java.lang.annotation.Repeatable

@Target(METHOD)
annotation Proxies {
	Proxy[] value
}

@Target(METHOD)
@Repeatable(Proxies)
annotation Proxy {
	String name
	Class<?> proxy
}