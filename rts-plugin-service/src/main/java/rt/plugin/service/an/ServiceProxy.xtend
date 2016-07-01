package rt.plugin.service.an

import java.lang.annotation.Target
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.AbstractInterfaceProcessor
import org.eclipse.xtend.lib.macro.declaration.MutableInterfaceDeclaration
import org.eclipse.xtend.lib.macro.TransformationContext
import rt.plugin.service.Promise

@Target(TYPE)
@Active(ServiceProxyProcessor)
annotation ServiceProxy {
	Class<?> value
}

class ServiceProxyProcessor extends AbstractInterfaceProcessor {
	
	override doTransform(MutableInterfaceDeclaration inter, extension TransformationContext ctx) {
		val anno = inter.findAnnotation(ServiceProxy.findTypeGlobally)
		val client = anno.getClassValue('value')
		
		client.declaredResolvedMethods.forEach[ meth |
			val interMeth = meth.declaration
			inter.addMethod(interMeth.simpleName)[ proxyMeth |
				interMeth.parameters.forEach[ proxyMeth.addParameter(simpleName, type) ]
				proxyMeth.returnType = Promise.newTypeReference(interMeth.returnType)
				
				val anRef = Public.newAnnotationReference[ ref |
					ref.setClassValue('retType', interMeth.returnType)
				]
				
				proxyMeth.addAnnotation(anRef)
			]
		]
	}
}