package rt.pipeline

class PathValidator {
	static def isValid(String path) {
		return !(path.contains('..') || path.contains('~'))
	}
}