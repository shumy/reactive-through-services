package rt.plugin.config

import javax.xml.bind.annotation.XmlRootElement
import javax.xml.bind.annotation.XmlAttribute
import javax.xml.bind.annotation.XmlElement

@XmlRootElement(name='entry')
class PluginEntry {
	@XmlAttribute public String type
	@XmlAttribute public String ref
	
	@XmlElement public String name
}