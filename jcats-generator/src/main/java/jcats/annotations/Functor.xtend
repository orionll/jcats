package jcats.annotations;

import java.lang.annotation.ElementType
import java.lang.annotation.Target
import java.util.List
import org.eclipse.xtend.lib.macro.Active
import org.eclipse.xtend.lib.macro.TransformationContext
import org.eclipse.xtend.lib.macro.TransformationParticipant
import org.eclipse.xtend.lib.macro.declaration.MutableTypeDeclaration
import org.eclipse.xtend.lib.macro.declaration.Type
import org.eclipse.xtend.lib.macro.declaration.TypeDeclaration
import org.eclipse.xtend.lib.macro.declaration.TypeParameterDeclaration
import org.eclipse.xtend.lib.macro.declaration.TypeParameterDeclarator

import static extension jcats.annotations.TransformationHelper.*

@Target(ElementType::TYPE)
@Active(typeof(FunctorProcessor))
annotation Functor {}

class FunctorProcessor implements TransformationParticipant<MutableTypeDeclaration> {

	override doTransform(List<? extends MutableTypeDeclaration> annotatedClasses, @Extension TransformationContext context) {
		for (MutableTypeDeclaration annotatedClass : annotatedClasses) {
			doTransform(annotatedClass, context);
		}
	}

	def doTransform(MutableTypeDeclaration type, extension TransformationContext context) {
		val typeParams = (type as TypeParameterDeclarator).typeParameters
		val f = Constants.F.findTypeGlobally

		if (type.qualifiedName == Constants.F) {
			addFMap(type, typeParams, f, context)
			addFContramap(type, typeParams, f, context)
		}

		if (typeParams.size == 0) {
			type.addError('''@«typeof(Functor).simpleName» can only be applied to generic types''')
		} else if (typeParams.size == 1) {
			addMethodsForSingleParamFunctor(type, f, context)
		} else {
			addMethodsForMultiParamFunctor(type, typeParams, f, context)
		}
	}

	def addFMap(MutableTypeDeclaration type, Iterable<? extends TypeParameterDeclaration> typeParams, Type f, extension TransformationContext context) {
		type.addMethod("map") [
			static = false
			abstract = false
			val a = typeParams.head.newTypeReference
			val b = typeParams.tail.head.newTypeReference
			val c = addTypeParameter("C").newTypeReference
			addParameter("f", f.newTypeReference(b, c))
			returnType = f.newTypeReference(a, c)
			body = ['''
				java.util.Objects.requireNonNull(f);
				return (A a) -> f.apply(apply(a));
			''']
		]
	}

	def addFContramap(MutableTypeDeclaration type, Iterable<? extends TypeParameterDeclaration> typeParams, Type f, extension TransformationContext context) {
		type.addMethod("contraMap") [
			static = false
			abstract = false
			val a = typeParams.head.newTypeReference
			val b = typeParams.tail.head.newTypeReference
			val c = addTypeParameter("C").newTypeReference
			addParameter("f", f.newTypeReference(c, a))
			returnType = f.newTypeReference(c, b)
			body = ['''
				java.util.Objects.requireNonNull(f);
				return (C c) -> apply(f.apply(c));
			''']
		]
	}

	def addF0Map(MutableTypeDeclaration type, Iterable<? extends TypeParameterDeclaration> typeParams, Type f, extension TransformationContext context) {
		type.addMethod("map") [
			static = false
			abstract = false
			val a = typeParams.head.newTypeReference
			val b = addTypeParameter("B").newTypeReference
			addParameter("f", f.newTypeReference(a, b))
			returnType = type.newTypeReference(b)
			body = ['''
				java.util.Objects.requireNonNull(f);
				return () -> f.apply(apply());
			''']
		]
	}

	private val static liftBody = '''
		java.util.Objects.requireNonNull(f);
		return fa -> fa.map(f);
	'''

	private def static widenBody(TypeDeclaration type) { '''return («type.simpleName»)fa;''' }

	package def static addMethodsForSingleParamFunctor(MutableTypeDeclaration type, Type f, extension TransformationContext context) {
		type.addMethod("lift") [
			static = true
			abstract = false
			val a = addTypeParameter("A").newTypeReference
			val b = addTypeParameter("B").newTypeReference
			addParameter("f", f.newTypeReference(a, b))
			returnType = f.newTypeReference(type.newTypeReference(a), type.newTypeReference(b))
			body = [liftBody]
		]

		type.addMethod("widen") [
			static = true
			abstract = false
			val to = addTypeParameter("B").newTypeReference
			val from = addTypeParameter("A", to).newTypeReference
			returnType = type.newTypeReference(to)
			addParameter("fa", type.newTypeReference(from))
			body = [widenBody(type)]
		]
	}

	package def static addMethodsForMultiParamFunctor(MutableTypeDeclaration type, Iterable<? extends TypeParameterDeclaration> typeParams,
		Type f, extension TransformationContext context) {
		type.addMethod("lift") [
			static = true
			abstract = false
			val method = it
			val ab = typeParams.map[method.addTypeParameter(it.simpleName).newTypeReference].toList
			val a = ab.take(ab.size - 1).toList
			val b = ab.last
			val c = addTypeParameter("C").newTypeReference
			addParameter("f", f.newTypeReference(b, c))
			returnType = f.newTypeReference(type.typeReference(ab, context), type.typeReference(a, c, context))
			body = [liftBody]
		]

		type.addMethod("widen") [
			static = true
			abstract = false
			val method = it
			val aDecl = typeParams.take(typeParams.size - 1)
			val bDecl = typeParams.last
			val a = aDecl.map[method.addTypeParameter(it.simpleName).newTypeReference].toList
			val c = addTypeParameter("C").newTypeReference
			val b = addTypeParameter(bDecl.simpleName, c).newTypeReference
			returnType = type.typeReference(a, c, context)
			addParameter("fa", type.typeReference(a, b, context))
			body = [widenBody(type)]
		]
	}
}
