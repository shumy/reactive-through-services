package rt.plugin.service.an

import java.lang.annotation.Target
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.AbstractClassProcessor
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.MutableMethodDeclaration
import org.eclipse.xtend.lib.macro.declaration.ClassDeclaration
import org.eclipse.xtend.lib.macro.CodeGenerationContext
import rt.plugin.config.PluginConfig
import rt.plugin.config.PluginConfigFactory
import rt.plugin.config.PluginEntry
import java.util.List
import rt.pipeline.IComponent
import rt.pipeline.pipe.PipeContext
import rt.pipeline.IMessageBus.Message
import org.eclipse.xtend.lib.macro.ValidationContext
import rt.plugin.service.IServiceClientFactory
import rt.plugin.service.ServiceClient
import java.util.LinkedList
import org.eclipse.xtend.lib.macro.declaration.AnnotationReference
import org.eclipse.xtend.lib.macro.declaration.MutableParameterDeclaration
import org.eclipse.xtend.lib.macro.declaration.MethodDeclaration

@Target(TYPE)
@Active(ServiceProcessor)
annotation Service {
	Class<?> value = Void
}

class ServiceProcessor extends AbstractClassProcessor {
	
	override doValidate(ClassDeclaration clazz, extension ValidationContext ctx) {
		val reserved = #[Message.OK, Message.ERROR]
		
		val srvPublicMethods = clazz.declaredMethods.filter[ findAnnotation(Public.findTypeGlobally) != null ]
		srvPublicMethods.forEach[
			if (reserved.contains(simpleName))
				addError('Reserved public method name!')
		]
		
		//TODO: verify if methods have return types, inferred not working!
	}
	
	def methSignature(MethodDeclaration meth) {
		'''«meth.returnType» «meth.simpleName»(«FOR param: meth.parameters SEPARATOR ','»«param.type»«ENDFOR»)'''.toString
	}
	
	override doTransform(MutableClassDeclaration clazz, extension TransformationContext ctx) {
		clazz.extendedClass = IComponent.newTypeReference
		
		//validate interface implementation before changes...
		val annoRef = clazz.findAnnotation(Service.findTypeGlobally)
		val srvInterface = annoRef.getClassValue('value')
		if (srvInterface != Void.newTypeReference) {
			val srvInterfaceMethods = srvInterface.declaredResolvedMethods.map[ declaration ]
			srvInterfaceMethods.forEach[ interMeth |
				if (!clazz.declaredMethods.exists[ methSignature == interMeth.methSignature ]) {
					clazz.addError('No implementation for method: ' + interMeth.methSignature)
				}
			]
		}
		
		
		val switchCases = new LinkedList<String>
		for (MutableMethodDeclaration meth: clazz.declaredMethods) {
			val annoPublicRef = meth.findAnnotation(Public.findTypeGlobally)
			if (annoPublicRef != null) {
				val isNotification = annoPublicRef.getBooleanValue('notif')
				
				//make a copy because the parameters will be changed
				val methParameters = meth.parameters.map[it as MutableParameterDeclaration].toList
				
				val ctxArgs = meth.getContextArgs(ctx)
				ctxArgs.forEach[
					meth.addParameter(getStringValue('name'), getClassValue('proxy'))
				]
				
				val retType = meth.returnType.simpleName
				val hasIntervalSimbol = methParameters.size != 0 && ctxArgs.size != 0
				switchCases.add('''
					case "«meth.simpleName»":
						«IF methParameters.size != 0»
						args = msg.args(«FOR param: methParameters SEPARATOR ','» «param.type.simpleName.replaceFirst('<.*>', '')».class«ENDFOR» );
						«ENDIF»
						«IF retType != 'void'»ret = «ENDIF»«meth.simpleName»(«methParameters.addMessageArgs»«IF hasIntervalSimbol»,«ENDIF»«meth.addContextArgs(ctx, ctxArgs)»);
						«IF !isNotification»
							«IF retType != 'void'»
								ctx.replyOK(ret);
							«ELSE»
								ctx.replyOK();
							«ENDIF»
						«ENDIF»
						break;
				''')
			}
		}
		
		clazz.addMethod('apply')[
			addParameter('ctx', PipeContext.newTypeReference)
			
			body = '''
				«ServiceClient» client = null;
				
				final IServiceClientFactory clientFactory = ctx.object(«IServiceClientFactory».class);
				if (clientFactory != null)
					client = clientFactory.getServiceClient();
				
				final «Message» msg = ctx.getMessage();
				«List»<Object> args = null;
				Object ret = null;
				
				switch(msg.cmd) {
					«FOR cas: switchCases»
						«cas»
					«ENDFOR»
					default:
						ctx.replyError("No public method: " + msg.cmd);
						break;
				}
			'''
		]
	}
	
	override doGenerateCode(ClassDeclaration clazz, extension CodeGenerationContext context) {
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
		])
		
		// write plugin-config.xml
		file.contents = factory.transform(config)
	}
	
	def getContextArgs(MutableMethodDeclaration meth, extension TransformationContext ctx) {
		val ctxArgs = new LinkedList<AnnotationReference>
		
		val annoProxyRef = meth.findAnnotation(Proxy.findTypeGlobally)
		if (annoProxyRef != null)
			ctxArgs.add(annoProxyRef)
		
		val annoProxysRef = meth.findAnnotation(Proxies.findTypeGlobally)
		if (annoProxysRef != null) {
			val proxies = annoProxysRef.getAnnotationArrayValue('value')
			ctxArgs.addAll(proxies)
		}
		
		return ctxArgs
	}
	
	def addContextArgs(MutableMethodDeclaration meth, extension TransformationContext ctx, List<AnnotationReference> ctxArgs)
		'''«FOR annoRef: ctxArgs SEPARATOR ','» client.create("«annoRef.getStringValue('name')»", «annoRef.getClassValue('proxy')».class)«ENDFOR» '''
	
	def addMessageArgs(List<MutableParameterDeclaration> parameters) {
		var index = 0
		'''«FOR param: parameters SEPARATOR ','» («param.type»)args.get(«index++»)«ENDFOR» '''
	}
}