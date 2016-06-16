package rt.plugin

import org.eclipse.aether.artifact.DefaultArtifact
import org.eclipse.aether.resolution.ArtifactDescriptorRequest
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.aether.collection.CollectRequest
import rt.plugin.output.ConsoleDependencyGraphDumper
import org.eclipse.aether.resolution.DependencyRequest
import org.eclipse.aether.util.filter.DependencyFilterUtils
import org.eclipse.aether.util.artifact.JavaScopes
import org.eclipse.aether.graph.Dependency
import org.eclipse.aether.graph.DependencyFilter
import org.eclipse.aether.resolution.DependencyResult

class PluginArtifact {
	@Accessors val String reference
	
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
	
	def resolve() {
		result = repo.system.resolveDependencies(repo.session, dependencyRequest)
		result.root.accept(new ConsoleDependencyGraphDumper)
		
		return result.artifactResults
	}
}