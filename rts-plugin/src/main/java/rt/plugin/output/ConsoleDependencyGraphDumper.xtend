package rt.plugin.output

import org.eclipse.aether.graph.DependencyVisitor
import java.util.ArrayList
import org.eclipse.aether.graph.DependencyNode
import org.eclipse.aether.util.graph.manager.DependencyManagerUtils
import org.eclipse.aether.util.graph.transformer.ConflictResolver
import org.eclipse.aether.util.artifact.ArtifactIdUtils

class ConsoleDependencyGraphDumper implements DependencyVisitor {
	val childInfos = new ArrayList<ChildInfo>

	override def visitEnter(DependencyNode node) {
		println(formatIndentation + formatNode(node))
		childInfos.add(new ChildInfo(node.children.size))
		return true
	}
	
	override def visitLeave(DependencyNode node) {
		if (!childInfos.isEmpty) {
			childInfos.remove(childInfos.size() - 1)
		}
		
		if (!childInfos.isEmpty) {
			childInfos.get(childInfos.size - 1).index++
		}
		
		return true
	}

	private def formatIndentation() {
		val buffer = new StringBuilder(128)
		for (val iter = childInfos.iterator; iter.hasNext;) {
			buffer.append(iter.next.formatIndentation(!iter.hasNext))
		}
		return buffer.toString
	}

	private def formatNode(DependencyNode node) {
		val buffer = new StringBuilder(128)
		val a = node.artifact
		val d = node.dependency
		
		buffer.append(a)
		if (d != null && d.scope.length > 0) {
			buffer.append(' [').append(d.scope)
			if (d.isOptional) {
				buffer.append(', optional')
			}
			buffer.append(']')
		}
		
		{
			val premanaged = DependencyManagerUtils.getPremanagedVersion(node)
			if (premanaged != null && !premanaged.equals(a.baseVersion)) {
				buffer.append(' (version managed from ').append(premanaged).append(')')
			}
		}
		
		{
			val premanaged = DependencyManagerUtils.getPremanagedScope(node)
			if (premanaged != null && !premanaged.equals(d.scope)) {
				buffer.append(' (scope managed from ').append(premanaged).append(')')
			}
		}
		
		val winner = node.data.get(ConflictResolver.NODE_DATA_WINNER) as DependencyNode
		if (winner != null && !ArtifactIdUtils.equalsId(a, winner.artifact)) {
			val w = winner.artifact
			buffer.append(' (conflicts with ')
			if (ArtifactIdUtils.toVersionlessId(a).equals(ArtifactIdUtils.toVersionlessId(w))) {
				buffer.append(w.version)
			} else {
				buffer.append(w)
			}
			buffer.append(')')
		}
		
		return buffer.toString
	}

	private static class ChildInfo {
		val int count
		int index

		new(int count) {
			this.count = count
		}

		def formatIndentation(boolean end) {
			val last = index + 1 >= count
			if (end) {
				return if (last) '\\- ' else '+- '
			}
			
			return if (last) '   ' else '|  '
		}

	}
}