package rt.plugin.service.an

import com.google.common.collect.ImmutableList
import java.lang.annotation.Target
import java.util.LinkedList
import java.util.List
import org.eclipse.xtend.lib.macro.AbstractClassProcessor
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.CodeGenerationContext
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.ValidationContext
import org.eclipse.xtend.lib.macro.declaration.AnnotationReference
import org.eclipse.xtend.lib.macro.declaration.ClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.MethodDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableClassDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableMethodDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableParameterDeclaration
import org.eclipse.xtend.lib.macro.declaration.TypeReference
import org.eclipse.xtend.lib.macro.declaration.Visibility
import rt.data.schema.SProperty
import rt.data.schema.SType
import rt.pipeline.IComponent
import rt.pipeline.IMessageBus.Message
import rt.pipeline.pipe.PipeContext
import rt.pipeline.promise.AsyncUtils
import rt.plugin.config.PluginConfig
import rt.plugin.config.PluginConfigFactory
import rt.plugin.config.PluginEntry
import rt.plugin.service.IServiceClientFactory
import rt.plugin.service.ServiceClient
import rt.plugin.service.descriptor.DMethod
import rt.plugin.service.descriptor.IDescriptor

@Target(TYPE)
@Active(ServiceProcessor)
annotation Service {
	Class<?> value = Void
	boolean metadata = true
}

class ServiceProcessor extends AbstractClassProcessor {
	override doValidate(ClassDeclaration clazz, extension ValidationContext ctx) {
		//TODO: verify if methods have return types, inferred not working!
	}
	
	def methSignature(MethodDeclaration meth) {
		'''«meth.returnType» «meth.simpleName»(«FOR param: meth.parameters SEPARATOR ','»«param.type»«ENDFOR»)'''.toString
	}
	
	override doTransform(MutableClassDeclaration clazz, extension TransformationContext ctx) {
		val publicMethods = clazz.declaredMethods.filter[ findAnnotation(Public.findTypeGlobally) != null ].toList
		
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
		for (MutableMethodDeclaration meth: publicMethods) {
			val annoPublicRef = meth.findAnnotation(Public.findTypeGlobally)
			val isNotification = annoPublicRef.getBooleanValue('notif')
			val isAsync = annoPublicRef.getBooleanValue('async')
			
			//make a copy because the parameters will be changed
			val methParameters = meth.parameters.map[it as MutableParameterDeclaration].toList
			
			val ctxArgs = meth.getContextArgs(ctx)
			ctxArgs.forEach[
				meth.addParameter(getStringValue('name'), getClassValue('type'))
			]
			
			val retType = meth.returnType.simpleName
			val hasIntervalSimbol = methParameters.size != 0 && ctxArgs.size != 0
			switchCases.add('''
				case "«meth.simpleName»":
					«IF methParameters.size != 0»
						final «List.canonicalName»<Object> «meth.simpleName»Args = msg.args(«FOR param: methParameters SEPARATOR ','» «param.type.simpleName.replaceFirst('<.*>', '')».class«ENDFOR» );
					«ENDIF»
					
					«IF isAsync»
						«AsyncUtils.canonicalName».task(() -> {
							«IF retType != 'void'»final Object «meth.simpleName»Ret = «ENDIF»«meth.simpleName»(«addMessageArgs(meth.simpleName + 'Args', methParameters)»«IF hasIntervalSimbol»,«ENDIF»«meth.addContextArgs(ctx, ctxArgs)»);
							«IF retType != 'void'»
								return «meth.simpleName»Ret;
							«ELSE»
								return null;
							«ENDIF»
						}).then(res -> {
							«IF !isNotification»
								«IF retType != 'void'»
									ctx.replyOK(res);
								«ELSE»
									ctx.replyOK();
								«ENDIF»
							«ENDIF»
						}, err -> {
							ctx.replyError(err);
						});
					«ELSE»
						«IF retType != 'void'»final Object «meth.simpleName»Ret = «ENDIF»«meth.simpleName»(«addMessageArgs(meth.simpleName + 'Args', methParameters)»«IF hasIntervalSimbol»,«ENDIF»«meth.addContextArgs(ctx, ctxArgs)»);
						«IF !isNotification»
							«IF retType != 'void'»
								ctx.replyOK(«meth.simpleName»Ret);
							«ELSE»
								ctx.replyOK();
							«ENDIF»
						«ENDIF»
					«ENDIF»
					break;
			''')
		}
		
		clazz.addMethod('apply')[
			addParameter('ctx', PipeContext.newTypeReference)
			
			body = '''
				final «Message» msg = ctx.getMessage();
				
				final «IServiceClientFactory» clientFactory = ctx.object(«IServiceClientFactory».class);
				final «ServiceClient» client = clientFactory != null ? clientFactory.getServiceClient() : null;
				
				try {
					switch(msg.cmd) {
						«FOR cas: switchCases»
							«cas»
						«ENDFOR»
						default:
							ctx.replyError(new RuntimeException("No public method: " + msg.cmd));
							break;
					}
				} catch(«Exception.name» ex) {
					ex.printStackTrace();
					ctx.replyError(ex);
				}
			'''
		]
		
		val anno = clazz.findAnnotation(Service.findTypeGlobally)
		if (anno.getBooleanValue('metadata'))
			clazz.generateMetadata(publicMethods, ctx)
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

		meth.annotations.forEach[
			if (annotationTypeDeclaration ==  Proxy.findTypeGlobally || annotationTypeDeclaration ==  Context.findTypeGlobally) {
				ctxArgs.add(it)
			} else if (annotationTypeDeclaration == Proxies.findTypeGlobally || annotationTypeDeclaration == Contexts.findTypeGlobally) {
				val annoArray = getAnnotationArrayValue('value')
				ctxArgs.addAll(annoArray)
			}
		]
		
		return ctxArgs
	}
	
