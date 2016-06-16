package rt.node.annotation

import java.lang.annotation.Target
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.AbstractClassProcessor
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.TransformationContext
import rt.node.IComponent
import rt.node.pipeline.PipeContext
import rt.node.pipeline.PipeMessage
import org.eclipse.xtend.lib.macro.declaration.MutableMethodDeclaration
import io.vertx.core.json.JsonArray
import io.vertx.core.json.JsonObject
import org.eclipse.xtend.lib.macro.declaration.TypeReference
import java.util.List
import org.eclipse.xtend.lib.macro.declaration.ClassDeclaration
import org.eclipse.xtend.lib.macro.CodeGenerationContext

@Target(TYPE)
@Active(ServiceProcessor)
annotation Service {
	String value
}

class ServiceProcessor extends AbstractClassProcessor {
	override doTransform(MutableClassDeclaration clazz, extension TransformationContext ctx) {
		val anno = clazz.findAnnotation(Service.findTypeGlobally)
		val name = anno.getStringValue("value")
		
		clazz.extendedClass = ctx.newTypeReference(IComponent)
		
		clazz.addMethod("getName")[
			returnType = ctx.newTypeReference(String)
			body = '''
				return "srv:«name»";
			'''
		]
		
		
		clazz.declaredMethods.forEach[
			println(it.simpleName)
		]
		
		clazz.addMethod("apply")[
			addParameter("ctx", ctx.newTypeReference(PipeContext))
			
			body = '''
				final «PipeMessage» msg = ctx.getMessage();
				final «String» cmd = msg.getCmd();
				final «JsonArray» args = msg.getArgs();
				final «JsonObject» ret = new «JsonObject»();
				
				switch(cmd) {
					«FOR meth : clazz.declaredMethods»
						«IF meth.findAnnotation(Public.findTypeGlobally) != null»
							«meth.addCase»
						«ENDIF»
					«ENDFOR»
					default:
						ctx.replyError("No public method: " + cmd);
						break;
				}
			'''
		]
	}
	
	/*
	override doGenerateCode(List<? extends ClassDeclaration> annotatedSourceElements, @Extension CodeGenerationContext context) {
		val filePath = annotatedSourceElements.get(0).compilationUnit.filePath
		val file = filePath.projectFolder.append('/src/main/resources/plugin.properties')

		file.contents = '''
			«FOR clazz: annotatedSourceElements»
				«clazz.qualifiedName»
					«FOR method: clazz.declaredMethods»
						«method.simpleName»
					«ENDFOR»
			«ENDFOR»
		'''
	}
	
	override doGenerateCode(ClassDeclaration clazz, @Extension CodeGenerationContext context) {
		val filePath = clazz.compilationUnit.filePath
		val file = filePath.projectFolder.append('/src/main/resources/' + clazz.simpleName + '.properties')
		
		file.contents = '''
			«FOR method : clazz.declaredMethods»
				«method.simpleName»
			«ENDFOR»
      	'''
	}
	*/
	
	def addCase(MutableMethodDeclaration meth) {
		val retType = meth.returnType.simpleName.replaceFirst('<.*>', '')

		//TODO: add support for non native types
		var i = 0
		return '''
			case "«meth.simpleName»":
				«IF retType != "void"»final «meth.returnType» «meth.simpleName»Value = «ENDIF»«meth.simpleName»(«FOR param : meth.parameters SEPARATOR ','» «param.type.addArgType(i++)»«ENDFOR» );
				«IF retType != "void"»
				ret.put("type", "«retType.toFirstLower»");
				ret.put("value", «meth.simpleName»Value);
				ctx.replyOK(ret);
				«ENDIF»
				break;
		'''
	}
	
	def addArgType(TypeReference type, int index) {
		val simpleType = type.simpleName.replaceFirst('<.*>', '').toFirstUpper
		
		switch simpleType {
			case 'Int': return '''args.getInteger(«index»)'''
			case 'Map': return '''args.getJsonObject(«index»).getMap()'''
			default:
				return '''args.get«simpleType»(«index»)'''
		}
	}
}