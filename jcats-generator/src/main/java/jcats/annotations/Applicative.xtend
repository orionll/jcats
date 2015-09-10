package jcats.annotations;

import java.lang.annotation.ElementType
import java.lang.annotation.Target
import java.util.List
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.TransformationParticipant
import org.eclipse.xtend.lib.macro.declaration.MutableTypeDeclaration
import org.eclipse.xtend.lib.macro.declaration.Type
import org.eclipse.xtend.lib.macro.declaration.TypeParameterDeclaration
import org.eclipse.xtend.lib.macro.declaration.TypeParameterDeclarator

import static extension jcats.annotations.TransformationHelper.*

@Target(ElementType::TYPE)
@Active(typeof(ApplicativeProcessor))
annotation Applicative {}

class ApplicativeProcessor implements TransformationParticipant<MutableTypeDeclaration> {

	override doTransform(List<? extends MutableTypeDeclaration> annotatedClasses, @Extension TransformationContext context) {
		for (MutableTypeDeclaration annotatedClass : annotatedClasses) {
			doTransform(annotatedClass, context);
		}
	}

	def doTransform(MutableTypeDeclaration type, extension TransformationContext context) {
		val typeParams = (type as TypeParameterDeclarator).typeParameters
		val f = Constants.F.findTypeGlobally

		if (typeParams.size == 0) {
			type.addError('''@«typeof(Applicative).simpleName» can only be applied to generic types''')
		} else if (typeParams.size == 1) {
			addMethodsForSingleParamApplicative(type, f, context)
		} else {
			addMethodsForMultiParamApplicative(type, typeParams, f, context)
		}
	}
	
	private def static String applyBody(int arity) {
		'''return «(arity + 1 >.. 2).map['''ap(fa«it», '''].join»fa1.map(f.curry«if (arity == 2) "" else arity - 1»())«(1 ..< arity).map[")"].join»;'''
	}
	
	private def static String tupleBody(int arity) {
		'''return apply«arity»(«(1 .. arity).map["fa" + it].join(", ")», P«arity»::p«arity»);'''
	}

	package def static addMethodsForSingleParamApplicative(MutableTypeDeclaration type, Type f, extension TransformationContext context) {
		for (arity : 2 .. Constants.MAX_ARITY) {
			val fn = (Constants.F + arity).findTypeGlobally
			
			type.addMethod('''apply«arity»''') [
				static = true
				abstract = false
				val method = it
				val a = (1 .. arity).map[method.addTypeParameter("A" + it).newTypeReference].toList
				val b = addTypeParameter("B").newTypeReference
				a.forEach[param, index |
					method.addParameter('''fa«index + 1»''', type.newTypeReference(param))
				]
				addParameter("f", fn.typeReference(a, b, context))
				returnType = type.newTypeReference(b)
				body = [applyBody(arity)]
			]
		}
		
		for (arity : 2 .. Constants.MAX_ARITY) {
			val pn = (Constants.P + arity).findTypeGlobally
			
			type.addMethod('''tuple«arity»''') [
				static = true
				abstract = false
				val method = it
				val a = (1 .. arity).map[method.addTypeParameter("A" + it).newTypeReference].toList
				a.forEach[param, index |
					method.addParameter('''fa«index + 1»''', type.newTypeReference(param))
				]
				returnType = type.newTypeReference(pn.typeReference(a, context))
				body = [tupleBody(arity)]
			]
		}
	}
	
	package def static addMethodsForMultiParamApplicative(MutableTypeDeclaration type, Iterable<? extends TypeParameterDeclaration> typeParams,
		Type f, extension TransformationContext context) {
		for (arity : 2 .. Constants.MAX_ARITY) {
			val fn = (Constants.F + arity).findTypeGlobally
			
			type.addMethod('''apply«arity»''') [
				static = true
				abstract = false
				val method = it
				val a = typeParams.take(typeParams.size - 1).map[method.addTypeParameter(it.simpleName).newTypeReference].toList
				val b = (1 .. arity).map[method.addTypeParameter("B" + it).newTypeReference].toList
				val c = addTypeParameter("C").newTypeReference
				b.forEach[param, index |
					method.addParameter('''fa«index + 1»''', type.typeReference(a, param, context))
				]
				addParameter("f", fn.typeReference(b, c, context))
				returnType = type.typeReference(a, c, context)
				body = [applyBody(arity)]
			]
		}
		
		for (arity : 2 .. Constants.MAX_ARITY) {
			val pn = (Constants.P + arity).findTypeGlobally
			
			type.addMethod('''tuple«arity»''') [
				static = true
				abstract = false
				val method = it
				val a = typeParams.take(typeParams.size - 1).map[method.addTypeParameter(it.simpleName).newTypeReference].toList
				val b = (1 .. arity).map[method.addTypeParameter("B" + it).newTypeReference].toList
				b.forEach[param, index |
					method.addParameter('''fa«index + 1»''', type.typeReference(a, param, context))
				]
				returnType = type.typeReference(a, pn.typeReference(b, context), context)
				body = [tupleBody(arity)]
			]
		}
	}
}
