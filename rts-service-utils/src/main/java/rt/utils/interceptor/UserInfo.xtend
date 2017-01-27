package rt.utils.interceptor

import java.util.Set
import java.util.List

class UserInfo {
	public val String name
	public val Set<String> groups
	
	new(String name, List<String> groups) {
		this.name = name
		this.groups = groups.toSet
	}
}