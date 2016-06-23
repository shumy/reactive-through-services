package rt.entity.change

interface IObservable {
	def void onChange((Change) => void listener)
}