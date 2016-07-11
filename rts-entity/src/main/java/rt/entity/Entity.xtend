package rt.entity

import java.lang.annotation.Target
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.AbstractClassProcessor
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.TransformationContext
import java.util.List
import java.util.ArrayList
import rt.entity.change.IObservable
import rt.entity.change.Change
import rt.entity.change.ChangeType
import rt.entity.sync.EntitySync
import java.util.Map

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
		clazz.extendedClass = EntitySync.newTypeReference
		
		addFieldMethods(clazz, ctx)
	}
	
	def void addFieldMethods(MutableClassDeclaration clazz, extension TransformationContext ctx) {
		val allFields = clazz.declaredFields.filter [ !static && !transient ]
		val variableFields = allFields.filter[ !final ]
		
		//convert primitives to boxed fields...
		allFields.forEach[
			val fType = typeConversions.get(type.simpleName)
			val fTypeRef = fType?.newTypeReference ?: type
			type = fTypeRef
		]
		
		//validate some constraints
		/*observedFields.forEach[
			if (initializer != null)
				addError('You need to initialize the field in the constructor')
		]*/
		
		clazz.addMethod('getFields') [
			returnType = List.newTypeReference(string)
			body = '''
				final List<String> fields = new «ArrayList.name»<>(«allFields.size»);
				«FOR field: allFields»
					fields.add("«field.simpleName»");
				«ENDFOR»
				return fields;
			'''
		]
		
		clazz.addMethod('getValue') [
			returnType = object
			addParameter('field', string)
			body = '''
				«FOR field: allFields»
					if (field.equals("«field.simpleName»")) return this.«field.simpleName»;
				«ENDFOR»

				throw new RuntimeException("No field '" + field + "' for «clazz.qualifiedName»");
			'''
		]
		
		clazz.addMethod('setValue') [
			addParameter('field', string)
			addParameter('value', object)
			body = '''
				if(value == null)
					throw new RuntimeException("Trying to set null value on field '" + field + "' in «clazz.qualifiedName»");

				«FOR field: variableFields»
					if (field.equals("«field.simpleName»")) { this.set«field.simpleName.toFirstUpper»( («field.type»)value ); return; }
				«ENDFOR»

				throw new RuntimeException("No field '" + field + "' for «clazz.qualifiedName»");
			'''
		]
		
		for(field: allFields) {
			field.markAsRead
			val fType = typeConversions.get(field.type.simpleName)
			val fTypeRef = fType?.newTypeReference ?: field.type
			
			val getType = if (fType == Boolean) 'is' else 'get'			
			clazz.addMethod(getType + field.simpleName.toFirstUpper)[
				returnType = fTypeRef
				body = '''
					return this.«field.simpleName»;
				'''
			]
			
			if (List.newTypeReference.isAssignableFrom(fTypeRef)) {
				field.initializer = '''newList("«field.simpleName»")'''
			} else if (Map.newTypeReference.isAssignableFrom(fTypeRef)) {
				field.initializer = '''newMap("«field.simpleName»")'''
			}
		}
		
		for(field: variableFields) {
			val fType = typeConversions.get(field.type.simpleName)
			val fTypeRef = fType?.newTypeReference ?: field.type
			
			clazz.addMethod('set' + field.simpleName.toFirstUpper)[
				addParameter('value', fTypeRef)
				body = '''
					«IF field.findAnnotation(Ignore.findTypeGlobally) == null»
						«IF IObservable.newTypeReference.isAssignableFrom(fTypeRef)»
							unobserve("«field.simpleName»", this.«field.simpleName»);
							observe("«field.simpleName»", value);
							
						«ENDIF»
						final «Change.name» change = new «Change.name»(«ChangeType.name».UPDATE, value, "«field.simpleName»");
						publish(change);
					«ENDIF»
					this.«field.simpleName» = value;
				'''
			]
		}
	}
}