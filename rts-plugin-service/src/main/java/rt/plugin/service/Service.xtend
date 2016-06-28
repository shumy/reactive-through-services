package rt.plugin.service

import java.lang.annotation.Target
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.AbstractClassProcessor
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.MutableMethodDeclaration
import org.eclipse.xtend.lib.macro.declaration.TypeReference
import org.eclipse.xtend.lib.macro.declaration.ClassDeclaration
import org.eclipse.xtend.lib.macro.CodeGenerationContext
import rt.plugin.config.PluginConfig
import rt.plugin.config.PluginConfigFactory
import rt.plugin.config.PluginEntry
import java.util.List
import rt.pipeline.IComponent
import rt.pipeline.pipe.PipeContext
import rt.pipeline.IMessageBus.Message

@Target(TYPE)
@Active(ServiceProcessor)
annotation Service {
	String value
}

class ServiceProcessor extends AbstractClassProcessor {

	override doTransform(MutableClassDeclaration clazz, extension TransformationContext ctx) {
		val anno = clazz.findAnnotation(Service.findTypeGlobally)
		val name = anno.getStringValue('value')
		
		clazz.extendedClass = IComponent.newTypeReference
		
		clazz.addField('ctx')[
			type = PipeContext.newTypeReference
		]
		
		clazz.addMethod('getName')[
			returnType = String.newTypeReference
			body = '''
				return "srv:«name»";
			'''
		]
		
		clazz.addMethod('apply')[
			addParameter('ctx', PipeContext.newTypeReference)
			
			body = '''
				this.ctx = ctx; 
				
				final «Message» msg = ctx.getMessage();
				«List»<Object> args = null;
				Object ret = null;
				
				switch(msg.cmd) {
					«FOR meth : clazz.declaredMethods»
						«IF meth.findAnnotation(Public.findTypeGlobally) != null»
							«meth.addCase»
						«ENDIF»
					«ENDFOR»
					default:
						ctx.replyError("No public method: " + msg.cmd);
						break;
				}
			'''
		]
	}
	
	override doGenerateCode(ClassDeclaration clazz, @Extension CodeGenerationContext context) {
		val anno = clazz.findAnnotation(Service.findTypeGlobally)
		val serviceName = anno.getStringValue('value')
		
		val filePath = clazz.compilationUnit.filePath
		val file = filePath.projectFolder.append('/src/main/resources/plugin-config.xml')
		val factory = new PluginConfigFactory
		
		// read plugin-config.xml
		val config = if (file.exists) factory.readFrom(file.contentsAsStream) else new PluginConfig
		config.cleanVoidEntries
		
		// change config
		config.addEntry(new PluginEntry => [
			type = 'srv'
			ref = clazz.qualifiedName
			name = serviceName
		])
		
		// write plugin-config.xml
		file.contents = factory.transform(config)
	}
	
	def addCase(MutableMethodDeclaration meth) {
		val retType = meth.returnType.simpleName

		var i = 0
		return '''
			case "«meth.simpleName»":
				«IF meth.parameters.size != 0»
				args = msg.args(«FOR param : meth.parameters SEPARATOR ','» «param.type.simpleName.replaceFirst('<.*>', '')».class«ENDFOR» );
				«ENDIF»
				«IF retType != 'void'»ret = «ENDIF»«meth.simpleName»(«FOR param : meth.parameters SEPARATOR ','» «param.type.addArgType(i++)»«ENDFOR» );
				«IF retType != 'void'»
					ctx.replyOK(ret);
				«ELSE»
					ctx.replyOK();
				«ENDIF»
				break;
		'''
	}
	
	def addArgType(TypeReference type, int index) {
		return '''(«type»)args.get(«index»)'''
	}
}