package rt.async

interface IAsyncError {
	def void error((Throwable) => void onError)
}