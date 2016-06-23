package rt.entity.change

import java.util.ArrayList

enum ChangeType {
	ADD, UPDATE, REMOVE, CLEAR
}

class Change {
	public static val PATH_SEPARATOR = '.'
	
	public var ChangeType type
	public var Object newValue
	public var Object oldValue
	
	public val path = new ArrayList<String>
	
	new(){}
	new(ChangeType type, Object newValue, String path) {
		this.type = type
		this.newValue = newValue
		this.path.add(path)
	}
}