package rt.plugin.service.an

import java.lang.annotation.Target
import java.lang.annotation.Repeatable

@Target(METHOD)
annotation Contexts {
	Context[] value
}

@Target(METHOD)
@Repeatable(Contexts)
annotation Context {
	String name
	Class<?> type
}