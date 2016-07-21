package rt.data

import java.lang.annotation.Target
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.AbstractClassProcessor
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.ClassDeclaration
import org.eclipse.xtend.lib.macro.RegisterGlobalsContext
import org.eclipse.xtend.lib.macro.declaration.FieldDeclaration
import org.eclipse.xtend.lib.macro.declaration.Visibility
import org.eclipse.xtext.xbase.lib.Procedures.Procedure1
import org.eclipse.xtend.lib.macro.ValidationContext

@Target(TYPE)
@Active(DataProcessor)
annotation Data {
	boolean metadata = false
}

class DataProcessor extends AbstractClassProcessor {
	val typeConversions = #{
		'boolean' -> Boolean,
		'int' -> Integer,
		'long' -> Long,
		'float' -> Float,
		'double' -> Double
	}
	
	override doValidate(ClassDeclaration clazz, extension ValidationContext context) {
		val variableFields = clazz.declaredFields.filter [ !final ]
		variableFields.forEach[
			addError('Variable fields not supported in Data!')
		]
	}
	
	override doRegisterGlobals(ClassDeclaration clazz, extension RegisterGlobalsContext context) {
		registerClass(clazz.qualifiedName + 'Builder')
	}
	
	override doTransform(MutableClassDeclaration clazz, extension TransformationContext context) {
		val allFields = clazz.declaredFields.filter [ !transient ]
		val mandatoryFields = allFields.filter [
			findAnnotation(Optional.findTypeGlobally) == null && findAnnotation(Default.findTypeGlobally) == null
		]
		
		//change builder class...
		val builderClassName = clazz.qualifiedName + 'Builder'
		val builderClazz = findClass(builderClassName)
		
		allFields.forEach[ field |
			val fTypeRef = context.convert(field)
			
			builderClazz.addField(field.simpleName)[
				type = fTypeRef
				visibility = Visibility.PUBLIC
				val defAno = field.findAnnotation(Default.findTypeGlobally)
				if (defAno != null)
					initializer = '''«defAno.getValue('value')»'''
			]
		]
		
		builderClazz.addConstructor[
			visibility = Visibility.DEFAULT
			body = ''''''
		]
		
		builderClazz.addMethod('operator_doubleArrow')[
			returnType = clazz.newTypeReference
			addParameter('block', Procedure1.newTypeReference(builderClazz.newTypeReference))
			body = '''
				block.apply(this);
				final «clazz.simpleName» data = new «clazz.simpleName»(this);
				data.validate();
				return data;
			'''
		]
		
		
		//change original class...
		allFields.forEach[ field |
			val fType = typeConversions.get(field.type.simpleName)
			val fTypeRef = fType?.newTypeReference ?: field.type
			
			field.markAsRead
			field.type = fTypeRef
			
			val getType = if (fType == Boolean) 'is' else 'get'
			clazz.addMethod(getType + field.simpleName.toFirstUpper)[
				returnType = fTypeRef
				body = '''
					return this.«field.simpleName»;
				'''
			]
		]
		
		clazz.addConstructor[
			val builderTypeRef = newTypeReference(builderClassName)
			addParameter('builder', builderTypeRef)
			body = '''
				«FOR field: allFields»
					this.«field.simpleName» = builder.«field.simpleName»;
				«ENDFOR»
			'''
		]
		
		val customValidations = clazz.declaredMethods.filter[
			findAnnotation(Validation.findTypeGlobally) != null && parameters.length == 0
		]
		
		clazz.addMethod('validate')[
			body ='''
				«FOR field: mandatoryFields»
					if («field.simpleName» == null)
						throw new «ValidationException.canonicalName»("Field :«field.simpleName» is mandatory!");
				«ENDFOR»
				«FOR vMethod: customValidations»
					«vMethod.simpleName»();
				«ENDFOR»
			'''
		]
		
		clazz.addMethod('B')[
			static = true
			returnType = builderClazz.newTypeReference
			body = '''
				return new «builderClassName»();
			'''
		]
		
		//this one only works when using static extension imports!
		clazz.addMethod('operator_doubleArrow') [
			static = true
			returnType = clazz.newTypeReference
			addParameter('left', Class.newTypeReference(clazz.newTypeReference))
			addParameter('block', Procedure1.newTypeReference(builderClazz.newTypeReference))
			body = '''
				final «builderClazz.simpleName» builder = new «builderClazz.simpleName»(); 
				block.apply(builder);
				final «clazz.simpleName» data = new «clazz.simpleName»(builder);
				data.validate();
				return data;
			'''
		]
	}
	
	def convert(extension TransformationContext context, FieldDeclaration field) {
		val fType = typeConversions.get(field.type.simpleName)
		return fType?.newTypeReference ?: field.type
	}
}