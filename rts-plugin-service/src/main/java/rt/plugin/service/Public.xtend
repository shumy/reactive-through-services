package rt.plugin.service

import java.lang.annotation.Target
import java.lang.annotation.Retention

@Target(METHOD)
@Retention(RUNTIME)
annotation Public {
	Class<?> retType = Void
}