	def addContextArgs(MutableMethodDeclaration meth, extension TransformationContext ctx, List<AnnotationReference> ctxArgs) '''
		«FOR annoRef: ctxArgs SEPARATOR ','»
			«IF annoRef.annotationTypeDeclaration == Proxy.findTypeGlobally»
				client.create("«annoRef.getSrvPath»", «annoRef.getClassValue('type')».class)
			«ELSE»
				ctx.object(«annoRef.getClassValue('type')».class)
			«ENDIF»
		«ENDFOR»
	'''
	
	def addMessageArgs(String varName, List<MutableParameterDeclaration> parameters) {
		var index = 0
		'''«FOR param: parameters SEPARATOR ','» («param.type»)«varName».get(«index++»)«ENDFOR» '''
	}
	
	def getSrvPath(AnnotationReference annoRef) {
		val srvName = annoRef.getStringValue('name')
		return 'srv:' + srvName
	}
	
	def void generateMetadata(MutableClassDeclaration clazz, List<? extends MutableMethodDeclaration> methods, extension TransformationContext ctx) {
		clazz.extendedClass = IDescriptor.newTypeReference
		
		clazz.addField('methods')[
			visibility = Visibility.PUBLIC
			transient = true
			static = true
			final = true
			type = List.newTypeReference(DMethod.newTypeReference)
			initializer = '''«ImmutableList».copyOf(new DMethod[] {
				«FOR meth: methods SEPARATOR ','»
					«ctx.methodInitializer(meth)»
				«ENDFOR»
			})'''
		]
		
		clazz.addMethod('getMethods')[
			returnType = List.newTypeReference(DMethod.newTypeReference)
			body = '''
				return methods;
			'''
		]
	}
	
	def methodInitializer(extension TransformationContext ctx, MutableMethodDeclaration meth) {
		//remove context parameters
		val originalParams = meth.parameters.filter[ primarySourceElement != null ]
		return '''
			new DMethod("«meth.simpleName»", «meth.returnType.typeInitializer», «ImmutableList.simpleName».copyOf(new «SProperty.canonicalName»[] {
				«FOR param: originalParams SEPARATOR ','»
					«ctx.parameterInitializer(param)»
				«ENDFOR»
			}))
		'''
	}
	
	def parameterInitializer(extension TransformationContext ctx, MutableParameterDeclaration param)
		'''new «SProperty.canonicalName»("«param.simpleName»", «param.type.typeInitializer»)'''
	
	def typeInitializer(TypeReference rType) {
		val type = rType.wrapperIfPrimitive.name.split('<').get(0)
		val argTypes = rType.actualTypeArguments.map[ name.split('<').get(0) ]
		
		'''«SType.canonicalName».from(«type».class«IF argTypes.length != 0», «ENDIF»«FOR arg: argTypes SEPARATOR ', '»«arg».class«ENDFOR»)'''
	}
}