package rt.plugin.config

import javax.xml.bind.annotation.XmlRootElement
import javax.xml.bind.annotation.XmlAttribute
import javax.xml.bind.annotation.XmlElement

@XmlRootElement(name='entry')
class PluginEntry {
	@XmlAttribute(required=true) public String type
	@XmlAttribute(required=true) public String ref
	
	@XmlElement public String name
	
	def copyFrom(PluginEntry entry) {
		type = entry.type
		ref = entry.ref
		name = entry.name
	}
}