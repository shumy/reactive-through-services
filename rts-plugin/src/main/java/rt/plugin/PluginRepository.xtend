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
import java.net.URL
import java.net.URLClassLoader
import rt.plugin.config.PluginConfigFactory

class PluginRepository {
	@Accessors val plugins = new PluginList(this)

	package val RepositorySystem system
	package val RemoteRepository centraRepository
	package val LocalRepository localRepository
	package val DefaultRepositorySystemSession session
	
	package val pluginConfigFactory = new PluginConfigFactory
	
	val String localPath
	val remoteRepoPath = 'http://central.maven.org/maven2/'
	
	//all registered files from resolve operation
	var isResolved = false
	val classPath = new HashMap<String, URL>
	
	var URLClassLoader urlClassLoader = null
	
	new(String localPath) {
		this.localPath = localPath
		
		val locator = MavenRepositorySystemUtils.newServiceLocator => [
			addService(RepositoryConnectorFactory, BasicRepositoryConnectorFactory)
			addService(TransporterFactory, FileTransporterFactory)
			addService(TransporterFactory, HttpTransporterFactory)
			errorHandler = new DefaultErrorHandler
		]
		
		system = locator.getService(RepositorySystem)
		
		centraRepository = new RemoteRepository.Builder('central', 'default', remoteRepoPath).build
		localRepository = new LocalRepository(localPath)
		
		session = MavenRepositorySystemUtils.newSession => [
			//transferListener = new ConsoleTransferListener
			//repositoryListener = new ConsoleRepositoryListener
			
			setConfigProperty(ConflictResolver.NODE_DATA_WINNER, true)
			setConfigProperty(DependencyManagerUtils.CONFIG_PROP_VERBOSE, true)
		]
		
		// needed after session create
		session.localRepositoryManager = system.newLocalRepositoryManager(session, localRepository)
	}
	
	def boolean resolve() {
		isResolved = true
		
		plugins.artifacts.values.forEach[
			resolve.forEach[
				val reference = '''«artifact.groupId»:«artifact.artifactId»:«artifact.version»'''
				classPath.put(reference, artifact.file.toURI.toURL)
				
				if (!resolved)
					throw new RuntimeException('''Unresolved artifact: «reference»''')
			]
		]

		println('''ClassPath (resolved=«isResolved», size=«classPath.keySet.size») «classPath.keySet»''')
		return isResolved
	}
	
	def Class<?> loadClass(String clazz) {
		if (!isResolved)
			throw new RuntimeException('ClassPath is not resolved, or something went wrong in the resolve process!')
		
		if (urlClassLoader == null) {
			var i = 0
			val URL[] urls = newArrayOfSize(classPath.size)
			for (url: classPath.values) {
				urls.set(i, url)
				i++
			}
			
			urlClassLoader = new URLClassLoader(urls, PluginRepository.classLoader)
		}
		
		return urlClassLoader.loadClass(clazz)
	}
	
	def instanceOf(String clazz) {
		try {
			return loadClass(clazz).newInstance
		} catch(Throwable ex) {
			ex.printStackTrace
			return null
		}
	}
	
	static class PluginList {
		val PluginRepository repo
		val artifacts = new HashMap<String, PluginArtifact>
		
		package new(PluginRepository repo) {
			this.repo = repo
		}
		
		def += (String reference) {
			addArtifact(reference)
		}
		
		def addArtifact(String reference) {
			val artifact = new PluginArtifact(repo, reference)
			artifacts.put(reference, artifact)
		
			return artifact
		}
		
		def getArtifacts() {
			return artifacts.values
		}
		
		def artifact(String reference) {
			return artifacts.get(reference)
		}
		
		override toString() {
			return artifacts.keySet.toString
		}
	}
}