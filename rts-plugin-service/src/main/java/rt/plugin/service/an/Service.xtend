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
import rt.async.AsyncUtils
import rt.async.observable.Observable
import rt.async.promise.Promise
import rt.async.pubsub.Message
import rt.data.schema.SProperty
import rt.data.schema.SType
import rt.pipeline.IComponent
import rt.pipeline.pipe.PipeContext
import rt.plugin.config.PluginConfig
import rt.plugin.config.PluginConfigFactory
import rt.plugin.config.PluginEntry
import rt.plugin.service.CtxHeaders
import rt.plugin.service.IServiceClientFactory
import rt.plugin.service.ServiceClient
import rt.plugin.service.ServiceUtils
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
			val isWorker = annoPublicRef.getBooleanValue('worker')
			
			//make a copy because the parameters will be changed
			val methParameters = meth.parameters.map[it as MutableParameterDeclaration].toList
			
			val ctxArgs = meth.getContextArgs(ctx)
			ctxArgs.forEach[
				meth.addParameter(getStringValue('name'), getClassValue('type'))
			]
			
			val hasIntervalSimbol = methParameters.size != 0 && ctxArgs.size != 0
			switchCases.add('''
				case "«meth.simpleName»":
					«IF methParameters.size != 0»
						final «List.canonicalName»<Object> «meth.simpleName»Args = msg.args(«FOR param: methParameters SEPARATOR ','» «param.type.simpleName.replaceFirst('<.*>', '')».class«ENDFOR» );
					«ENDIF»
					
					«IF isWorker»
						«AsyncUtils.canonicalName».task(() -> {
							«meth.addReturnType(ctx)»
								«meth.addMethodCall(methParameters, hasIntervalSimbol, ctxArgs, ctx)»
							«IF meth.returnType.wrapperIfPrimitive != Void.newTypeReference»
								return «meth.simpleName»Ret;
							«ELSE»
								return null;
							«ENDIF»
						}).then(
							res -> {
								«meth.addReturnProcess(isNotification, 'res', ctx)»
							},
							err -> ctx.replyError(err)
						);
					«ELSE»
						«meth.addReturnType(ctx)»
							«meth.addMethodCall(methParameters, hasIntervalSimbol, ctxArgs, ctx)»
						«meth.addReturnProcess(isNotification, meth.simpleName + 'Ret', ctx)»
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
				
				final «CtxHeaders» ctxHeaders = ctx.object(CtxHeaders.class);
				if (ctxHeaders != null && ctxHeaders.get("auth") != null) {
					«ServiceUtils».setTokenType(ctxHeaders.get("auth"));
					«ServiceUtils».setAuthToken(ctxHeaders.get("token"));
				}
				
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
		
		if (annoRef.getBooleanValue('metadata'))
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
	
	def addReturnType(MethodDeclaration meth, extension TransformationContext ctx) '''
		«IF meth.returnType.wrapperIfPrimitive != Void.newTypeReference»
			«IF Promise.newTypeReference.isAssignableFrom(meth.returnType)»
				final Promise<«meth.returnType.actualTypeArguments.get(0)»> «meth.simpleName»Ret =
			«ELSEIF Observable.newTypeReference.isAssignableFrom(meth.returnType)»
				final Observable<«meth.returnType.actualTypeArguments.get(0)»> «meth.simpleName»Ret =
			«ELSE»
				final Object «meth.simpleName»Ret =
			«ENDIF»
		«ENDIF»
	'''
	
	def addMethodCall(MethodDeclaration meth, List<MutableParameterDeclaration> methParameters, boolean hasIntervalSimbol, List<AnnotationReference> ctxArgs, extension TransformationContext ctx) '''
		«meth.simpleName»(«addMessageArgs(meth.simpleName + 'Args', methParameters)»«IF hasIntervalSimbol»,«ENDIF»«meth.addContextArgs(ctx, ctxArgs)»);
	'''
	
	def addReturnProcess(MethodDeclaration meth, boolean isNotification, String varName, extension TransformationContext ctx) '''
		«IF !isNotification»
			«IF meth.returnType.wrapperIfPrimitive != Void.newTypeReference»
				«IF Promise.newTypeReference.isAssignableFrom(meth.returnType)»
					«varName».then(
						pRes -> «IF meth.returnType.actualTypeArguments.get(0) != Void.newTypeReference»ctx.replyOK(pRes)«ELSE»ctx.replyOK()«ENDIF»,
						pError -> ctx.replyError(pError)
					);
				«ELSEIF Observable.newTypeReference.isAssignableFrom(meth.returnType)»
					final String «varName»UUID = UUID.randomUUID().toString();
					ctx.replyObservable(«varName»UUID);
					«varName».subscribe(
						oNext -> ctx.publishNext(«varName»UUID, oNext),
						() -> ctx.publishComplete(«varName»UUID),
						pError -> ctx.publishError(«varName»UUID, pError)
					);
				«ELSE»
					ctx.replyOK(«varName»);
				«ENDIF»
			«ELSE»
				ctx.replyOK();
			«ENDIF»
		«ENDIF»
	'''
	
	def addContextArgs(MethodDeclaration meth, extension TransformationContext ctx, List<AnnotationReference> ctxArgs) '''
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