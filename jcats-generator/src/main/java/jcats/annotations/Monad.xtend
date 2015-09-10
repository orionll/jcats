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
@Active(typeof(MonadProcessor))
annotation Monad {}

class MonadProcessor implements TransformationParticipant<MutableTypeDeclaration> {

	override doTransform(List<? extends MutableTypeDeclaration> annotatedClasses, @Extension TransformationContext context) {
		for (MutableTypeDeclaration annotatedClass : annotatedClasses) {
			doTransform(annotatedClass, context);
		}
	}

	def doTransform(MutableTypeDeclaration type, extension TransformationContext context) {
		val typeParams = (type as TypeParameterDeclarator).typeParameters
		val f = Constants.F.findTypeGlobally
		
		if (type.qualifiedName == Constants.F) {
			addFFlatMap(type, typeParams, f, context)
		}

		if (typeParams.size == 0) {
			type.addError('''@«typeof(Monad).simpleName» can only be applied to generic types''')
		} else if (typeParams.size == 1) {
			addMethodsForSingleParamMonad(type, f, context)
		} else {
			addMethodsForMultiParamMonad(type, typeParams, f, context)
		}
	}
	
	private def addFFlatMap(MutableTypeDeclaration type, Iterable<? extends TypeParameterDeclaration> typeParams, Type f, extension TransformationContext context) {
		type.addMethod("flatMap") [
			static = false
			abstract = false
			val a = typeParams.head.newTypeReference
			val b = typeParams.tail.head.newTypeReference
			val c = addTypeParameter("C").newTypeReference
			addParameter("f", f.newTypeReference(b, f.newTypeReference(a, c)))
			returnType = f.newTypeReference(a, c)
			body = ['''
				java.util.Objects.requireNonNull(f);
				return (A a) -> f.apply(apply(a)).apply(a);
			''']
		]
	}
	
	val static joinBody = "return ffa.flatMap(F.id());"
	
	val static apBody = "return f.flatMap(g -> fa.map(a -> g.apply(a)));"

	package def static addMethodsForSingleParamMonad(MutableTypeDeclaration type, Type f, extension TransformationContext context) {
		if (!type.methodExists("join", 1, 1, context)) {
			type.addMethod("join") [
				static = true
				abstract = false
				val a = addTypeParameter("A").newTypeReference
				addParameter("ffa", type.newTypeReference(type.newTypeReference(a)))
				returnType = type.newTypeReference(a)
				body = [joinBody]
			]
		}
		
		if (!type.methodExists("ap", 2, 2, context)) {
			type.addMethod("ap") [
				static = true
				abstract = false
				val a = addTypeParameter("A").newTypeReference
				val b = addTypeParameter("B").newTypeReference
				addParameter("fa", type.newTypeReference(a))
				addParameter("f", type.newTypeReference(f.newTypeReference(a, b)))
				returnType = type.newTypeReference(b)
				body = [apBody]
			]
		}
	}
	
	package def static addMethodsForMultiParamMonad(MutableTypeDeclaration type, Iterable<? extends TypeParameterDeclaration> typeParams,
		Type f, extension TransformationContext context) {
		if (!type.methodExists("join", 1, 1, context)) {
			type.addMethod("join") [
				static = true
				abstract = false
				val method = it
				val ab = typeParams.map[method.addTypeParameter(it.simpleName).newTypeReference].toList
				val a = ab.take(ab.size - 1).toList
				val b = ab.last
				addParameter("ffa", type.typeReference(a, type.typeReference(a, b, context), context))
				returnType = type.typeReference(a, b, context)
				body = [joinBody]
			]
		}

		if (!type.methodExists("ap", 1, 1, context)) {
			type.addMethod("ap") [
				static = true
				abstract = false
				val method = it
				val ab = typeParams.map[method.addTypeParameter(it.simpleName).newTypeReference].toList
				val a = ab.take(ab.size - 1).toList
				val b = ab.last
				val c = addTypeParameter("C").newTypeReference
				addParameter("fa", type.typeReference(a, b, context))
				addParameter("f", type.typeReference(a, f.newTypeReference(b, c), context))
				returnType = type.typeReference(a, c, context)
				body = [apBody]
			]
		}
	}
}
