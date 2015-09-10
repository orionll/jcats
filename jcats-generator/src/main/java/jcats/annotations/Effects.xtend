package jcats.annotations

import com.google.common.collect.Lists
import java.lang.annotation.ElementType
import java.lang.annotation.Target
import org.eclipse.xtend.lib.macro.AbstractInterfaceProcessor
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.RegisterGlobalsContext
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.declaration.InterfaceDeclaration
import org.eclipse.xtend.lib.macro.declaration.MutableInterfaceDeclaration

import static extension jcats.annotations.TransformationHelper.*

@Target(ElementType::TYPE)
@Active(typeof(EffectsProcessor))
annotation Effects {}

class EffectsProcessor extends AbstractInterfaceProcessor {
	
	override doRegisterGlobals(InterfaceDeclaration __, extension RegisterGlobalsContext context) {
		for (arity : 2 .. Constants.MAX_ARITY) {
			(Constants.EFFECT + arity).registerInterface
		}
	}

	override doTransform(MutableInterfaceDeclaration annotatedInterface, extension TransformationContext context) {
		if (annotatedInterface.qualifiedName == Constants.EFFECT) {
			for (arity : 2 .. Constants.MAX_ARITY) {
				val name = Constants.EFFECT + arity
				val type = findInterface(name)
				type.addAnnotation(findTypeGlobally(typeof(FunctionalInterface)).newAnnotationReference)
				transformEffect(arity, type, context)
			}
		} else {
			annotatedInterface.addError('''@«typeof(Effects).simpleName» can only be applied to «Constants.EFFECT»''')
		}
	}
	
	private def static transformEffect(int arity, MutableInterfaceDeclaration type, extension TransformationContext context) {
		val a = (1 .. arity).map[type.addTypeParameter("A" + it).newTypeReference].toList
		val f = Constants.F.findTypeGlobally

		type.addMethod("apply") [
			a.forEach[input, index | addParameter("a" + (index + 1), input)]
			returnType = typeof(void).newTypeReference
		]
		
		a.forEach[param, index |
			type.addMethod('''contraMap«index + 1»''') [
				abstract = false
				val b = addTypeParameter("B").newTypeReference
				val aCopy = Lists.newArrayList(a)
				addParameter("f", f.newTypeReference(b, aCopy.get(index)))
				aCopy.set(index, b)
				returnType = type.typeReference(aCopy, context)
				body = ['''
					java.util.Objects.requireNonNull(f);
					return («(1 .. arity).map[if (it == index + 1) "b" else '''a«it»'''].join(", ")») -> apply(«(1 .. arity).map[if (it == index + 1) "f.apply(b)" else '''a«it»'''].join(", ")»);
				''']
			]
		]
	}
	
}
