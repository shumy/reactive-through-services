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

class PluginArtifact {
	@Accessors val String reference
	
	val PluginRepository repo
	val ArtifactDescriptorRequest descriptorRequest
	
	new(PluginRepository repo, String reference) {
		this.repo = repo
		this.reference = reference
		
		descriptorRequest = new ArtifactDescriptorRequest => [
			artifact = new DefaultArtifact(reference)
			repositories = #[repo.centraRepository]
		]
	}
	
	/*def void collect() {
		val descriptorResult = repo.system.readArtifactDescriptor(repo.session, descriptorRequest)
		
		val collectRequest = new CollectRequest => [
			rootArtifact = descriptorResult.artifact
			dependencies = descriptorResult.dependencies
			managedDependencies = descriptorResult.managedDependencies
			repositories = descriptorRequest.repositories
		]
		
		val result = repo.system.collectDependencies(repo.session, collectRequest)
		result.root.accept(new ConsoleDependencyGraphDumper)
	}*/
	
	def void resolve() {
		val classpathFilter = DependencyFilterUtils.classpathFilter(JavaScopes.COMPILE)
		
		val collectRequest = new CollectRequest => [
			root = new Dependency(descriptorRequest.artifact, JavaScopes.COMPILE)
			repositories = descriptorRequest.repositories
		]
		
		val dependencyRequest = new DependencyRequest(collectRequest, classpathFilter)
		
		val result = repo.system.resolveDependencies(repo.session, dependencyRequest)
		result.root.accept(new ConsoleDependencyGraphDumper)
	}
}