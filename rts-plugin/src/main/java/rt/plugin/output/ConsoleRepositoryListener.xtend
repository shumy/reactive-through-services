package rt.plugin.output

import org.eclipse.aether.RepositoryEvent
import org.eclipse.aether.AbstractRepositoryListener

class ConsoleRepositoryListener extends AbstractRepositoryListener {

	override void artifactDeployed(RepositoryEvent event) {
		println('''Deployed «event.artifact» to «event.repository»''')
	}

	override void artifactDescriptorInvalid(RepositoryEvent event) {
		println('''Invalid artifact descriptor for «event.artifact»: «event.exception.message»''')
	}

	override void artifactDescriptorMissing(RepositoryEvent event) {
		println('''Missing artifact descriptor for «event.artifact»''')
	}

	override void artifactInstalled(RepositoryEvent event) {
		println('''Installed «event.artifact» to «event.file»''')
	}

	override void artifactResolved(RepositoryEvent event) {
		println('''Resolved artifact «event.artifact» from «event.repository»''')
	}

	override void artifactDownloaded(RepositoryEvent event) {
		println('''Downloaded artifact «event.artifact» from «event.repository»''')
	}

	override void metadataDeployed(RepositoryEvent event) {
		println('''Deployed «event.metadata» to «event.repository»''')
	}

	override void metadataInstalled(RepositoryEvent event) {
		println('''Installed «event.metadata» to «event.file»''')
	}

	override void metadataInvalid(RepositoryEvent event) {
		println('''Invalid metadata «event.metadata»''')
	}

	override void metadataResolved(RepositoryEvent event) {
		println('''Resolved metadata «event.metadata» from «event.repository»''')
	}
}