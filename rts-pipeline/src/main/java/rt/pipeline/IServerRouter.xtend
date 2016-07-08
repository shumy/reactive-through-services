package rt.pipeline

import rt.pipeline.pipe.PipeResource

interface IServerRouter {
	def void onResourceOpen((PipeResource) => void callback)
	def void onResourceClose((String) => void callback)
}