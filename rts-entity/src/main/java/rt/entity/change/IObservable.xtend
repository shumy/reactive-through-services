package rt.entity.change

interface IObservable {
	def Publisher getPublisher()
	def String onChange((Change) => void listener)
	def void applyChange(Change change)
}