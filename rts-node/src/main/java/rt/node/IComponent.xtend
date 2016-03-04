package rt.node

import rt.node.pipeline.PipeContext

interface IComponent extends (PipeContext) => void {
	def String getName()
}