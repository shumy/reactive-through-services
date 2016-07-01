package rt.pipeline

import rt.pipeline.pipe.PipeContext

interface IComponent extends (PipeContext) => void {}