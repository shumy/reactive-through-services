package rt.data.schema

class SType {
	public val String typ
	public val String fGen
	public val String sGen
	
	new(String typ) { this(typ, null, null) }
	new(String typ, String fGen) { this(typ, fGen, null) }
	new(String typ, String fGen, String sGen) {
		this.typ = typ
		this.fGen = fGen
		this.sGen = sGen
	}
	
	static def convertFromJava(String fromJava) {
		val nat = getNative(fromJava)
		if (nat == 'lst' || nat == 'set' || nat == 'map') {
			val splits = fromJava.split('<')
			if (splits.length != 2)
				throw new RuntimeException('Collections not supported with deep generic types!')
			
			val genericTypes = splits.get(1).substring(0, splits.get(1).length - 1)
			if (nat == 'map') {
				val gSplits = genericTypes.split(',')
				val firstGeneric = getNative(gSplits.get(0))
				val secondGeneric = getNative(gSplits.get(1))
				return new SType(nat, firstGeneric, secondGeneric)
			}
			
			val firstGeneric = getNative(genericTypes)
			return new SType(nat, firstGeneric)
		}
		
		return new SType(nat)
	}
	
	private static def getNative(String inType) {
		val type = inType.replaceAll('\\s+','')
		
		switch type {
			case 'String': 		'txt'
			case 'Boolean': 	'bol'
			case 'Integer': 	'int'
			case 'Long': 		'lng'
			case 'Float': 		'flt'
			case 'Double': 		'dbl'
			//TODO: cases for dates ?
			
			default: {
				if (type.startsWith('List')) return 	'lst'
				if (type.startsWith('Set')) return 		'set'
				if (type.startsWith('Map')) return 		'map'
				
				return type
			}
		}
	} 
}