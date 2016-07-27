package rt.plugin.service.an

import java.lang.annotation.Target
import java.lang.annotation.Retention

@Target(METHOD)
@Retention(RUNTIME)
annotation Public {
	Class<?> retType = Void
	boolean notif = false
	boolean async = false
}