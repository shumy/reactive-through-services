package rt.plugin.config

import javax.xml.bind.annotation.XmlElement
import javax.xml.bind.annotation.XmlRootElement
import javax.xml.bind.annotation.XmlElementWrapper
import java.util.List
import java.util.ArrayList

@XmlRootElement(name='config')
class PluginConfig {
	
	@XmlElementWrapper(name='entries')
	@XmlElement(name='entry')
	public List<PluginEntry> entries = new ArrayList
	
	def findOrCreateEntry(String type, String ref) {
		var entry = findEntry(type, ref)
		if (entry == null) {
			entry = new PluginEntry
			entries.add(entry)
		}
		
		return entry
	}
	
	def findEntry(String type, String ref) {
		for (entry: entries) {
			if (entry.type == type && entry.ref == ref)
				return entry
		}
		
		return null
	}
}