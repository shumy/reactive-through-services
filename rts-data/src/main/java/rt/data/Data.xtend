package rt.data

import com.google.common.collect.ImmutableList
import java.lang.annotation.Target
import java.util.List
import org.eclipse.xtend.lib.macro.AbstractClassProcessor
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.RegisterGlobalsContext
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.ValidationContext
import org.eclipse.xtend.lib.macro.declaration.ClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.FieldDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableFieldDeclaration
import org.eclipse.xtend.lib.macro.declaration.Visibility
import org.eclipse.xtext.xbase.lib.Procedures.Procedure1
import rt.data.schema.ISchema
import rt.data.schema.SProperty
import rt.data.schema.SType

@Target(TYPE)
@Active(DataProcessor)
annotation Data {
	boolean metadata = true
}

class DataProcessor extends AbstractClassProcessor {
	val typeConversions = #{
		'boolean' -> Boolean,
		'int' -> Integer,
		'long' -> Long,
		'float' -> Float,
		'double' -> Double
	}
	
	override doValidate(ClassDeclaration clazz, extension ValidationContext ctx) {
		clazz.declaredFields.forEach[
			if (!final)
				addError('Variable fields not supported in data types!')
		]
		
		clazz.declaredMethods.forEach[
			if (findAnnotation(Validation.findTypeGlobally) != null && parameters.length != 0)
				addError('Validation methods can not have parameters!')
		]
	}
	
	override doRegisterGlobals(ClassDeclaration clazz, extension RegisterGlobalsContext ctx) {
		registerClass(clazz.qualifiedName + 'Builder')
	}
	
	override doTransform(MutableClassDeclaration clazz, extension TransformationContext ctx) {
		val allFields = clazz.declaredFields.filter[ !(transient || static) ].toList
		val mandatoryFields = allFields.filter[
			findAnnotation(Optional.findTypeGlobally) == null && findAnnotation(Default.findTypeGlobally) == null
		]
		
		//change builder class...
		val builderClassName = clazz.qualifiedName + 'Builder'
		val builderClazz = findClass(builderClassName)
		
		allFields.forEach[ field |
			val fTypeRef = ctx.convert(field)
			
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
		clazz.extendedClass = IData.newTypeReference
		
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
		
		clazz.addMethod('get')[
			returnType = object
			addParameter('field', string)
			body = '''
				«FOR field: allFields»
					if (field.equals("«field.simpleName»")) return this.«field.simpleName»;
				«ENDFOR»

				throw new RuntimeException("No field '" + field + "' for «clazz.qualifiedName»");
			'''
		]
		
		val customValidations = clazz.declaredMethods.filter[ findAnnotation(Validation.findTypeGlobally) != null ]
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
		
		val anno = clazz.findAnnotation(Data.findTypeGlobally)
		if (anno.getBooleanValue('metadata'))
			clazz.generateMetadata(allFields, ctx)
	}
	
	def convert(extension TransformationContext context, FieldDeclaration field) {
		val fType = typeConversions.get(field.type.simpleName)
		return fType?.newTypeReference ?: field.type
	}
	
	def void generateMetadata(MutableClassDeclaration clazz, List<? extends MutableFieldDeclaration> fields, extension TransformationContext context) {
		clazz.extendedClass = ISchema.newTypeReference
		
		clazz.addField('properties')[
			visibility = Visibility.PUBLIC
			transient = true
			static = true
			final = true
			type = List.newTypeReference(SProperty.newTypeReference)
			initializer = '''«ImmutableList».copyOf(new SProperty[] {
				«FOR prop: fields SEPARATOR ','»
					«context.propertyInitializer(prop)»
				«ENDFOR»
			})'''
		]
		
		clazz.addMethod('getProperties')[
			returnType = List.newTypeReference(SProperty.newTypeReference)
			body = '''
				return properties;
			'''
		]
	}
	
	def propertyInitializer(extension TransformationContext ctx, MutableFieldDeclaration prop) {
		val isOptional = prop.findAnnotation(Optional.findTypeGlobally) != null
		val defaultValue = prop.findAnnotation(Default.findTypeGlobally)?.getStringValue('value')

		return '''
			new SProperty("«prop.simpleName»", «SType.canonicalName».convertFromJava("«ctx.convert(prop)»"), «isOptional», «IF defaultValue != null»«defaultValue»«ELSE»null«ENDIF»)
		'''
	}
}