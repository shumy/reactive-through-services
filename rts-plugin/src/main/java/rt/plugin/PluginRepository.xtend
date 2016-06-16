package rt.plugin

import org.eclipse.aether.RepositorySystem
import org.apache.maven.repository.internal.MavenRepositorySystemUtils
import org.eclipse.aether.connector.basic.BasicRepositoryConnectorFactory
import org.eclipse.aether.spi.connector.RepositoryConnectorFactory
import org.eclipse.aether.transport.file.FileTransporterFactory
import org.eclipse.aether.transport.http.HttpTransporterFactory
import org.eclipse.aether.spi.connector.transport.TransporterFactory
import rt.plugin.output.DefaultErrorHandler
import org.eclipse.aether.repository.LocalRepository
import rt.plugin.output.ConsoleTransferListener
import rt.plugin.output.ConsoleRepositoryListener
import org.eclipse.aether.util.graph.transformer.ConflictResolver
import org.eclipse.aether.DefaultRepositorySystemSession
import org.eclipse.aether.util.graph.manager.DependencyManagerUtils
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.aether.repository.RemoteRepository
import java.util.HashMap

class PluginRepository {
	@Accessors(PACKAGE_GETTER) val RepositorySystem system
	@Accessors(PACKAGE_GETTER) val RemoteRepository centraRepository
	@Accessors(PACKAGE_GETTER) val DefaultRepositorySystemSession session
	
	@Accessors val plugins = new PluginList(this)
	
	val String localPath
	val remotePath = 'http://central.maven.org/maven2/'
	
	new(String localPath) {
		this.localPath = localPath

		val localRepo = new LocalRepository(localPath)
		
		val locator = MavenRepositorySystemUtils.newServiceLocator => [
			addService(RepositoryConnectorFactory, BasicRepositoryConnectorFactory)
			addService(TransporterFactory, FileTransporterFactory)
			addService(TransporterFactory, HttpTransporterFactory)
			errorHandler = new DefaultErrorHandler
		]
		
		system = locator.getService(RepositorySystem)
		
		centraRepository = new RemoteRepository.Builder('central', 'default', remotePath).build
		
		session = MavenRepositorySystemUtils.newSession => [
			transferListener = new ConsoleTransferListener
			repositoryListener = new ConsoleRepositoryListener
			
			setConfigProperty(ConflictResolver.CONFIG_PROP_VERBOSE, true)
			setConfigProperty(DependencyManagerUtils.CONFIG_PROP_VERBOSE, true)
		]
		
		// needed after session create
		session.localRepositoryManager = system.newLocalRepositoryManager(session, localRepo)
	}
	
	def void resolve() {
		plugins.plugins.forEach[ key, plugin | plugin.resolve ]
	}
	
	static class PluginList {
		val PluginRepository repo
		val plugins = new HashMap<String, PluginArtifact>
		
		new(PluginRepository repo) {
			this.repo = repo
		}
		
		def addPlugin(String reference) {
			val artifact = new PluginArtifact(repo, reference)
			plugins.put(reference, artifact)
		
			return artifact
		}
		
		def getPlugin(String reference) {
			return plugins.get(reference)
		}
		
		def += (String reference) {
			addPlugin(reference)
		} 
	}
}