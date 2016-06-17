package rt.plugin

import org.eclipse.aether.artifact.DefaultArtifact
import org.eclipse.aether.resolution.ArtifactDescriptorRequest
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.aether.collection.CollectRequest
import org.eclipse.aether.resolution.DependencyRequest
import org.eclipse.aether.util.filter.DependencyFilterUtils
import org.eclipse.aether.util.artifact.JavaScopes
import org.eclipse.aether.graph.Dependency
import org.eclipse.aether.graph.DependencyFilter
import org.eclipse.aether.resolution.DependencyResult
import rt.plugin.config.PluginConfig
import org.eclipse.aether.resolution.ArtifactResult
import java.util.List
import java.util.zip.ZipFile

class PluginArtifact {
	@Accessors val String reference
	@Accessors(PUBLIC_GETTER) var PluginConfig config
	
	val PluginRepository repo
	
	val DependencyFilter filterRequest
	val ArtifactDescriptorRequest descriptorRequest
	val CollectRequest collectRequest
	val DependencyRequest dependencyRequest
	
	var DependencyResult result = null
	
	package new(PluginRepository repo, String reference) {
		this.repo = repo
		this.reference = reference
		
		filterRequest = DependencyFilterUtils.classpathFilter(JavaScopes.COMPILE)
		
		descriptorRequest = new ArtifactDescriptorRequest => [
			artifact = new DefaultArtifact(reference)
			repositories = #[repo.centraRepository]
		]
		
		collectRequest = new CollectRequest => [
			root = new Dependency(descriptorRequest.artifact, JavaScopes.COMPILE)
			repositories = descriptorRequest.repositories
		]
		
		dependencyRequest = new DependencyRequest(collectRequest, filterRequest)
	}
	
	def List<ArtifactResult> resolve() {
		result = repo.system.resolveDependencies(repo.session, dependencyRequest)
		//result.root.accept(new ConsoleDependencyGraphDumper)
		
		val artifacts = result.artifactResults
		if (!artifacts.empty)
			config = readConfig(artifacts.get(0))
		
		return artifacts
	}
	
	def findEntry(String type, String name) {
		if (config == null)
			throw new RuntimeException('''Not resolved plugin-config.xml in artifact: «reference»''')
		
		val entry = config.findEntry(type, name)
		if (entry == null)
			throw new RuntimeException('''No entry found («type», «name») in artifact: «reference»''')
		
		return entry
	}
	
	def <T> T newInstanceFromEntry(Class<T> clazz, String type, String className) {
		val entry = findEntry(type, className)
		return repo.instanceOf(entry.ref) as T
	}
	
	override toString() { return reference }
	
	private def PluginConfig readConfig(ArtifactResult pluginRef) {
		if (pluginRef.resolved) {
			val jarFile = new ZipFile(pluginRef.artifact.file.path)
			val entries = jarFile.entries

			while (entries.hasMoreElements) {
				val entry = entries.nextElement
				if (entry.name == 'plugin-config.xml') {
					val is = jarFile.getInputStream(entry)
					val config = repo.pluginConfigFactory.readFrom(is)
					
					//println(repo.pluginConfigFactory.transform(config))
					return config
				}
			}
		}
		
		return null
	}
}