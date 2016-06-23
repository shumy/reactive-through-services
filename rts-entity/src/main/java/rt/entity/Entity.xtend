package rt.entity

import java.lang.annotation.Target
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.AbstractClassProcessor
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.TransformationContext
import rt.entity.sync.SyncEntity
import java.util.List
import java.util.ArrayList
import rt.entity.change.IObservable
import rt.entity.change.Change
import rt.entity.change.ChangeType

@Target(TYPE)
@Active(EntityProcessor)
annotation Entity {	
}

class EntityProcessor extends AbstractClassProcessor {
	val typeConversions = #{
		'boolean' -> Boolean,
		'int' -> Integer,
		'long' -> Long,
		'float' -> Float,
		'double' -> Double
	}
	
	override doTransform(MutableClassDeclaration clazz, extension TransformationContext ctx) {
		clazz.extendedClass = SyncEntity.newTypeReference
		
		addFieldMethods(clazz, ctx)
	}
	
	def void addFieldMethods(MutableClassDeclaration clazz, extension TransformationContext ctx) {		
		val observedFields = clazz.declaredFields.filter [ !static && !transient && !final ]
		
		//validate some constraints
		observedFields.forEach[
			if (initializer != null)
				addError('You need to initialize the field in the constructor')
		]

		
		clazz.addMethod('getFields') [
			returnType = List.newTypeReference(string)
			body = ['''
				final List<String> fields = new «ArrayList.name»<>(«observedFields.size»);
				«FOR field: observedFields»
					fields.add("«field.simpleName»");
				«ENDFOR»
				return fields;
			''']
		]
		
		clazz.addMethod('getValue') [
			returnType = object
			addParameter('field', string)
			body = ['''
				«FOR field: observedFields»
					if (field.equals("«field.simpleName»")) return this.«field.simpleName»;
				«ENDFOR»

				throw new RuntimeException("No field '" + field + "' for «clazz.qualifiedName»");
			''']
		]
		
		clazz.addMethod('setValue') [
			addParameter('field', string)
			addParameter('value', object)
			body = ['''
				if(value == null)
					throw new RuntimeException("Trying to set null value on field '" + field + "' in «clazz.qualifiedName»");

				«FOR field: observedFields»
					if (field.equals("«field.simpleName»")) { this.set«field.simpleName.toFirstUpper»( («field.type»)value ); return; }
				«ENDFOR»

				throw new RuntimeException("No field '" + field + "' for «clazz.qualifiedName»");
			''']
		]
		
		for(field: observedFields) {
			val fType = typeConversions.get(field.type.simpleName)?.newTypeReference ?: field.type
						
			clazz.addMethod('get' + field.simpleName.toFirstUpper)[
				returnType = fType
				body = ['''
					return this.«field.simpleName»;
				''']
			]
			
			clazz.addMethod('set' + field.simpleName.toFirstUpper)[
				addParameter('value', fType)
				body = ['''
					final «Change.name» change = new «Change.name»(«ChangeType.name».UPDATE, value, "«field.simpleName»");
					publisher.publish(change);
					«IF IObservable.newTypeReference.isAssignableFrom(fType)»
						observe("«field.simpleName»", («IObservable.name»)value);
					«ENDIF»
					
					this.«field.simpleName» = value;
				''']
			]
		}
	}
}