package rt.plugin.config

import javax.xml.bind.JAXBContext
import javax.xml.bind.Marshaller
import javax.xml.bind.Unmarshaller
import java.io.InputStream
import java.io.OutputStream
import java.io.StringWriter

class PluginConfigFactory {
	val JAXBContext jaxbContext
	val Marshaller jaxbWriter
	val Unmarshaller jaxbReader
	
	new() {
		jaxbContext = JAXBContext.newInstance(PluginConfig)
		
		jaxbWriter = jaxbContext.createMarshaller => [
			setProperty(Marshaller.JAXB_FORMATTED_OUTPUT, true)
		]
		
		jaxbReader = jaxbContext.createUnmarshaller
	}
	
	def readFrom(InputStream is) {
		return jaxbReader.unmarshal(is) as PluginConfig
	}
	
	def writeTo(PluginConfig config, OutputStream os) {	
		jaxbWriter.marshal(config, os)
	}
	
	def transform(PluginConfig config) {
		val writer = new StringWriter
		jaxbWriter.marshal(config, writer)
		
		return writer.toString
	}
}